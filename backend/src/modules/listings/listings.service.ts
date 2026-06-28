import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ListingQueryDto } from './dto/listings.dto';

@Injectable()
export class ListingsService {
  constructor(private readonly prisma: PrismaService) {}
  private get db() { return this.prisma as any; }

  private effectivePriceOrder() {
    return [{ salePrice: 'asc' }, { unitPrice: 'asc' }, { createdAt: 'desc' }] as any;
  }

  private buildWhere(query: ListingQueryDto, publicOnly = true) {
    const where: any = {};
    if (publicOnly) {
      where.status = 'ACTIVE';
      where.approvalStatus = 'APPROVED';
      where.availableQuantity = { gt: 0 };
    }
    if (query.q) {
      const q = query.q.trim();
      where.OR = [
        { title: { contains: q } },
        { description: { contains: q } },
        { product: { nameAr: { contains: q } } },
        { product: { nameEn: { contains: q } } },
        { product: { sku: { contains: q } } },
        { product: { oemNumber: { contains: q } } },
        { product: { aftermarketCode: { contains: q } } },
        { product: { partBrand: { nameAr: { contains: q } } } },
        { product: { partBrand: { nameEn: { contains: q } } } },
        { city: { nameAr: { contains: q } } },
      ];
    }
    if (query.productId) where.productId = query.productId;
    if (query.cityId) where.cityId = query.cityId;
    if (query.organizationId) where.organizationId = query.organizationId;
    if (query.qualityType) where.qualityType = query.qualityType;
    if ((query as any).condition) where.condition = (query as any).condition;
    if (query.categoryId || query.partBrandId || query.makeId || query.modelId || query.year) {
      where.product = { ...(where.product ?? {}) };
      if (query.categoryId) where.product.categoryId = query.categoryId;
      if (query.partBrandId) where.product.partBrandId = query.partBrandId;
      if (query.makeId || query.modelId || query.year) {
        where.product.OR = [
          { isUniversal: true },
          {
            compatibilities: {
              some: {
                ...(query.makeId ? { makeId: query.makeId } : {}),
                ...(query.modelId ? { OR: [{ modelId: query.modelId }, { modelId: null }] } : {}),
                ...(query.year ? { AND: [
                  { OR: [{ yearFrom: null }, { yearFrom: { lte: query.year } }] },
                  { OR: [{ yearTo: null }, { yearTo: { gte: query.year } }] },
                ] } : {}),
              },
            },
          },
        ];
      }
    }
    if (query.minPrice || query.maxPrice) {
      const priceRange = { ...(query.minPrice ? { gte: query.minPrice } : {}), ...(query.maxPrice ? { lte: query.maxPrice } : {}) };
      where.AND = [
        ...(where.AND ?? []),
        { OR: [{ salePrice: priceRange }, { salePrice: null, unitPrice: priceRange }] },
      ];
    }
    return where;
  }

  private mapListing(item: any) {
    const bestPrice = item.salePrice ?? item.unitPrice;
    return {
      id: item.id,
      public_id: item.publicId,
      product_id: item.productId,
      title: item.title,
      description: item.description,
      condition: item.condition,
      quality_type: item.qualityType,
      price: Number(bestPrice),
      unit_price: Number(item.unitPrice),
      sale_price: item.salePrice == null ? null : Number(item.salePrice),
      currency: item.currency,
      available_quantity: item.availableQuantity,
      seller: item.organization?.displayName,
      branch: item.branch?.branchName,
      city: item.city?.nameAr,
      product: item.product,
      media_url: item.product?.media?.[0]?.mediaUrl ?? null,
    };
  }

  async search(query: ListingQueryDto) {
    const page = query.page ?? 1;
    const limit = Math.min(query.limit ?? 20, 50);
    const where = this.buildWhere(query, true);
    const [items, total] = await Promise.all([
      this.db.listing.findMany({
        where,
        include: { product: { include: { category: true, partBrand: true, media: true, compatibilities: true } }, organization: true, branch: true, city: true },
        orderBy: this.effectivePriceOrder(),
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.db.listing.count({ where }),
    ]);
    return { success: true, data: { items: items.map((item: any) => this.mapListing(item)), meta: { page, limit, total } } };
  }

  async details(id: number) {
    const data = await this.db.listing.findUnique({
      where: { id },
      include: {
        product: { include: { category: true, partBrand: true, media: true, specs: true, compatibilities: { include: { make: true, model: true, variant: true } } } },
        organization: true,
        branch: true,
        city: true,
        inventory: true,
        prices: { where: { isActive: true }, orderBy: { createdAt: 'desc' } },
      },
    });
    if (!data || data.status !== 'ACTIVE') {
      throw new NotFoundException({ message: 'Listing not found', error_code: 'LISTING_NOT_FOUND' });
    }
    return { success: true, data: this.mapListing(data) };
  }

  async compare(productId: number, query: ListingQueryDto) {
    const where = this.buildWhere({ ...query, productId }, true);
    const items = await this.db.listing.findMany({
      where,
      include: { product: { include: { media: true, partBrand: true } }, organization: true, branch: true, city: true },
      orderBy: this.effectivePriceOrder(),
      take: 20,
    });
    return { success: true, data: items.map((item: any) => this.mapListing(item)) };
  }

  async similar(id: number) {
    const listing = await this.db.listing.findUnique({ where: { id }, include: { product: true } });
    if (!listing) throw new NotFoundException({ message: 'Listing not found', error_code: 'LISTING_NOT_FOUND' });
    const items = await this.db.listing.findMany({
      where: {
        id: { not: id },
        status: 'ACTIVE',
        approvalStatus: 'APPROVED',
        availableQuantity: { gt: 0 },
        product: { categoryId: listing.product.categoryId },
      },
      include: { product: { include: { category: true, partBrand: true, media: true } }, organization: true, branch: true, city: true },
      orderBy: this.effectivePriceOrder(),
      take: 10,
    });
    return { success: true, data: items.map((item: any) => this.mapListing(item)) };
  }
}
