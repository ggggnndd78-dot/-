import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  AddProductCompatibilityDto,
  AddProductMediaDto,
  CreateCategoryDto,
  CreatePartBrandDto,
  CreateProductDto,
  ProductQueryDto,
} from './dto/catalog.dto';

@Injectable()
export class CatalogService {
  constructor(private readonly prisma: PrismaService) {}

  private get db() { return this.prisma as any; }

  async categories() {
    const data = await this.db.catalogCategory.findMany({
      where: { isActive: true },
      orderBy: [{ sortOrder: 'asc' }, { nameAr: 'asc' }],
      include: { children: true },
    });
    return { success: true, data };
  }

  async createCategory(dto: CreateCategoryDto) {
    const data = await this.db.catalogCategory.create({ data: dto });
    return { success: true, message: 'Category created', data };
  }

  async partBrands() {
    const data = await this.db.partBrand.findMany({ where: { isActive: true }, orderBy: { nameAr: 'asc' } });
    return { success: true, data };
  }

  async createPartBrand(dto: CreatePartBrandDto) {
    const data = await this.db.partBrand.create({ data: dto });
    return { success: true, message: 'Part brand created', data };
  }

  private buildProductWhere(query: ProductQueryDto) {
    const where: any = { isActive: true };
    const text = query.q?.trim();
    const partNumber = query.partNumber?.trim();

    const textFilters: any[] = [];
    if (text) {
      textFilters.push(
        { nameAr: { contains: text } },
        { nameEn: { contains: text } },
        { sku: { contains: text } },
        { oemNumber: { contains: text } },
        { aftermarketCode: { contains: text } },
        { partBrand: { nameAr: { contains: text } } },
        { partBrand: { nameEn: { contains: text } } },
      );
    }
    if (partNumber) {
      textFilters.push(
        { sku: { contains: partNumber } },
        { oemNumber: { contains: partNumber } },
        { aftermarketCode: { contains: partNumber } },
      );
    }
    if (textFilters.length) where.OR = textFilters;

    if (query.categoryId) where.categoryId = query.categoryId;
    if (query.partBrandId) where.partBrandId = query.partBrandId;
    if (query.makeId || query.modelId || query.year) {
      where.AND = [
        ...(where.AND ?? []),
        {
          OR: [
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
          ],
        },
      ];
    }
    return where;
  }

  async products(query: ProductQueryDto) {
    const page = query.page ?? 1;
    const limit = Math.min(query.limit ?? 20, 50);
    const where = this.buildProductWhere(query);

    const [items, total] = await Promise.all([
      this.db.catalogProduct.findMany({
        where,
        include: { category: true, partBrand: true, media: true, specs: true, compatibilities: true },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.db.catalogProduct.count({ where }),
    ]);
    return { success: true, data: { items, meta: { page, limit, total } } };
  }

  async product(id: number) {
    const data = await this.db.catalogProduct.findUnique({
      where: { id },
      include: {
        category: true,
        partBrand: true,
        media: true,
        specs: true,
        compatibilities: { include: { make: true, model: true, variant: true } },
        listings: { where: { status: 'ACTIVE', approvalStatus: 'APPROVED' }, include: { organization: true, branch: true, city: true } },
      },
    });
    if (!data) throw new NotFoundException({ message: 'Product not found', error_code: 'PRODUCT_NOT_FOUND' });
    return { success: true, data };
  }

  async createProduct(dto: CreateProductDto) {
    if (dto.compatibilities?.some((item) => item.yearFrom && item.yearTo && item.yearFrom > item.yearTo)) {
      throw new BadRequestException({ message: 'yearFrom cannot be greater than yearTo', error_code: 'INVALID_COMPATIBILITY_YEAR_RANGE' });
    }

    const data = await this.db.$transaction(async (tx: any) => {
      const { media, compatibilities, specs, ...productData } = dto as any;
      const product = await tx.catalogProduct.create({ data: productData });

      if (media?.length) {
        await tx.productMedia.createMany({ data: media.map((item: any) => ({ ...item, productId: product.id })) });
      }
      if (compatibilities?.length) {
        await tx.productCompatibility.createMany({ data: compatibilities.map((item: any) => ({ ...item, productId: product.id })) });
      }
      if (specs?.length) {
        await tx.productSpec.createMany({ data: specs.map((item: any) => ({ ...item, productId: product.id })) });
      }

      return tx.catalogProduct.findUnique({
        where: { id: product.id },
        include: { category: true, partBrand: true, media: true, specs: true, compatibilities: true },
      });
    });
    return { success: true, message: 'Product created', data };
  }

  async addMedia(productId: number, dto: AddProductMediaDto) {
    const data = await this.db.productMedia.create({ data: { ...dto, productId } });
    return { success: true, message: 'Product media added', data };
  }

  async addCompatibility(productId: number, dto: AddProductCompatibilityDto) {
    if (dto.yearFrom && dto.yearTo && dto.yearFrom > dto.yearTo) {
      throw new BadRequestException({ message: 'yearFrom cannot be greater than yearTo', error_code: 'INVALID_COMPATIBILITY_YEAR_RANGE' });
    }
    const product = await this.db.catalogProduct.findUnique({ where: { id: productId } });
    if (!product) throw new NotFoundException({ message: 'Product not found', error_code: 'PRODUCT_NOT_FOUND' });
    const data = await this.db.productCompatibility.create({ data: { ...dto, productId } });
    return { success: true, message: 'Product compatibility added', data };
  }
}
