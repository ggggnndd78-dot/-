import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AuditService } from '../audit/audit.service';
import { AccountingService } from '../accounting/accounting.service';
import {
  AssignShipmentDto,
  CreateDriverDto,
  CreateShipmentFromOrderDto,
  CreateShippingCompanyDto,
  UpdateDriverDto,
  UpdateShipmentStatusDto,
  UpdateShippingCompanyDto,
  UpsertDeliveryFeeDto,
} from './dto/delivery.dto';

const ALLOWED_SHIPMENT_TRANSITIONS: Record<string, string[]> = {
  PENDING: ['READY_FOR_PICKUP', 'PICKED_UP', 'CANCELLED'],
  READY_FOR_PICKUP: ['PICKED_UP', 'OUT_FOR_DELIVERY', 'CANCELLED'],
  PICKED_UP: ['IN_TRANSIT', 'OUT_FOR_DELIVERY', 'FAILED', 'RETURNED'],
  IN_TRANSIT: ['OUT_FOR_DELIVERY', 'FAILED', 'RETURNED'],
  OUT_FOR_DELIVERY: ['DELIVERED', 'FAILED', 'RETURNED'],
  FAILED: ['IN_TRANSIT', 'CANCELLED', 'RETURNED'],
};

@Injectable()
export class DeliveryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly audit: AuditService,
    private readonly accounting: AccountingService,
  ) {}

  private get db() { return this.prisma as any; }

  private async roleCodes(userId: number) {
    const roles = await this.db.userRole.findMany({ where: { userId }, include: { role: true } });
    return roles.map((entry: any) => entry.role.code);
  }

  private async isPlatformAdmin(userId: number) {
    const codes = await this.roleCodes(userId);
    return codes.includes('admin_super') || codes.includes('admin_operations');
  }

  private async assertOrganizationAccess(userId: number, organizationId: number) {
    if (await this.isPlatformAdmin(userId)) return { admin: true } as any;
    const member = await this.db.organizationMember.findFirst({ where: { userId, organizationId, status: 'ACTIVE' } });
    if (!member) throw new ForbiddenException({ message: 'ليس لديك صلاحية على هذه المؤسسة', error_code: 'ORGANIZATION_ACCESS_DENIED' });
    return member;
  }

  private async driverProfileForUser(userId: number) {
    return this.db.driver.findFirst({ where: { userId, status: 'ACTIVE' } });
  }

  async methods() {
    const data = await this.db.deliveryMethod.findMany({ where: { status: 'ACTIVE' }, orderBy: [{ kind: 'asc' }, { id: 'asc' }] });
    return { success: true, data };
  }

  async deliveryFees(params: { cityId?: number; branchId?: number; deliveryMethodId?: number }) {
    const where: any = { isActive: true };
    if (params.cityId) where.cityId = params.cityId;
    if (params.branchId) where.branchId = params.branchId;
    if (params.deliveryMethodId) where.deliveryMethodId = params.deliveryMethodId;
    const data = await this.db.deliveryFee.findMany({ where, include: { city: true, branch: true, deliveryMethod: true }, orderBy: { id: 'desc' }, take: 100 });
    return { success: true, data };
  }

  async upsertDeliveryFee(userId: number, dto: UpsertDeliveryFeeDto) {
    if (dto.organizationId) await this.assertOrganizationAccess(userId, Number(dto.organizationId));
    if (dto.branchId) {
      const branch = await this.db.organizationBranch.findUnique({ where: { id: Number(dto.branchId) } });
      if (!branch) throw new NotFoundException({ message: 'Branch not found', error_code: 'BRANCH_NOT_FOUND' });
      await this.assertOrganizationAccess(userId, branch.organizationId);
    }
    const data = await this.db.deliveryFee.create({
      data: {
        scope: dto.scope ?? 'CITY',
        organizationId: dto.organizationId ?? null,
        branchId: dto.branchId ?? null,
        cityId: dto.cityId ?? null,
        deliveryMethodId: dto.deliveryMethodId ?? null,
        label: dto.label ?? null,
        baseFee: dto.baseFee,
        minFee: dto.minFee ?? null,
        maxFee: dto.maxFee ?? null,
        currency: dto.currency ?? 'YER',
        estimatedMinDays: dto.estimatedMinDays ?? null,
        estimatedMaxDays: dto.estimatedMaxDays ?? null,
        isActive: dto.isActive ?? true,
      },
    });
    await this.audit.write({ actorUserId: userId, action: 'delivery.fee.created', entityType: 'delivery_fee', entityId: data.id, metadata: { scope: dto.scope, city_id: dto.cityId, branch_id: dto.branchId } }).catch(() => null);
    return { success: true, message: 'Delivery fee created', data };
  }

  async shippingCompanies(params: { cityId?: number; organizationId?: number }) {
    const where: any = { status: 'ACTIVE' };
    if (params.cityId) where.cityId = params.cityId;
    if (params.organizationId) where.organizationId = params.organizationId;
    const data = await this.db.localShippingCompany.findMany({ where, include: { city: true, organization: true }, orderBy: { id: 'desc' }, take: 100 });
    return { success: true, data };
  }

  async createShippingCompany(userId: number, dto: CreateShippingCompanyDto) {
    if (dto.organizationId) await this.assertOrganizationAccess(userId, Number(dto.organizationId));
    const data = await this.db.localShippingCompany.create({
      data: {
        organizationId: dto.organizationId ?? null,
        cityId: dto.cityId ?? null,
        code: dto.code ?? null,
        nameAr: dto.nameAr,
        nameEn: dto.nameEn ?? null,
        phone: dto.phone ?? null,
        trackingUrlTemplate: dto.trackingUrlTemplate ?? null,
        integrationCode: dto.integrationCode ?? null,
        supportsCod: dto.supportsCod ?? false,
        createdByUserId: userId,
      },
    });
    await this.audit.write({ actorUserId: userId, action: 'delivery.shipping_company.created', entityType: 'local_shipping_company', entityId: data.id }).catch(() => null);
    return { success: true, message: 'Shipping company created', data };
  }

  async updateShippingCompany(userId: number, id: number, dto: UpdateShippingCompanyDto) {
    const company = await this.db.localShippingCompany.findUnique({ where: { id } });
    if (!company) throw new NotFoundException({ message: 'Shipping company not found', error_code: 'SHIPPING_COMPANY_NOT_FOUND' });
    if (company.organizationId) await this.assertOrganizationAccess(userId, company.organizationId);
    const data = await this.db.localShippingCompany.update({
      where: { id },
      data: {
        nameAr: dto.nameAr ?? undefined,
        nameEn: dto.nameEn ?? undefined,
        phone: dto.phone ?? undefined,
        cityId: dto.cityId ?? undefined,
        trackingUrlTemplate: dto.trackingUrlTemplate ?? undefined,
        integrationCode: dto.integrationCode ?? undefined,
        supportsCod: dto.supportsCod ?? undefined,
        status: dto.status ?? undefined,
      },
    });
    await this.audit.write({ actorUserId: userId, action: 'delivery.shipping_company.updated', entityType: 'local_shipping_company', entityId: id }).catch(() => null);
    return { success: true, message: 'Shipping company updated', data };
  }

  async drivers(userId: number, organizationId?: number) {
    const where: any = {};
    if (organizationId) {
      await this.assertOrganizationAccess(userId, organizationId);
      where.organizationId = organizationId;
    } else if (!(await this.isPlatformAdmin(userId))) {
      const memberships = await this.db.organizationMember.findMany({ where: { userId, status: 'ACTIVE' }, select: { organizationId: true } });
      where.organizationId = { in: memberships.map((m: any) => m.organizationId) };
    }
    const data = await this.db.driver.findMany({ where, include: { organization: true, branch: true, user: { select: { id: true, displayName: true, phoneNormalized: true } } }, orderBy: { id: 'desc' }, take: 200 });
    return { success: true, data };
  }

  async createDriver(userId: number, dto: CreateDriverDto) {
    if (!dto.organizationId && !(await this.isPlatformAdmin(userId))) {
      throw new BadRequestException({ message: 'يجب تحديد المؤسسة للسائق', error_code: 'DRIVER_ORGANIZATION_REQUIRED' });
    }
    if (dto.organizationId) await this.assertOrganizationAccess(userId, Number(dto.organizationId));
    if (dto.branchId) {
      const branch = await this.db.organizationBranch.findUnique({ where: { id: Number(dto.branchId) } });
      if (!branch) throw new NotFoundException({ message: 'Branch not found', error_code: 'BRANCH_NOT_FOUND' });
      if (dto.organizationId && branch.organizationId !== Number(dto.organizationId)) throw new BadRequestException({ message: 'الفرع لا يتبع المؤسسة', error_code: 'BRANCH_ORGANIZATION_MISMATCH' });
    }
    const data = await this.db.driver.create({
      data: {
        userId: dto.userId ?? null,
        organizationId: dto.organizationId ?? null,
        branchId: dto.branchId ?? null,
        fullName: dto.fullName,
        phone: dto.phone ?? null,
        driverType: dto.driverType ?? 'INTERNAL',
        isAvailable: dto.isAvailable ?? true,
        vehicleType: dto.vehicleType ?? null,
        vehiclePlate: dto.vehiclePlate ?? null,
        currentCityId: dto.currentCityId ?? null,
        createdByUserId: userId,
      },
    });
    await this.audit.write({ actorUserId: userId, action: 'delivery.driver.created', entityType: 'driver', entityId: data.id, metadata: { organization_id: data.organizationId } }).catch(() => null);
    return { success: true, message: 'Driver created', data };
  }

  async updateDriver(userId: number, id: number, dto: UpdateDriverDto) {
    const driver = await this.db.driver.findUnique({ where: { id } });
    if (!driver) throw new NotFoundException({ message: 'Driver not found', error_code: 'DRIVER_NOT_FOUND' });
    if (driver.organizationId) await this.assertOrganizationAccess(userId, driver.organizationId);
    const data = await this.db.driver.update({
      where: { id },
      data: {
        fullName: dto.fullName ?? undefined,
        phone: dto.phone ?? undefined,
        status: dto.status ?? undefined,
        isAvailable: dto.isAvailable ?? undefined,
        vehicleType: dto.vehicleType ?? undefined,
        vehiclePlate: dto.vehiclePlate ?? undefined,
        currentCityId: dto.currentCityId ?? undefined,
      },
    });
    await this.audit.write({ actorUserId: userId, action: 'delivery.driver.updated', entityType: 'driver', entityId: id }).catch(() => null);
    return { success: true, message: 'Driver updated', data };
  }

  private makeShipmentNumber() {
    const d = new Date();
    const date = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
    return `SHP-${date}-${Math.floor(100000 + Math.random() * 900000)}`;
  }

  private async createShipmentNumber(tx: any) {
    for (let attempt = 0; attempt < 5; attempt += 1) {
      const shipmentNumber = this.makeShipmentNumber();
      const exists = await tx.shipment.findUnique({ where: { shipmentNumber } });
      if (!exists) return shipmentNumber;
    }
    throw new BadRequestException({ message: 'تعذر توليد رقم شحنة فريد', error_code: 'SHIPMENT_NUMBER_GENERATION_FAILED' });
  }

  private async resolveDeliveryMethod(methodId: number | undefined, fulfillmentMethod: string) {
    if (methodId) {
      const method = await this.db.deliveryMethod.findFirst({ where: { id: methodId, status: 'ACTIVE' } });
      if (!method) throw new BadRequestException({ message: 'طريقة التوصيل غير متاحة', error_code: 'DELIVERY_METHOD_NOT_FOUND' });
      return method;
    }
    const preferredKind = fulfillmentMethod === 'PICKUP' ? 'STORE_PICKUP' : 'DRIVER_DELIVERY';
    const preferred = await this.db.deliveryMethod.findFirst({ where: { kind: preferredKind, status: 'ACTIVE' } }).catch(() => null);
    if (preferred) return preferred;
    return this.db.deliveryMethod.findFirst({ where: { status: 'ACTIVE' }, orderBy: { id: 'asc' } });
  }

  private async resolveDeliveryFee(order: any, method: any, dto: CreateShipmentFromOrderDto) {
    if (dto.deliveryFeeId) {
      const fee = await this.db.deliveryFee.findFirst({ where: { id: dto.deliveryFeeId, isActive: true } });
      if (!fee) throw new BadRequestException({ message: 'قاعدة رسوم التوصيل غير صحيحة', error_code: 'DELIVERY_FEE_NOT_FOUND' });
      return { id: fee.id, amount: Number(fee.baseFee ?? 0) };
    }
    if (dto.deliveryFee != null) return { id: null, amount: Number(dto.deliveryFee) };

    const fee = await this.db.deliveryFee.findFirst({
      where: {
        isActive: true,
        OR: [
          { branchId: order.branchId ?? -1, deliveryMethodId: method?.id ?? undefined },
          { cityId: order.cityId ?? -1, deliveryMethodId: method?.id ?? undefined },
          { cityId: order.cityId ?? -1, deliveryMethodId: null },
        ],
      },
      orderBy: { id: 'desc' },
    }).catch(() => null);
    if (fee) return { id: fee.id, amount: Number(fee.baseFee ?? 0) };

    const cityFee = order.cityId ? await this.db.cityDeliveryFee.findUnique({ where: { cityId: order.cityId } }).catch(() => null) : null;
    if (cityFee?.isDeliveryAvailable) return { id: null, amount: Number(cityFee.deliveryFee ?? 0) };
    return { id: null, amount: Number(order.deliveryFee ?? method?.baseFee ?? 0) };
  }

  private async validateDriverForShipment(driverId: number | undefined, organizationId: number, cityId?: number | null) {
    if (!driverId) return null;
    const driver = await this.db.driver.findFirst({ where: { id: driverId, status: 'ACTIVE', isAvailable: true } });
    if (!driver) throw new BadRequestException({ message: 'السائق غير متاح', error_code: 'DRIVER_NOT_AVAILABLE' });
    if (driver.organizationId && driver.organizationId !== organizationId) throw new BadRequestException({ message: 'السائق لا يتبع المؤسسة', error_code: 'DRIVER_ORGANIZATION_MISMATCH' });
    if (driver.currentCityId && cityId && driver.currentCityId !== cityId) throw new BadRequestException({ message: 'السائق ليس في نفس المدينة', error_code: 'DRIVER_CITY_MISMATCH' });
    return driver;
  }

  private async validateShippingCompany(companyId: number | undefined, cityId?: number | null) {
    if (!companyId) return null;
    const company = await this.db.localShippingCompany.findFirst({ where: { id: companyId, status: 'ACTIVE' } });
    if (!company) throw new BadRequestException({ message: 'شركة الشحن غير متاحة', error_code: 'SHIPPING_COMPANY_NOT_AVAILABLE' });
    if (company.cityId && cityId && company.cityId !== cityId) throw new BadRequestException({ message: 'شركة الشحن لا تعمل في هذه المدينة', error_code: 'SHIPPING_COMPANY_CITY_MISMATCH' });
    return company;
  }

  async createFromOrder(userId: number, orderId: number, dto: CreateShipmentFromOrderDto) {
    const order = await this.db.order.findUnique({ where: { id: orderId }, include: { user: true, shipment: true, branch: true, city: true } });
    if (!order) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
    await this.assertOrganizationAccess(userId, order.organizationId);
    if (order.shipment) throw new BadRequestException({ message: 'يوجد شحنة لهذا الطلب بالفعل', error_code: 'SHIPMENT_ALREADY_EXISTS' });
    if (!['CONFIRMED', 'PROCESSING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY'].includes(order.status)) {
      throw new BadRequestException({ message: 'لا يمكن إنشاء شحنة في حالة الطلب الحالية', error_code: 'ORDER_STATUS_NOT_SHIPPABLE' });
    }

    const method = await this.resolveDeliveryMethod(dto.deliveryMethodId, order.fulfillmentMethod);
    if (method?.kind === 'STORE_PICKUP' && order.fulfillmentMethod !== 'PICKUP') throw new BadRequestException({ message: 'طريقة الاستلام من الفرع لا تناسب طلب التوصيل', error_code: 'DELIVERY_METHOD_MISMATCH' });
    if (method?.kind !== 'STORE_PICKUP' && order.fulfillmentMethod !== 'DELIVERY') throw new BadRequestException({ message: 'الطلب ليس طلب توصيل', error_code: 'ORDER_NOT_DELIVERY' });

    const driver = await this.validateDriverForShipment(dto.driverId, order.organizationId, order.cityId);
    const company = await this.validateShippingCompany(dto.shippingCompanyId, order.cityId);
    const fee = await this.resolveDeliveryFee(order, method, dto);

    const data = await this.db.$transaction(async (tx: any) => {
      const shipment = await tx.shipment.create({
        data: {
          shipmentNumber: await this.createShipmentNumber(tx),
          orderId: order.id,
          organizationId: order.organizationId,
          branchId: order.branchId,
          cityId: order.cityId,
          deliveryMethodId: method?.id ?? null,
          deliveryFeeId: fee.id,
          driverId: driver?.id ?? null,
          shippingCompanyId: company?.id ?? null,
          createdByUserId: userId,
          trackingNumber: dto.trackingNumber ?? null,
          externalShipmentNumber: dto.externalShipmentNumber ?? null,
          externalTrackingUrl: dto.externalTrackingUrl ?? null,
          courierName: dto.courierName ?? company?.nameAr ?? driver?.fullName ?? null,
          recipientName: dto.recipientName ?? order.user.displayName ?? null,
          recipientPhone: dto.recipientPhone ?? order.user.phoneNormalized ?? order.user.phoneE164 ?? null,
          deliveryAddress: dto.deliveryAddress ?? order.branch?.addressLine1 ?? null,
          deliveryFee: fee.amount,
          currency: order.currency,
          estimatedDeliveryAt: dto.estimatedDeliveryAt ? new Date(dto.estimatedDeliveryAt) : null,
          assignedAt: driver?.id || company?.id ? new Date() : null,
          notes: dto.notes ?? null,
          events: { create: { status: 'PENDING', changedByUserId: userId, driverId: driver?.id ?? null, note: driver?.id ? 'Shipment created and driver assigned' : company?.id ? 'Shipment created and shipping company selected' : 'Shipment created' } },
        },
        include: { events: true, driver: true, shippingCompany: true, deliveryMethod: true },
      });
      await tx.order.update({ where: { id: order.id }, data: { status: method?.kind === 'STORE_PICKUP' ? 'READY_FOR_PICKUP' : 'OUT_FOR_DELIVERY' } });
      await tx.orderStatusHistory.create({ data: { orderId: order.id, status: method?.kind === 'STORE_PICKUP' ? 'READY_FOR_PICKUP' : 'OUT_FOR_DELIVERY', changedByUserId: userId, note: 'Shipment created' } });
      return shipment;
    });

    await this.audit.write({ actorUserId: userId, action: 'delivery.shipment.created', entityType: 'shipment', entityId: data.id, metadata: { order_id: order.id, driver_id: data.driverId, shipping_company_id: data.shippingCompanyId } }).catch(() => null);
    await this.notifications.createForUser(order.userId, 'تم إنشاء شحنة لطلبك', `رقم الشحنة: ${data.shipmentNumber}`, { order_id: order.id, shipment_id: data.id }).catch(() => null);
    if (driver?.userId) await this.notifications.createForUser(driver.userId, 'تم تعيين شحنة لك', `رقم الشحنة: ${data.shipmentNumber}`, { shipment_id: data.id, order_id: order.id }).catch(() => null);
    return { success: true, message: 'Shipment created', data };
  }

  async assignShipment(userId: number, id: number, dto: AssignShipmentDto) {
    const shipment = await this.db.shipment.findUnique({ where: { id }, include: { order: true } });
    if (!shipment) throw new NotFoundException({ message: 'Shipment not found', error_code: 'SHIPMENT_NOT_FOUND' });
    await this.assertOrganizationAccess(userId, shipment.organizationId);
    const driver = await this.validateDriverForShipment(dto.driverId, shipment.organizationId, shipment.cityId);
    const company = await this.validateShippingCompany(dto.shippingCompanyId, shipment.cityId);
    if (!driver && !company) throw new BadRequestException({ message: 'اختر سائقًا أو شركة شحن', error_code: 'ASSIGNMENT_TARGET_REQUIRED' });

    const data = await this.db.$transaction(async (tx: any) => {
      const updated = await tx.shipment.update({
        where: { id },
        data: {
          driverId: driver?.id ?? shipment.driverId,
          shippingCompanyId: company?.id ?? shipment.shippingCompanyId,
          trackingNumber: dto.trackingNumber ?? shipment.trackingNumber,
          externalShipmentNumber: dto.externalShipmentNumber ?? shipment.externalShipmentNumber,
          externalTrackingUrl: dto.externalTrackingUrl ?? shipment.externalTrackingUrl,
          courierName: company?.nameAr ?? driver?.fullName ?? shipment.courierName,
          assignedAt: new Date(),
        },
        include: { driver: true, shippingCompany: true, events: true },
      });
      await tx.shipmentTrackingEvent.create({ data: { shipmentId: id, status: shipment.status, changedByUserId: userId, driverId: driver?.id ?? null, note: dto.note ?? 'Shipment assigned' } });
      return updated;
    });
    await this.audit.write({ actorUserId: userId, action: 'delivery.shipment.assigned', entityType: 'shipment', entityId: id, metadata: { driver_id: data.driverId, shipping_company_id: data.shippingCompanyId } }).catch(() => null);
    if (driver?.userId) await this.notifications.createForUser(driver.userId, 'تم تعيين شحنة لك', `رقم الشحنة: ${data.shipmentNumber}`, { shipment_id: data.id }).catch(() => null);
    return { success: true, message: 'Shipment assigned', data };
  }

  async driverAcceptShipment(userId: number, id: number, note?: string) {
    const driver = await this.driverProfileForUser(userId);
    if (!driver) throw new ForbiddenException({ message: 'حسابك غير مربوط كسائق', error_code: 'DRIVER_PROFILE_REQUIRED' });
    const shipment = await this.db.shipment.findFirst({ where: { id, driverId: driver.id } });
    if (!shipment) throw new NotFoundException({ message: 'Shipment not assigned to this driver', error_code: 'SHIPMENT_NOT_ASSIGNED_TO_DRIVER' });
    const data = await this.db.$transaction(async (tx: any) => {
      const updated = await tx.shipment.update({ where: { id }, data: { acceptedAt: new Date() } });
      await tx.shipmentTrackingEvent.create({ data: { shipmentId: id, status: shipment.status, changedByUserId: userId, driverId: driver.id, note: note ?? 'Driver accepted shipment' } });
      return updated;
    });
    await this.audit.write({ actorUserId: userId, action: 'delivery.shipment.driver_accepted', entityType: 'shipment', entityId: id, metadata: { driver_id: driver.id } }).catch(() => null);
    return { success: true, message: 'Shipment accepted', data };
  }

  async myShipments(userId: number) {
    const data = await this.db.shipment.findMany({
      where: { order: { userId } },
      include: { order: true, events: { orderBy: { createdAt: 'asc' } }, deliveryMethod: true, driver: true, shippingCompany: true },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data };
  }

  async driverShipments(userId: number) {
    const driver = await this.driverProfileForUser(userId);
    if (!driver) return { success: true, data: [] };
    const data = await this.db.shipment.findMany({
      where: { driverId: driver.id },
      include: { order: true, events: { orderBy: { createdAt: 'asc' } }, deliveryMethod: true, driver: true, shippingCompany: true },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    return { success: true, data };
  }

  async merchantShipments(userId: number) {
    const memberships = await this.db.organizationMember.findMany({ where: { userId, status: 'ACTIVE' }, select: { organizationId: true } });
    const organizationIds = memberships.map((m: any) => m.organizationId);
    const data = await this.db.shipment.findMany({
      where: { organizationId: { in: organizationIds } },
      include: { order: true, events: { orderBy: { createdAt: 'asc' } }, deliveryMethod: true, driver: true, shippingCompany: true },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
    return { success: true, data };
  }

  async adminShipments(params: { status?: string; cityId?: number; driverId?: number; take?: number; skip?: number }) {
    const where: any = {};
    if (params.status) where.status = params.status;
    if (params.cityId) where.cityId = params.cityId;
    if (params.driverId) where.driverId = params.driverId;
    const data = await this.db.shipment.findMany({
      where,
      include: { order: true, organization: true, branch: true, city: true, events: { orderBy: { createdAt: 'asc' } }, deliveryMethod: true, driver: true, shippingCompany: true },
      orderBy: { createdAt: 'desc' },
      take: Math.min(Math.max(params.take ?? 80, 1), 200),
      skip: params.skip ?? 0,
    });
    return { success: true, data };
  }

  async details(userId: number, id: number) {
    const shipment = await this.db.shipment.findUnique({ where: { id }, include: { order: true, events: { orderBy: { createdAt: 'asc' }, include: { changedBy: { select: { id: true, displayName: true } }, driver: true } }, deliveryMethod: true, driver: true, shippingCompany: true, deliveryFeeRule: true } });
    if (!shipment) throw new NotFoundException({ message: 'Shipment not found', error_code: 'SHIPMENT_NOT_FOUND' });
    if (shipment.order.userId === userId) return { success: true, data: shipment };
    if (shipment.driver?.userId === userId) return { success: true, data: shipment };
    if (await this.isPlatformAdmin(userId)) return { success: true, data: shipment };
    await this.assertOrganizationAccess(userId, shipment.organizationId);
    return { success: true, data: shipment };
  }

  private validateTransition(current: string, next: string) {
    if (['DELIVERED', 'CANCELLED', 'RETURNED'].includes(current)) {
      throw new BadRequestException({ message: 'لا يمكن تعديل شحنة مغلقة', error_code: 'SHIPMENT_ALREADY_CLOSED' });
    }
    const allowed = ALLOWED_SHIPMENT_TRANSITIONS[current] ?? [];
    if (!allowed.includes(next)) {
      throw new BadRequestException({ message: `انتقال حالة غير مسموح من ${current} إلى ${next}`, error_code: 'INVALID_SHIPMENT_STATUS_TRANSITION' });
    }
  }

  private async assertShipmentUpdater(userId: number, shipment: any) {
    if (await this.isPlatformAdmin(userId)) return { driver: null };
    const driver = await this.driverProfileForUser(userId);
    if (driver && shipment.driverId === driver.id) return { driver };
    await this.assertOrganizationAccess(userId, shipment.organizationId);
    return { driver: null };
  }


  async rescheduleShipment(userId: number, id: number, dto: { scheduledAt?: string; note?: string }) {
    const shipment = await this.db.shipment.findUnique({ where: { id }, include: { order: true, driver: true } });
    if (!shipment) throw new NotFoundException({ message: 'Shipment not found', error_code: 'SHIPMENT_NOT_FOUND' });
    await this.assertShipmentUpdater(userId, shipment);
    if (['DELIVERED', 'CANCELLED', 'RETURNED'].includes(shipment.status)) {
      throw new BadRequestException({ message: 'لا يمكن إعادة جدولة شحنة مغلقة', error_code: 'SHIPMENT_ALREADY_CLOSED' });
    }
    const scheduledAt = dto.scheduledAt ? new Date(dto.scheduledAt) : null;
    if (!scheduledAt || Number.isNaN(scheduledAt.getTime())) {
      throw new BadRequestException({ message: 'موعد الشحنة غير صالح', error_code: 'INVALID_SHIPMENT_SCHEDULE' });
    }
    const data = await this.db.$transaction(async (tx: any) => {
      const updated = await tx.shipment.update({ where: { id }, data: { estimatedDeliveryAt: scheduledAt, notes: dto.note ?? shipment.notes } });
      await tx.shipmentTrackingEvent.create({ data: { shipmentId: id, status: shipment.status, changedByUserId: userId, driverId: shipment.driverId ?? null, note: dto.note ?? 'Shipment rescheduled' } });
      return updated;
    });
    await this.audit.write({ actorUserId: userId, action: 'delivery.shipment.rescheduled', entityType: 'shipment', entityId: id, metadata: { scheduled_at: scheduledAt.toISOString() } }).catch(() => null);
    return { success: true, message: 'Shipment rescheduled', data };
  }

  async updateStatus(userId: number, id: number, dto: UpdateShipmentStatusDto) {
    const shipment = await this.db.shipment.findUnique({ where: { id }, include: { order: true, driver: true } });
    if (!shipment) throw new NotFoundException({ message: 'Shipment not found', error_code: 'SHIPMENT_NOT_FOUND' });
    const actor = await this.assertShipmentUpdater(userId, shipment);
    this.validateTransition(shipment.status, dto.status);

    const data = await this.db.$transaction(async (tx: any) => {
      const payload: any = { status: dto.status };
      if (dto.status === 'READY_FOR_PICKUP') payload.preparedAt = new Date();
      if (dto.status === 'PICKED_UP') payload.pickedUpAt = new Date();
      if (dto.status === 'DELIVERED') { payload.deliveredAt = new Date(); payload.completedAt = new Date(); }
      if (dto.status === 'CANCELLED') payload.cancelledAt = new Date();
      const updated = await tx.shipment.update({ where: { id }, data: payload, include: { driver: true, shippingCompany: true } });
      await tx.shipmentTrackingEvent.create({ data: { shipmentId: id, status: dto.status, changedByUserId: userId, driverId: actor.driver?.id ?? shipment.driverId ?? null, note: dto.note ?? null, locationText: dto.locationText ?? null } });
      if (dto.status === 'OUT_FOR_DELIVERY') {
        await tx.order.update({ where: { id: shipment.orderId }, data: { status: 'OUT_FOR_DELIVERY' } });
        await tx.orderStatusHistory.create({ data: { orderId: shipment.orderId, status: 'OUT_FOR_DELIVERY', changedByUserId: userId, note: dto.note ?? 'Out for delivery' } });
      }
      if (dto.status === 'DELIVERED') {
        await tx.order.update({ where: { id: shipment.orderId }, data: { status: 'DELIVERED' } });
        await tx.orderStatusHistory.create({ data: { orderId: shipment.orderId, status: 'DELIVERED', changedByUserId: userId, note: dto.note ?? 'Delivered' } });
        if (shipment.driverId) await tx.driver.update({ where: { id: shipment.driverId }, data: { completedShipments: { increment: 1 }, isAvailable: true } }).catch(() => null);
        if (shipment.order.paymentMethod === 'CASH_ON_DELIVERY') await this.accounting.postCodDeliveredForOrder(tx, shipment.order, userId);
      }
      return updated;
    });

    await this.audit.write({ actorUserId: userId, action: 'delivery.shipment.status_updated', entityType: 'shipment', entityId: id, metadata: { status: dto.status, order_id: shipment.orderId } }).catch(() => null);
    await this.notifications.createForUser(shipment.order.userId, 'تحديث حالة الشحنة', `حالة الشحنة الآن: ${dto.status}`, { shipment_id: shipment.id, order_id: shipment.orderId, status: dto.status }).catch(() => null);
    return { success: true, message: 'Shipment status updated', data };
  }
}
