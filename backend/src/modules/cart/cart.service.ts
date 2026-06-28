import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { AddCartItemDto, UpdateCartItemDto } from './dto/cart.dto';

@Injectable()
export class CartService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}
  private get db() { return this.prisma as any; }

  private async getActiveCart(userId: number) {
    let cart = await this.db.cart.findFirst({ where: { userId, status: 'ACTIVE' } });
    if (!cart) cart = await this.db.cart.create({ data: { userId } });
    return cart;
  }

  private validateListingQuantity(listing: any, requestedQuantity: number) {
    if (!listing || listing.status !== 'ACTIVE' || listing.approvalStatus !== 'APPROVED') {
      throw new NotFoundException({ message: 'Listing not available', error_code: 'LISTING_NOT_AVAILABLE' });
    }
    if (requestedQuantity < listing.minOrderQuantity) {
      throw new BadRequestException({ message: `الحد الأدنى للطلب هو ${listing.minOrderQuantity}`, error_code: 'MIN_ORDER_QUANTITY' });
    }
    const available = listing.availableQuantity - listing.reservedQuantity;
    if (available < requestedQuantity) {
      throw new BadRequestException({ message: 'الكمية المطلوبة غير متوفرة', error_code: 'INSUFFICIENT_STOCK' });
    }
  }

  async getCart(userId: number) {
    const cart = await this.getActiveCart(userId);
    const data = await this.db.cart.findUnique({
      where: { id: cart.id },
      include: { items: { include: { listing: { include: { product: { include: { media: true, partBrand: true, category: true } }, organization: true, branch: true } } } } },
    });
    const subtotal = (data.items ?? []).reduce((sum: number, item: any) => {
      const price = Number(item.listing.salePrice ?? item.listing.unitPrice);
      return sum + price * item.quantity;
    }, 0);
    return { success: true, data: { ...data, subtotal, currency: 'YER' } };
  }

  async addItem(userId: number, dto: AddCartItemDto) {
    const listing = await this.db.listing.findUnique({ where: { id: dto.listingId } });
    const cart = await this.getActiveCart(userId);
    const existing = await this.db.cartItem.findFirst({ where: { cartId: cart.id, listingId: dto.listingId } });
    const requestedQuantity = (existing?.quantity ?? 0) + dto.quantity;
    this.validateListingQuantity(listing, requestedQuantity);

    const data = await this.db.cartItem.upsert({
      where: { cartId_listingId: { cartId: cart.id, listingId: dto.listingId } },
      update: { quantity: requestedQuantity },
      create: { cartId: cart.id, listingId: dto.listingId, quantity: dto.quantity },
    });
    await this.audit.write({ actorUserId: userId, action: 'cart.item.added', entityType: 'cart_item', entityId: data.id, metadata: { cart_id: cart.id, listing_id: dto.listingId, quantity: requestedQuantity } }).catch(() => null);
    return { success: true, message: 'Item added to cart', data };
  }

  async updateItem(userId: number, itemId: number, dto: UpdateCartItemDto) {
    const cart = await this.getActiveCart(userId);
    const item = await this.db.cartItem.findFirst({ where: { id: itemId, cartId: cart.id }, include: { listing: true } });
    if (!item) throw new NotFoundException({ message: 'Cart item not found', error_code: 'CART_ITEM_NOT_FOUND' });
    this.validateListingQuantity(item.listing, dto.quantity);
    const data = await this.db.cartItem.update({ where: { id: itemId }, data: { quantity: dto.quantity } });
    await this.audit.write({ actorUserId: userId, action: 'cart.item.updated', entityType: 'cart_item', entityId: itemId, metadata: { cart_id: cart.id, quantity: dto.quantity } }).catch(() => null);
    return { success: true, message: 'Cart item updated', data };
  }

  async removeItem(userId: number, itemId: number) {
    const cart = await this.getActiveCart(userId);
    const item = await this.db.cartItem.findFirst({ where: { id: itemId, cartId: cart.id } });
    if (!item) throw new NotFoundException({ message: 'Cart item not found', error_code: 'CART_ITEM_NOT_FOUND' });
    await this.db.cartItem.delete({ where: { id: itemId } });
    await this.audit.write({ actorUserId: userId, action: 'cart.item.removed', entityType: 'cart_item', entityId: itemId, metadata: { cart_id: cart.id } }).catch(() => null);
    return { success: true, message: 'Cart item removed', data: null };
  }

  async clear(userId: number) {
    const cart = await this.getActiveCart(userId);
    await this.db.cartItem.deleteMany({ where: { cartId: cart.id } });
    await this.audit.write({ actorUserId: userId, action: 'cart.cleared', entityType: 'cart', entityId: cart.id }).catch(() => null);
    return { success: true, message: 'Cart cleared', data: null };
  }
}
