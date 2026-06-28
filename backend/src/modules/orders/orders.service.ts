import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { EventBusService } from '../../common/events/event-bus.service';
import { AuditService } from '../audit/audit.service';
import { CancelOrderDto, CheckoutPreviewDto, CreateOrderDto, UpdateOrderStatusDto } from './dto/orders.dto';

const TERMINAL_ORDER_STATUSES = ['CANCELLED', 'REFUNDED'];
const CANCELLABLE_BY_CUSTOMER = ['PENDING', 'CONFIRMED'];
const ORDER_STATUS_TRANSITIONS: Record<string, string[]> = {
  PENDING: ['CONFIRMED', 'CANCELLED'],
  CONFIRMED: ['PROCESSING', 'CANCELLED'],
  PROCESSING: ['READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'CANCELLED'],
  READY_FOR_PICKUP: ['DELIVERED', 'CANCELLED'],
  OUT_FOR_DELIVERY: ['DELIVERED', 'CANCELLED'],
  DELIVERED: ['RETURN_REQUESTED'],
  RETURN_REQUESTED: ['REFUNDED'],
};

type MoneyPlan = {
  subtotal: number;
  deliveryFee: number;
  discount: number;
  total: number;
  currency: string;
  coupon?: any | null;
  address?: any | null;
};

@Injectable()
export class OrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly events: EventBusService,
    private readonly audit: AuditService,
  ) {}

  private get db() {
    return this.prisma as any;
  }

  private async assertCustomer(userId: number) {
    const role = await this.prisma.userRole.findFirst({
      where: { userId, role: { is: { code: 'customer' } } },
      select: { id: true },
    });
    if (!role) {
      throw new ForbiddenException({
        message: 'العملاء فقط يمكنهم إنشاء الطلبات',
        error_code: 'CUSTOMER_ONLY',
      });
    }
  }

  private async getActiveCartWithItems(userId: number) {
    const cart = await this.db.cart.findFirst({
      where: { userId, status: 'ACTIVE' },
      include: {
        items: {
          include: {
            listing: {
              include: {
                product: true,
                organization: true,
                branch: true,
                city: true,
              },
            },
          },
          orderBy: { id: 'asc' },
        },
      },
    });

    if (!cart || cart.items.length === 0) {
      throw new BadRequestException({ message: 'السلة فارغة', error_code: 'EMPTY_CART' });
    }
    return cart;
  }

  private validateAndGroup(cart: any) {
    const groups = new Map<number, any[]>();

    for (const item of cart.items) {
      const listing = item.listing;
      if (!listing || listing.status !== 'ACTIVE' || listing.approvalStatus !== 'APPROVED') {
        throw new BadRequestException({ message: 'يوجد منتج غير متاح في السلة', error_code: 'LISTING_NOT_AVAILABLE' });
      }

      if (item.quantity < listing.minOrderQuantity) {
        throw new BadRequestException({
          message: `الحد الأدنى للطلب هو ${listing.minOrderQuantity}: ${listing.title}`,
          error_code: 'MIN_ORDER_QUANTITY',
        });
      }

      const available = Number(listing.availableQuantity) - Number(listing.reservedQuantity);
      if (available < item.quantity) {
        throw new BadRequestException({ message: `الكمية غير متوفرة: ${listing.title}`, error_code: 'INSUFFICIENT_STOCK' });
      }

      if (!groups.has(listing.organizationId)) groups.set(listing.organizationId, []);
      groups.get(listing.organizationId)!.push(item);
    }

    return groups;
  }

  private linePrice(item: any) {
    return Number(item.listing.salePrice ?? item.listing.unitPrice);
  }

  private calculateSubtotal(items: any[]) {
    return items.reduce((sum, item) => sum + this.linePrice(item) * Number(item.quantity), 0);
  }

  private async resolveAddress(userId: number, dto: CheckoutPreviewDto | CreateOrderDto) {
    if (dto.fulfillmentMethod !== 'DELIVERY') return null;

    if (dto.addressId) {
      const address = await this.db.address.findFirst({ where: { id: dto.addressId, userId, isActive: true } });
      if (!address) throw new BadRequestException({ message: 'عنوان التوصيل غير صحيح', error_code: 'ADDRESS_NOT_FOUND' });
      return address;
    }

    const address = await this.db.address.findFirst({ where: { userId, isActive: true, isDefault: true } });
    if (!address) {
      throw new BadRequestException({ message: 'اختر عنوان التوصيل قبل تأكيد الطلب', error_code: 'DELIVERY_ADDRESS_REQUIRED' });
    }
    return address;
  }

  private async calculateDeliveryFee(dto: CheckoutPreviewDto | CreateOrderDto, address: any | null) {
    if (dto.fulfillmentMethod !== 'DELIVERY') return 0;
    if (!address?.cityId) return 0;

    const fee = await this.db.cityDeliveryFee.findUnique({ where: { cityId: address.cityId } });
    if (!fee || !fee.isDeliveryAvailable) {
      throw new BadRequestException({ message: 'التوصيل غير متاح لهذه المدينة حاليًا', error_code: 'DELIVERY_NOT_AVAILABLE' });
    }
    return Number(fee.deliveryFee ?? 0);
  }

  private async resolveCoupon(userId: number, code: string | undefined, subtotal: number) {
    const normalized = (code ?? '').trim().toUpperCase();
    if (!normalized) return { coupon: null, discount: 0 };

    const now = new Date();
    const coupon = await this.db.coupon.findUnique({ where: { code: normalized } });
    if (!coupon || coupon.status !== 'ACTIVE' || !['ALL', 'MARKETPLACE'].includes(coupon.scope)) {
      throw new BadRequestException({ message: 'كود الخصم غير صالح', error_code: 'INVALID_COUPON' });
    }
    if (coupon.startsAt && coupon.startsAt > now) {
      throw new BadRequestException({ message: 'كود الخصم لم يبدأ بعد', error_code: 'COUPON_NOT_STARTED' });
    }
    if (coupon.endsAt && coupon.endsAt < now) {
      throw new BadRequestException({ message: 'كود الخصم منتهي', error_code: 'COUPON_EXPIRED' });
    }
    if (Number(coupon.minOrderAmount ?? 0) > subtotal) {
      throw new BadRequestException({ message: 'المبلغ أقل من الحد الأدنى للكوبون', error_code: 'COUPON_MIN_ORDER' });
    }
    if (coupon.usageLimit && coupon.usedCount >= coupon.usageLimit) {
      throw new BadRequestException({ message: 'تم استهلاك كود الخصم', error_code: 'COUPON_USAGE_LIMIT' });
    }

    const userUses = await this.db.couponRedemption.count({ where: { couponId: coupon.id, userId } });
    if (userUses >= Number(coupon.perUserLimit ?? 1)) {
      throw new BadRequestException({ message: 'استخدمت هذا الكوبون مسبقًا', error_code: 'COUPON_USER_LIMIT' });
    }

    let discount = 0;
    if (coupon.discountType === 'PERCENTAGE') {
      discount = subtotal * (Number(coupon.discountValue) / 100);
      if (coupon.maxDiscountAmount) discount = Math.min(discount, Number(coupon.maxDiscountAmount));
    } else {
      discount = Number(coupon.discountValue);
    }
    discount = Math.min(Math.max(discount, 0), subtotal);
    return { coupon, discount };
  }

  private async buildMoneyPlan(userId: number, dto: CheckoutPreviewDto | CreateOrderDto, allItems: any[]): Promise<MoneyPlan> {
    const subtotal = this.calculateSubtotal(allItems);
    const address = await this.resolveAddress(userId, dto);
    const deliveryFee = await this.calculateDeliveryFee(dto, address);
    const { coupon, discount } = await this.resolveCoupon(userId, dto.couponCode, subtotal);
    return {
      subtotal,
      deliveryFee,
      discount,
      total: subtotal + deliveryFee - discount,
      currency: 'YER',
      coupon,
      address,
    };
  }

  private prorateDiscount(groupSubtotal: number, totalSubtotal: number, discount: number) {
    if (discount <= 0 || totalSubtotal <= 0) return 0;
    return Math.round(((groupSubtotal / totalSubtotal) * discount) * 100) / 100;
  }

  async checkoutPreview(userId: number, dto: CheckoutPreviewDto) {
    await this.assertCustomer(userId);
    const cart = await this.getActiveCartWithItems(userId);
    const groups = this.validateAndGroup(cart);
    const allItems = Array.from(groups.values()).flat();
    const plan = await this.buildMoneyPlan(userId, dto, allItems);

    const merchants = Array.from(groups.entries()).map(([organizationId, items]) => {
      const subtotal = this.calculateSubtotal(items);
      const discount = this.prorateDiscount(subtotal, plan.subtotal, plan.discount);
      const deliveryFee = plan.deliveryFee > 0 ? Math.round((plan.deliveryFee / groups.size) * 100) / 100 : 0;
      return {
        organization_id: organizationId,
        organization_name: items[0].listing.organization.displayName,
        fulfillment_method: dto.fulfillmentMethod ?? 'PICKUP',
        subtotal,
        delivery_fee: deliveryFee,
        discount,
        total: subtotal + deliveryFee - discount,
        items: items.map((item: any) => ({
          cart_item_id: item.id,
          listing_id: item.listingId,
          title: item.listing.title,
          quantity: item.quantity,
          unit_price: this.linePrice(item),
          total: this.linePrice(item) * item.quantity,
        })),
      };
    });

    return {
      success: true,
      data: {
        merchants,
        subtotal: plan.subtotal,
        delivery_fee: plan.deliveryFee,
        discount: plan.discount,
        grand_total: plan.total,
        currency: plan.currency,
        coupon_code: plan.coupon?.code ?? null,
        address_id: plan.address?.id ?? null,
      },
    };
  }

  private makeOrderNumber(prefix = 'GH') {
    const d = new Date();
    const date = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
    return `${prefix}-${date}-${Math.floor(100000 + Math.random() * 900000)}`;
  }

  private async createOrderNumber(tx: any) {
    for (let attempt = 0; attempt < 5; attempt += 1) {
      const orderNumber = this.makeOrderNumber('GH');
      const exists = await tx.order.findUnique({ where: { orderNumber } });
      if (!exists) return orderNumber;
    }
    throw new BadRequestException({ message: 'تعذر توليد رقم طلب فريد', error_code: 'ORDER_NUMBER_GENERATION_FAILED' });
  }

  private async createInvoiceNumber(tx: any, orderNumber: string) {
    const invoiceNumber = `INV-${orderNumber}`;
    const exists = await tx.invoice.findUnique({ where: { invoiceNumber } }).catch(() => null);
    if (!exists) return invoiceNumber;
    return this.makeOrderNumber('INV');
  }

  async createOrder(userId: number, dto: CreateOrderDto) {
    await this.assertCustomer(userId);
    const cart = await this.getActiveCartWithItems(userId);
    const groups = this.validateAndGroup(cart);
    const allItems = Array.from(groups.values()).flat();
    const plan = await this.buildMoneyPlan(userId, dto, allItems);
    const createdOrders: any[] = [];

    await this.db.$transaction(async (tx: any) => {
      let allocatedDelivery = 0;
      let allocatedDiscount = 0;
      let groupIndex = 0;
      const groupEntries = Array.from(groups.entries());

      for (const [organizationId, items] of groupEntries) {
        groupIndex += 1;
        const subtotal = this.calculateSubtotal(items);
        const isLast = groupIndex === groupEntries.length;
        const deliveryFee = plan.deliveryFee > 0
          ? (isLast ? plan.deliveryFee - allocatedDelivery : Math.round((plan.deliveryFee / groupEntries.length) * 100) / 100)
          : 0;
        const discountAmount = isLast
          ? plan.discount - allocatedDiscount
          : this.prorateDiscount(subtotal, plan.subtotal, plan.discount);
        allocatedDelivery += deliveryFee;
        allocatedDiscount += discountAmount;
        const totalAmount = subtotal + deliveryFee - discountAmount;
        const orderNumber = await this.createOrderNumber(tx);

        const order = await tx.order.create({
          data: {
            orderNumber,
            userId,
            organizationId,
            branchId: items[0].listing.branchId,
            cityId: plan.address?.cityId ?? items[0].listing.cityId,
            fulfillmentMethod: dto.fulfillmentMethod ?? 'PICKUP',
            paymentMethod: dto.paymentMethod ?? (dto.fulfillmentMethod === 'DELIVERY' ? 'CASH_ON_DELIVERY' : 'CASH_ON_PICKUP'),
            subtotalAmount: subtotal,
            deliveryFee,
            discountAmount,
            totalAmount,
            customerNote: dto.customerNote,
            items: {
              create: items.map((item: any) => ({
                listingId: item.listingId,
                productName: item.listing.title,
                unitPrice: this.linePrice(item),
                quantity: item.quantity,
                totalAmount: this.linePrice(item) * item.quantity,
              })),
            },
            statusHistory: { create: { status: 'PENDING', changedByUserId: userId, note: 'Order created by customer' } },
          },
          include: { items: true, organization: true, branch: true, statusHistory: true, fees: true, invoices: true },
        });

        if (deliveryFee > 0) {
          await tx.orderFee.create({ data: { orderId: order.id, feeType: 'DELIVERY', label: 'رسوم التوصيل', amount: deliveryFee, currency: 'YER' } });
        }

        await tx.invoice.create({
          data: {
            orderId: order.id,
            invoiceNumber: await this.createInvoiceNumber(tx, orderNumber),
            subtotalAmount: subtotal,
            deliveryFee,
            discountAmount,
            totalAmount,
            currency: 'YER',
          },
        });

        if (plan.coupon) {
          await tx.couponRedemption.create({
            data: {
              couponId: plan.coupon.id,
              userId,
              orderId: order.id,
              discountAmount,
              currency: 'YER',
              metadata: { checkout_cart_id: cart.publicId },
            },
          });
          await tx.coupon.update({ where: { id: plan.coupon.id }, data: { usedCount: { increment: 1 } } });
        }

        for (const item of items) {
          await this.reserveStock(tx, item, userId, String(order.id));
        }

        createdOrders.push(order);
      }

      await tx.cart.update({ where: { id: cart.id }, data: { status: 'CHECKED_OUT' } });
    });

    await this.audit.write({
      actorUserId: userId,
      action: 'orders.checkout.created',
      entityType: 'checkout',
      entityId: cart.publicId,
      metadata: { order_ids: createdOrders.map((order) => order.id), order_numbers: createdOrders.map((order) => order.orderNumber), total_amount: plan.total },
    }).catch(() => null);

    for (const order of createdOrders) {
      await this.events.publish({
        name: 'OrderCreated',
        aggregateType: 'order',
        aggregateId: order.id,
        actorUserId: userId,
        source: 'orders',
        payload: {
          order_id: order.id,
          order_number: order.orderNumber,
          organization_id: order.organizationId,
          total_amount: Number(order.totalAmount),
        },
      }).catch(() => null);
    }

    return { success: true, message: 'Order created successfully', data: createdOrders };
  }

  async myOrders(userId: number) {
    const data = await this.db.order.findMany({
      where: { userId },
      include: { items: true, organization: true, branch: true, invoices: true, fees: true, statusHistory: { orderBy: { createdAt: 'desc' }, take: 1 } },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data };
  }

  async details(userId: number, id: number) {
    const data = await this.db.order.findFirst({
      where: { id, userId },
      include: {
        items: { include: { listing: true } },
        organization: true,
        branch: true,
        invoices: true,
        fees: true,
        statusHistory: { orderBy: { createdAt: 'asc' } },
      },
    });
    if (!data) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
    return { success: true, data };
  }

  private validateOrderTransition(currentStatus: string, nextStatus: string) {
    if (TERMINAL_ORDER_STATUSES.includes(currentStatus)) {
      throw new BadRequestException({ message: 'لا يمكن تعديل طلب مغلق', error_code: 'ORDER_ALREADY_CLOSED' });
    }
    const allowed = ORDER_STATUS_TRANSITIONS[currentStatus] ?? [];
    if (!allowed.includes(nextStatus)) {
      throw new BadRequestException({ message: `انتقال حالة غير مسموح من ${currentStatus} إلى ${nextStatus}`, error_code: 'INVALID_ORDER_STATUS_TRANSITION' });
    }
  }

  private async reserveStock(tx: any, item: any, actorUserId: number, referenceId: string) {
    const listing = await tx.listing.findUnique({ where: { id: item.listingId } });
    const beforeReserved = Number(listing?.reservedQuantity ?? 0);
    const quantity = Number(item.quantity);
    await tx.listing.update({ where: { id: item.listingId }, data: { reservedQuantity: { increment: quantity } } });
    await tx.listingInventory.upsert({
      where: { listingId: item.listingId },
      update: { reservedQuantity: { increment: quantity } },
      create: { listingId: item.listingId, availableQuantity: Number(listing?.availableQuantity ?? 0), reservedQuantity: quantity },
    }).catch(() => null);
    await tx.stockMovement.create({
      data: {
        listingId: item.listingId,
        movementType: 'ORDER_RESERVED',
        quantity,
        quantityBefore: beforeReserved,
        quantityAfter: beforeReserved + quantity,
        reason: 'Reserved for marketplace order checkout',
        referenceType: 'ORDER',
        referenceId,
        createdByUserId: actorUserId,
      },
    }).catch(() => null);
  }

  private async releaseReservedStock(tx: any, items: any[], actorUserId?: number, referenceId?: string) {
    for (const item of items) {
      const listing = await tx.listing.findUnique({ where: { id: item.listingId } });
      const beforeReserved = Number(listing?.reservedQuantity ?? 0);
      const quantity = Number(item.quantity);
      await tx.listing.update({ where: { id: item.listingId }, data: { reservedQuantity: { decrement: quantity } } });
      await tx.listingInventory.update({ where: { listingId: item.listingId }, data: { reservedQuantity: { decrement: quantity } } }).catch(() => null);
      await tx.stockMovement.create({
        data: {
          listingId: item.listingId,
          movementType: 'ORDER_RESERVATION_RELEASED',
          quantity: -quantity,
          quantityBefore: beforeReserved,
          quantityAfter: Math.max(beforeReserved - quantity, 0),
          reason: 'Released reserved stock for cancelled order',
          referenceType: 'ORDER',
          referenceId: referenceId ?? null,
          createdByUserId: actorUserId ?? null,
        },
      }).catch(() => null);
    }
  }

  private async commitDeliveredStock(tx: any, items: any[], actorUserId: number, referenceId: string) {
    for (const item of items) {
      const listing = await tx.listing.findUnique({ where: { id: item.listingId } });
      const beforeAvailable = Number(listing?.availableQuantity ?? 0);
      const quantity = Number(item.quantity);
      await tx.listing.update({
        where: { id: item.listingId },
        data: {
          reservedQuantity: { decrement: quantity },
          availableQuantity: { decrement: quantity },
        },
      });
      await tx.listingInventory.update({
        where: { listingId: item.listingId },
        data: {
          reservedQuantity: { decrement: quantity },
          availableQuantity: { decrement: quantity },
        },
      }).catch(() => null);
      await tx.stockMovement.create({
        data: {
          listingId: item.listingId,
          movementType: 'ORDER_SOLD',
          quantity: -quantity,
          quantityBefore: beforeAvailable,
          quantityAfter: beforeAvailable - quantity,
          reason: 'Marketplace order delivered',
          referenceType: 'ORDER',
          referenceId,
          createdByUserId: actorUserId,
        },
      }).catch(() => null);
    }
  }

  async cancelByCustomer(userId: number, id: number, dto: CancelOrderDto) {
    const order = await this.db.order.findFirst({ where: { id, userId }, include: { items: true } });
    if (!order) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
    if (!CANCELLABLE_BY_CUSTOMER.includes(order.status)) {
      throw new BadRequestException({ message: 'لا يمكن إلغاء الطلب في هذه الحالة', error_code: 'ORDER_CANNOT_BE_CANCELLED' });
    }

    const updated = await this.db.$transaction(async (tx: any) => {
      const data = await tx.order.update({ where: { id }, data: { status: 'CANCELLED', cancellationReason: dto.reason } });
      await tx.orderStatusHistory.create({ data: { orderId: id, status: 'CANCELLED', changedByUserId: userId, note: dto.reason ?? 'Cancelled by customer' } });
      await this.releaseReservedStock(tx, order.items, userId, String(id));
      return data;
    });

    await this.audit.write({ actorUserId: userId, action: 'orders.customer.cancelled', entityType: 'order', entityId: id, metadata: { reason: dto.reason ?? null } }).catch(() => null);

    await this.events.publish({
      name: 'OrderStatusChanged',
      aggregateType: 'order',
      aggregateId: id,
      actorUserId: userId,
      source: 'orders',
      payload: { status: 'CANCELLED', reason: dto.reason ?? null },
    }).catch(() => null);

    return { success: true, message: 'Order cancelled successfully', data: updated };
  }
}
