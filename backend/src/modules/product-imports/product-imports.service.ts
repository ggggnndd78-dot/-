import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { EventBusService } from '../../common/events/event-bus.service';
import { PrismaService } from '../../prisma/prisma.service';
import { ProductImportJobsQueryDto, ProductImportRowsQueryDto, UploadProductImportDto } from './dto/product-imports.dto';

const XLSX = require('xlsx');

type ImportError = { fieldName?: string; errorCode: string; message: string; value?: string };
type NormalizedImportRow = {
  product_name: string;
  part_number: string;
  category: string;
  brand: string;
  vehicle_brand?: string;
  vehicle_model?: string;
  year_from?: number;
  year_to?: number;
  condition_type: string;
  quality_type: string;
  price_yer: number;
  stock_quantity: number;
  city: string;
  branch: string;
  description?: string;
  categoryId?: number;
  partBrandId?: number;
  cityId?: number;
  makeId?: number;
  modelId?: number;
};

const REQUIRED_COLUMNS = [
  'product_name',
  'part_number',
  'category',
  'brand',
  'vehicle_brand',
  'vehicle_model',
  'year_from',
  'year_to',
  'condition_type',
  'quality_type',
  'price_yer',
  'stock_quantity',
  'city',
  'branch',
  'description',
];

const HEADER_ALIASES: Record<string, string> = {
  product_name: 'product_name',
  product: 'product_name',
  name: 'product_name',
  item_name: 'product_name',
  part_number: 'part_number',
  partnumber: 'part_number',
  part_no: 'part_number',
  sku: 'part_number',
  oem: 'part_number',
  oem_number: 'part_number',
  category: 'category',
  brand: 'brand',
  part_brand: 'brand',
  vehicle_brand: 'vehicle_brand',
  make: 'vehicle_brand',
  car_brand: 'vehicle_brand',
  vehicle_model: 'vehicle_model',
  model: 'vehicle_model',
  car_model: 'vehicle_model',
  year_from: 'year_from',
  from_year: 'year_from',
  year_to: 'year_to',
  to_year: 'year_to',
  condition_type: 'condition_type',
  condition: 'condition_type',
  quality_type: 'quality_type',
  quality: 'quality_type',
  price_yer: 'price_yer',
  price: 'price_yer',
  stock_quantity: 'stock_quantity',
  quantity: 'stock_quantity',
  stock: 'stock_quantity',
  city: 'city',
  branch: 'branch',
  description: 'description',
};

@Injectable()
export class ProductImportsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly events: EventBusService,
  ) {}

  private get db() { return this.prisma as any; }

  async downloadTemplateBuffer() {
    const example = {
      product_name: 'فلتر زيت تويوتا كورولا',
      part_number: '04152-YZZA6',
      category: 'فلاتر',
      brand: 'تويوتا أصلي',
      vehicle_brand: 'تويوتا',
      vehicle_model: 'كورولا',
      year_from: 2014,
      year_to: 2022,
      condition_type: 'NEW',
      quality_type: 'ORIGINAL',
      price_yer: 7500,
      stock_quantity: 10,
      city: 'صنعاء',
      branch: 'Main Branch',
      description: 'فلتر زيت أصلي مناسب للموديلات المحددة',
    };
    const worksheet = XLSX.utils.json_to_sheet([example], { header: REQUIRED_COLUMNS });
    XLSX.utils.sheet_add_aoa(worksheet, [REQUIRED_COLUMNS], { origin: 'A1' });
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'products');
    return XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
  }

  async listJobs(userId: number, query: ProductImportJobsQueryDto) {
    const organizationIds = await this.visibleOrganizationIds(userId);
    const where: any = {
      organizationId: query.organizationId ? query.organizationId : { in: organizationIds },
      ...(query.status ? { status: query.status } : {}),
    };
    if (query.organizationId && !organizationIds.includes(query.organizationId) && !(await this.isSuperAdmin(userId))) {
      throw new ForbiddenException({ message: 'ليس لديك صلاحية على هذه المؤسسة', error_code: 'ORGANIZATION_ACCESS_DENIED' });
    }
    const data = await this.db.productImportJob.findMany({
      where,
      include: { organization: true, branch: true, uploadedBy: true },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return { success: true, data };
  }

  async getJob(userId: number, publicId: string) {
    const job = await this.db.productImportJob.findUnique({
      where: { publicId },
      include: { organization: true, branch: true, uploadedBy: true, errors: { take: 100, orderBy: { id: 'asc' } } },
    });
    if (!job) throw new NotFoundException({ message: 'Import job not found', error_code: 'IMPORT_JOB_NOT_FOUND' });
    await this.assertCanAccessOrganization(userId, job.organizationId);
    return { success: true, data: job };
  }

  async getRows(userId: number, publicId: string, query: ProductImportRowsQueryDto) {
    const job = await this.db.productImportJob.findUnique({ where: { publicId } });
    if (!job) throw new NotFoundException({ message: 'Import job not found', error_code: 'IMPORT_JOB_NOT_FOUND' });
    await this.assertCanAccessOrganization(userId, job.organizationId);
    const rows = await this.db.productImportRow.findMany({
      where: { jobId: job.id, ...(query.status ? { status: query.status } : {}) },
      include: { errors: true, product: true, listing: true },
      orderBy: { rowNumber: 'asc' },
      take: 500,
    });
    return { success: true, data: rows };
  }

  async getErrors(userId: number, publicId: string) {
    const job = await this.db.productImportJob.findUnique({ where: { publicId } });
    if (!job) throw new NotFoundException({ message: 'Import job not found', error_code: 'IMPORT_JOB_NOT_FOUND' });
    await this.assertCanAccessOrganization(userId, job.organizationId);
    const errors = await this.db.productImportError.findMany({
      where: { jobId: job.id },
      include: { row: true },
      orderBy: [{ rowId: 'asc' }, { id: 'asc' }],
      take: 1000,
    });
    return { success: true, data: errors };
  }

  async upload(userId: number, dto: UploadProductImportDto, file: any) {
    if (!file?.buffer) {
      throw new BadRequestException({ message: 'ملف Excel مطلوب', error_code: 'IMPORT_FILE_REQUIRED' });
    }
    const organizationId = await this.resolveOrganizationId(userId, dto);
    const { organization, branch } = await this.assertCanImport(userId, organizationId, Number(dto.branchId));
    this.assertSupportedFile(file.originalname);

    const workbookRows = this.readWorkbook(file.buffer);
    const headerResult = this.validateHeaders(workbookRows.headers);
    if (headerResult.missing.length) {
      throw new BadRequestException({
        message: 'ملف الاستيراد ناقص أعمدة مطلوبة',
        error_code: 'IMPORT_REQUIRED_COLUMNS_MISSING',
        missing_columns: headerResult.missing,
      });
    }

    const job = await this.db.productImportJob.create({
      data: {
        organizationId,
        branchId: branch.id,
        uploadedByUserId: userId,
        fileName: file.filename ?? file.originalname,
        originalFileName: file.originalname,
        fileMimeType: file.mimetype,
        fileSizeBytes: file.size,
        status: 'UPLOADED',
      },
    });

    await this.events.publish({
      name: 'ProductImportUploaded',
      aggregateType: 'ProductImportJob',
      aggregateId: job.publicId,
      actorUserId: userId,
      payload: { organization_id: organizationId, branch_id: branch.id, file_name: file.originalname },
    });

    const parsed = await this.parseAndValidateRows(job.id, organization, branch, workbookRows.rows);
    const status = parsed.invalidRows > 0
      ? (parsed.validRows > 0 ? 'READY_TO_CONFIRM' : 'VALIDATION_FAILED')
      : 'READY_TO_CONFIRM';

    const updatedJob = await this.db.productImportJob.update({
      where: { id: job.id },
      data: {
        status,
        totalRows: parsed.totalRows,
        validRows: parsed.validRows,
        invalidRows: parsed.invalidRows,
        parsedAt: new Date(),
      },
      include: { organization: true, branch: true, errors: { take: 100, orderBy: { id: 'asc' } } },
    });

    await this.events.publish({
      name: parsed.invalidRows > 0 ? 'ProductImportValidationFailed' : 'ProductImportParsed',
      aggregateType: 'ProductImportJob',
      aggregateId: updatedJob.publicId,
      actorUserId: userId,
      payload: { total_rows: parsed.totalRows, valid_rows: parsed.validRows, invalid_rows: parsed.invalidRows },
    });

    return { success: true, message: 'تم رفع الملف وقراءة الصفوف', data: updatedJob };
  }

  async confirm(userId: number, publicId: string) {
    const job = await this.db.productImportJob.findUnique({
      where: { publicId },
      include: { organization: true, branch: true },
    });
    if (!job) throw new NotFoundException({ message: 'Import job not found', error_code: 'IMPORT_JOB_NOT_FOUND' });
    await this.assertCanImport(userId, job.organizationId, job.branchId);
    if (!['READY_TO_CONFIRM', 'VALIDATION_FAILED'].includes(job.status)) {
      throw new BadRequestException({ message: 'لا يمكن تأكيد هذا الاستيراد في حالته الحالية', error_code: 'IMPORT_JOB_NOT_CONFIRMABLE' });
    }

    const rows = await this.db.productImportRow.findMany({ where: { jobId: job.id, status: 'VALID' }, orderBy: { rowNumber: 'asc' } });
    if (!rows.length) {
      throw new BadRequestException({ message: 'لا توجد صفوف صحيحة للاستيراد', error_code: 'IMPORT_NO_VALID_ROWS' });
    }

    let imported = 0;
    let skipped = 0;
    const now = new Date();

    for (const row of rows) {
      const data = row.normalizedData as NormalizedImportRow;
      try {
        await this.db.$transaction(async (tx: any) => {
          const slug = await this.uniqueProductSlug(tx, `${data.product_name}-${data.part_number}`);
          let product = await tx.catalogProduct.findFirst({
            where: { OR: [{ sku: data.part_number }, { oemNumber: data.part_number }, { aftermarketCode: data.part_number }] },
          });

          if (!product) {
            product = await tx.catalogProduct.create({
              data: {
                categoryId: data.categoryId,
                partBrandId: data.partBrandId,
                nameAr: data.product_name,
                nameEn: data.product_name,
                slug,
                sku: data.part_number,
                oemNumber: data.part_number,
                description: data.description ?? null,
                isUniversal: !data.makeId,
                isActive: true,
              },
            });
          }

          if (data.makeId) {
            const existingCompatibility = await tx.productCompatibility.findFirst({
              where: {
                productId: product.id,
                makeId: data.makeId,
                modelId: data.modelId ?? null,
                yearFrom: data.year_from ?? null,
                yearTo: data.year_to ?? null,
              },
            });
            if (!existingCompatibility) {
              await tx.productCompatibility.create({
                data: {
                  productId: product.id,
                  makeId: data.makeId,
                  modelId: data.modelId ?? null,
                  yearFrom: data.year_from ?? null,
                  yearTo: data.year_to ?? null,
                },
              });
            }
          }

          const listing = await tx.listing.create({
            data: {
              productId: product.id,
              organizationId: job.organizationId,
              branchId: job.branchId,
              cityId: data.cityId,
              createdByUserId: userId,
              title: data.product_name,
              description: data.description ?? null,
              condition: data.condition_type,
              qualityType: data.quality_type,
              status: 'ACTIVE',
              approvalStatus: 'APPROVED',
              unitPrice: data.price_yer,
              currency: 'YER',
              availableQuantity: data.stock_quantity,
              reservedQuantity: 0,
              supportsPickup: true,
              supportsDelivery: false,
              publishedAt: now,
            },
          });

          await tx.listingInventory.create({ data: { listingId: listing.id, availableQuantity: data.stock_quantity, reservedQuantity: 0 } });
          await tx.listingPrice.create({ data: { listingId: listing.id, unitPrice: data.price_yer, currency: 'YER', isActive: true } });
          await tx.stockMovement.create({
            data: {
              listingId: listing.id,
              movementType: 'IMPORT_INITIAL_STOCK',
              quantity: data.stock_quantity,
              quantityBefore: 0,
              quantityAfter: data.stock_quantity,
              reason: `Product import ${job.publicId}`,
              referenceType: 'PRODUCT_IMPORT_JOB',
              referenceId: job.publicId,
              createdByUserId: userId,
            },
          });
          await tx.productImportRow.update({ where: { id: row.id }, data: { status: 'IMPORTED', productId: product.id, listingId: listing.id } });
        });
        imported++;
      } catch (error: any) {
        skipped++;
        await this.db.productImportRow.update({ where: { id: row.id }, data: { status: 'SKIPPED', errorSummary: error?.message ?? 'Import failed' } });
        await this.db.productImportError.create({ data: { jobId: job.id, rowId: row.id, errorCode: 'IMPORT_ROW_FAILED', message: error?.message?.slice(0, 500) ?? 'Row import failed' } });
      }
    }

    const finalStatus = skipped > 0 || job.invalidRows > 0 ? 'PARTIALLY_COMPLETED' : 'COMPLETED';
    const updated = await this.db.productImportJob.update({
      where: { id: job.id },
      data: { status: finalStatus, importedRows: imported, skippedRows: skipped, confirmedAt: now, completedAt: new Date() },
      include: { organization: true, branch: true },
    });

    await this.events.publish({
      name: finalStatus === 'COMPLETED' ? 'ProductImportCompleted' : 'ProductImportPartiallyCompleted',
      aggregateType: 'ProductImportJob',
      aggregateId: updated.publicId,
      actorUserId: userId,
      payload: { imported_rows: imported, skipped_rows: skipped, invalid_rows: job.invalidRows },
    });

    return { success: true, message: 'تم تأكيد الاستيراد وحفظ المنتجات الصحيحة', data: updated };
  }

  private readWorkbook(buffer: Buffer) {
    const workbook = XLSX.read(buffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0];
    if (!sheetName) throw new BadRequestException({ message: 'ملف Excel فارغ', error_code: 'IMPORT_EMPTY_WORKBOOK' });
    const sheet = workbook.Sheets[sheetName];
    const rows = XLSX.utils.sheet_to_json(sheet, { defval: '', raw: false }) as Record<string, any>[];
    if (!rows.length) throw new BadRequestException({ message: 'لا توجد صفوف منتجات داخل الملف', error_code: 'IMPORT_NO_ROWS' });
    const headers = Object.keys(rows[0] ?? {});
    return { headers, rows };
  }

  private assertSupportedFile(fileName: string) {
    const lower = (fileName ?? '').toLowerCase();
    if (!lower.endsWith('.xlsx') && !lower.endsWith('.xls') && !lower.endsWith('.csv')) {
      throw new BadRequestException({ message: 'صيغة الملف غير مدعومة. استخدم xlsx أو xls أو csv', error_code: 'IMPORT_UNSUPPORTED_FILE' });
    }
  }

  private validateHeaders(headers: string[]) {
    const normalized = new Set(headers.map((h) => this.mapHeader(h)).filter(Boolean));
    const missing = REQUIRED_COLUMNS.filter((column) => !normalized.has(column));
    return { missing };
  }

  private async parseAndValidateRows(jobId: number, organization: any, branch: any, rawRows: Record<string, any>[]) {
    const duplicatePartNumbers = new Set<string>();
    let validRows = 0;
    let invalidRows = 0;

    for (let index = 0; index < rawRows.length; index++) {
      const raw = rawRows[index];
      const rowNumber = index + 2;
      const normalizedRaw = this.normalizeRawRow(raw);
      const { data, errors } = await this.validateRow(normalizedRaw, organization, branch, duplicatePartNumbers);
      const status = errors.length ? 'INVALID' : 'VALID';
      const row = await this.db.productImportRow.create({
        data: {
          jobId,
          rowNumber,
          status,
          rawData: raw,
          normalizedData: data ?? null,
          errorSummary: errors.map((e) => e.message).join(' | ') || null,
        },
      });

      for (const error of errors) {
        await this.db.productImportError.create({
          data: {
            jobId,
            rowId: row.id,
            fieldName: error.fieldName ?? null,
            errorCode: error.errorCode,
            message: error.message,
            value: error.value ?? null,
          },
        });
      }

      if (errors.length) invalidRows++; else validRows++;
    }
    return { totalRows: rawRows.length, validRows, invalidRows };
  }

  private normalizeRawRow(raw: Record<string, any>) {
    const row: Record<string, string> = {};
    for (const [key, value] of Object.entries(raw)) {
      const mapped = this.mapHeader(key);
      if (!mapped) continue;
      row[mapped] = this.clean(value);
    }
    return row;
  }

  private mapHeader(header: string) {
    const key = this.clean(header).toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
    return HEADER_ALIASES[key] ?? key;
  }

  private clean(value: any) {
    return String(value ?? '').trim();
  }

  private async validateRow(raw: Record<string, string>, organization: any, branch: any, duplicatePartNumbers: Set<string>) {
    const errors: ImportError[] = [];
    const required = ['product_name', 'part_number', 'category', 'brand', 'price_yer', 'stock_quantity', 'city', 'branch'];
    for (const field of required) {
      if (!raw[field]) errors.push({ fieldName: field, errorCode: 'REQUIRED_FIELD', message: `الحقل ${field} مطلوب` });
    }

    const price = Number(raw.price_yer);
    if (!Number.isFinite(price) || price <= 0) errors.push({ fieldName: 'price_yer', errorCode: 'INVALID_PRICE', message: 'السعر يجب أن يكون رقمًا أكبر من صفر', value: raw.price_yer });
    const stock = Number(raw.stock_quantity);
    if (!Number.isInteger(stock) || stock < 0) errors.push({ fieldName: 'stock_quantity', errorCode: 'INVALID_STOCK', message: 'الكمية يجب أن تكون رقمًا صحيحًا صفر أو أكبر', value: raw.stock_quantity });

    const partNumber = raw.part_number?.toUpperCase();
    if (partNumber && duplicatePartNumbers.has(partNumber)) {
      errors.push({ fieldName: 'part_number', errorCode: 'DUPLICATE_IN_FILE', message: 'رقم القطعة مكرر داخل الملف', value: partNumber });
    }
    if (partNumber) duplicatePartNumbers.add(partNumber);

    const [category, brand, city] = await Promise.all([
      raw.category ? this.findCategory(raw.category) : null,
      raw.brand ? this.findPartBrand(raw.brand) : null,
      raw.city ? this.findCity(raw.city) : null,
    ]);
    if (raw.category && !category) errors.push({ fieldName: 'category', errorCode: 'CATEGORY_NOT_FOUND', message: 'التصنيف غير موجود في النظام', value: raw.category });
    if (raw.brand && !brand) errors.push({ fieldName: 'brand', errorCode: 'BRAND_NOT_FOUND', message: 'شركة القطعة غير موجودة في النظام', value: raw.brand });
    if (raw.city && !city) errors.push({ fieldName: 'city', errorCode: 'CITY_NOT_FOUND', message: 'المدينة غير موجودة في النظام', value: raw.city });

    if (raw.branch && !this.matchesBranch(raw.branch, branch)) {
      errors.push({ fieldName: 'branch', errorCode: 'BRANCH_NOT_MATCHED', message: 'الفرع لا يطابق الفرع المحدد أو لا يتبع المؤسسة', value: raw.branch });
    }

    let make: any = null;
    let model: any = null;
    if (raw.vehicle_brand || raw.vehicle_model) {
      make = raw.vehicle_brand ? await this.findVehicleMake(raw.vehicle_brand) : null;
      if (!make) errors.push({ fieldName: 'vehicle_brand', errorCode: 'VEHICLE_MAKE_NOT_FOUND', message: 'ماركة السيارة غير موجودة', value: raw.vehicle_brand });
      model = make && raw.vehicle_model ? await this.findVehicleModel(make.id, raw.vehicle_model) : null;
      if (raw.vehicle_model && !model) errors.push({ fieldName: 'vehicle_model', errorCode: 'VEHICLE_MODEL_NOT_FOUND', message: 'موديل السيارة غير موجود أو لا يتبع الماركة', value: raw.vehicle_model });
    }

    const yearFrom = raw.year_from ? Number(raw.year_from) : undefined;
    const yearTo = raw.year_to ? Number(raw.year_to) : undefined;
    const hasYearFrom = yearFrom !== undefined;
    const hasYearTo = yearTo !== undefined;
    if (hasYearFrom && (!Number.isInteger(yearFrom) || yearFrom < 1950 || yearFrom > 2100)) {
      errors.push({ fieldName: 'year_from', errorCode: 'INVALID_YEAR', message: 'سنة البداية غير صحيحة', value: raw.year_from });
    }
    if (hasYearTo && (!Number.isInteger(yearTo) || yearTo < 1950 || yearTo > 2100)) {
      errors.push({ fieldName: 'year_to', errorCode: 'INVALID_YEAR', message: 'سنة النهاية غير صحيحة', value: raw.year_to });
    }
    if (hasYearFrom && hasYearTo && yearFrom > yearTo) {
      errors.push({ fieldName: 'year_to', errorCode: 'INVALID_YEAR_RANGE', message: 'سنة البداية لا يمكن أن تكون أكبر من سنة النهاية' });
    }

    const existingListing = partNumber ? await this.db.listing.findFirst({
      where: {
        organizationId: organization.id,
        product: { OR: [{ sku: partNumber }, { oemNumber: partNumber }, { aftermarketCode: partNumber }] },
      },
    }) : null;
    if (existingListing) {
      errors.push({ fieldName: 'part_number', errorCode: 'DUPLICATE_PART_FOR_ORGANIZATION', message: 'رقم القطعة موجود مسبقًا لنفس المؤسسة', value: partNumber });
    }

    const condition = this.mapCondition(raw.condition_type);
    if (!condition) errors.push({ fieldName: 'condition_type', errorCode: 'INVALID_CONDITION', message: 'نوع الحالة يجب أن يكون NEW أو USED أو REFURBISHED', value: raw.condition_type });
    const quality = this.mapQuality(raw.quality_type);
    if (!quality) errors.push({ fieldName: 'quality_type', errorCode: 'INVALID_QUALITY', message: 'نوع الجودة يجب أن يكون ORIGINAL/OEM أو AFTERMARKET أو USED', value: raw.quality_type });

    const data: NormalizedImportRow | null = errors.length ? null : {
      product_name: raw.product_name,
      part_number: partNumber,
      category: raw.category,
      brand: raw.brand,
      vehicle_brand: raw.vehicle_brand || undefined,
      vehicle_model: raw.vehicle_model || undefined,
      year_from: yearFrom,
      year_to: yearTo,
      condition_type: condition!,
      quality_type: quality!,
      price_yer: price,
      stock_quantity: stock,
      city: raw.city,
      branch: branch.branchName,
      description: raw.description || undefined,
      categoryId: category.id,
      partBrandId: brand.id,
      cityId: city.id,
      makeId: make?.id,
      modelId: model?.id,
    };
    return { data, errors };
  }

  private async resolveOrganizationId(userId: number, dto: UploadProductImportDto) {
    if (dto.organizationId) return Number(dto.organizationId);
    if (dto.organizationPublicId) {
      const org = await this.db.organization.findUnique({ where: { publicId: dto.organizationPublicId } });
      if (!org) throw new NotFoundException({ message: 'Organization not found', error_code: 'ORGANIZATION_NOT_FOUND' });
      return org.id;
    }
    const organizationIds = await this.visibleOrganizationIds(userId);
    const branch = await this.db.organizationBranch.findFirst({
      where: {
        id: Number(dto.branchId),
        organizationId: { in: organizationIds },
      },
      select: { organizationId: true },
    });
    if (branch) return branch.organizationId;
    throw new BadRequestException({ message: 'organizationId أو organizationPublicId مطلوب', error_code: 'ORGANIZATION_REQUIRED' });
  }

  private async assertCanImport(userId: number, organizationId: number, branchId: number) {
    const organization = await this.db.organization.findUnique({ where: { id: organizationId } });
    if (!organization) throw new NotFoundException({ message: 'Organization not found', error_code: 'ORGANIZATION_NOT_FOUND' });
    if (!['MERCHANT', 'WORKSHOP', 'WAREHOUSE'].includes(organization.organizationType)) {
      throw new BadRequestException({ message: 'هذا النوع من الحسابات لا يستخدم استيراد المنتجات', error_code: 'IMPORT_ORGANIZATION_TYPE_NOT_ALLOWED' });
    }
    if (organization.status !== 'APPROVED' || !organization.isVerified) {
      throw new ForbiddenException({ message: 'لا يمكن الاستيراد قبل اعتماد الحساب', error_code: 'ORGANIZATION_NOT_APPROVED' });
    }

    await this.assertCanAccessOrganization(userId, organizationId);
    const permissions = await this.userPermissionCodes(userId, organizationId);
    const requiredAny = ['merchant.products.manage', 'merchant.inventory.manage', 'warehouse.inventory.manage', 'product_imports.manage'];
    if (!(await this.isSuperAdmin(userId)) && !requiredAny.some((permission) => permissions.has(permission))) {
      throw new ForbiddenException({ message: 'لا تملك صلاحية استيراد المنتجات', error_code: 'IMPORT_PERMISSION_DENIED' });
    }

    const branch = await this.db.organizationBranch.findFirst({ where: { id: branchId, organizationId } });
    if (!branch) throw new BadRequestException({ message: 'الفرع غير محدد أو لا يتبع هذه المؤسسة', error_code: 'IMPORT_BRANCH_REQUIRED' });
    return { organization, branch };
  }

  private async assertCanAccessOrganization(userId: number, organizationId: number) {
    if (await this.isSuperAdmin(userId)) return;
    const member = await this.db.organizationMember.findFirst({ where: { userId, organizationId, status: 'ACTIVE' } });
    if (!member) throw new ForbiddenException({ message: 'ليس لديك صلاحية على هذه المؤسسة', error_code: 'ORGANIZATION_ACCESS_DENIED' });
  }

  private async visibleOrganizationIds(userId: number) {
    if (await this.isSuperAdmin(userId)) {
      const orgs = await this.db.organization.findMany({ select: { id: true } });
      return orgs.map((org: any) => org.id);
    }
    const memberships = await this.db.organizationMember.findMany({ where: { userId, status: 'ACTIVE' }, select: { organizationId: true } });
    return memberships.map((m: any) => m.organizationId);
  }

  private async isSuperAdmin(userId: number) {
    const role = await this.db.userRole.findFirst({ where: { userId, role: { code: 'admin_super' } } });
    return Boolean(role);
  }

  private async userPermissionCodes(userId: number, organizationId: number) {
    const codes = new Set<string>();
    const roles = await this.db.userRole.findMany({ where: { userId }, include: { role: { include: { rolePermissions: { include: { permission: true } } } } } });
    for (const role of roles) for (const rp of role.role.rolePermissions) codes.add(rp.permission.code);
    const member = await this.db.organizationMember.findFirst({ where: { userId, organizationId }, include: { permissions: true } });
    for (const permission of member?.permissions ?? []) codes.add(permission.permissionCode);
    return codes;
  }

  private matchesBranch(value: string, branch: any) {
    const input = this.normalizeText(value);
    return input === String(branch.id) || input === this.normalizeText(branch.publicId) || input === this.normalizeText(branch.branchName);
  }

  private async findCategory(value: string) {
    const v = this.normalizeText(value);
    return this.db.catalogCategory.findFirst({ where: { OR: [{ nameAr: { equals: value } }, { nameEn: { equals: value } }, { slug: v }] } });
  }

  private async findPartBrand(value: string) {
    const v = this.normalizeText(value);
    return this.db.partBrand.findFirst({ where: { OR: [{ nameAr: { equals: value } }, { nameEn: { equals: value } }, { slug: v }] } });
  }

  private async findCity(value: string) {
    const v = this.normalizeText(value);
    return this.db.city.findFirst({ where: { OR: [{ nameAr: { equals: value } }, { nameEn: { equals: value } }, { code: v }] } });
  }

  private async findVehicleMake(value: string) {
    const v = this.normalizeText(value);
    return this.db.vehicleMake.findFirst({ where: { OR: [{ nameAr: { equals: value } }, { nameEn: { equals: value } }, { slug: v }] } });
  }

  private async findVehicleModel(makeId: number, value: string) {
    const v = this.normalizeText(value);
    return this.db.vehicleModel.findFirst({ where: { makeId, OR: [{ nameAr: { equals: value } }, { nameEn: { equals: value } }, { slug: v }] } });
  }

  private normalizeText(value: string) {
    return String(value ?? '').trim().toLowerCase().replace(/\s+/g, '-');
  }

  private mapCondition(value: string) {
    const v = this.clean(value).toUpperCase();
    if (['NEW', 'جديد'].includes(v)) return 'NEW';
    if (['USED', 'مستعمل'].includes(v)) return 'USED';
    if (['REFURBISHED', 'مجدد'].includes(v)) return 'REFURBISHED';
    return null;
  }

  private mapQuality(value: string) {
    const v = this.clean(value).toUpperCase();
    if (['ORIGINAL', 'OEM', 'GENUINE', 'أصلي'].includes(v)) return 'ORIGINAL';
    if (['AFTERMARKET', 'بديل', 'تجاري'].includes(v)) return 'AFTERMARKET';
    if (['USED', 'مستعمل'].includes(v)) return 'USED';
    return null;
  }

  private async uniqueProductSlug(tx: any, base: string) {
    const normalized = this.normalizeText(base).replace(/[^a-z0-9\-\u0600-\u06FF]/g, '').slice(0, 180) || `product-${Date.now()}`;
    let slug = normalized;
    let counter = 1;
    while (await tx.catalogProduct.findUnique({ where: { slug } })) {
      counter++;
      slug = `${normalized}-${counter}`.slice(0, 240);
    }
    return slug;
  }
}
