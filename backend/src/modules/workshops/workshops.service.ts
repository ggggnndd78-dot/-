import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import {
  BookingSlotsQueryDto,
  CancelWorkshopBookingDto,
  CreateBookingSlotDto,
  CreateDiagnosticReportDto,
  CreateMaintenanceRecordDto,
  CreateServiceOrderFromBookingDto,
  CreateWorkshopBookingDto,
  CreateWorkshopServiceDto,
  CreateWorkshopTechnicianDto,
  SubmitWorkshopRatingDto,
  UpdateServiceOrderStatusDto,
  UpdateWorkshopBookingStatusDto,
  UpdateWorkshopServiceDto,
  UpdateWorkshopServiceStatusDto,
  WorkshopServicesQueryDto,
} from './dto/workshops.dto';

const TERMINAL_BOOKING_STATUSES = ['COMPLETED', 'CANCELLED', 'REJECTED'];
const TERMINAL_SERVICE_ORDER_STATUSES = ['COMPLETED', 'CANCELLED'];

const WORKSHOP_BOOKING_TRANSITIONS: Record<string, string[]> = {
  REQUESTED: ['CONFIRMED', 'REJECTED', 'CANCELLED'],
  CONFIRMED: ['IN_PROGRESS', 'CANCELLED', 'REJECTED'],
  IN_PROGRESS: ['COMPLETED', 'CANCELLED'],
};

const SERVICE_ORDER_TRANSITIONS: Record<string, string[]> = {
  OPEN: ['DIAGNOSIS_IN_PROGRESS', 'WAITING_CUSTOMER_APPROVAL', 'IN_REPAIR', 'CANCELLED'],
  DIAGNOSIS_IN_PROGRESS: ['WAITING_CUSTOMER_APPROVAL', 'WAITING_PARTS', 'IN_REPAIR', 'CANCELLED'],
  WAITING_CUSTOMER_APPROVAL: ['WAITING_PARTS', 'IN_REPAIR', 'CANCELLED'],
  WAITING_PARTS: ['IN_REPAIR', 'CANCELLED'],
  IN_REPAIR: ['READY_FOR_DELIVERY', 'CANCELLED'],
  READY_FOR_DELIVERY: ['COMPLETED', 'CANCELLED'],
};

@Injectable()
export class WorkshopsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}
  private get db() { return this.prisma as any; }

  private async auditSafe(input: { actorUserId?: number; action: string; entityType?: string; entityId?: string | number; metadata?: Record<string, unknown> }) {
    try {
      await this.audit.write({
        actorUserId: input.actorUserId,
        action: input.action,
        entityType: input.entityType,
        entityId: input.entityId,
        metadata: input.metadata,
      });
    } catch {
      // Audit must never break the user workflow.
    }
  }

  private async assertCustomer(userId: number) {
    const role = await this.prisma.userRole.findFirst({
      where: { userId, role: { is: { code: 'customer' } } },
      select: { id: true },
    });
    if (!role) {
      throw new ForbiddenException({ message: 'العملاء فقط يمكنهم حجز خدمات الورش', error_code: 'CUSTOMER_ONLY' });
    }
  }

  private parseSlotDateTime(date: string, time: string) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      throw new BadRequestException({ message: 'صيغة التاريخ يجب أن تكون YYYY-MM-DD', error_code: 'INVALID_SLOT_DATE' });
    }
    if (!/^\d{2}:\d{2}$/.test(time)) {
      throw new BadRequestException({ message: 'صيغة الوقت يجب أن تكون HH:mm', error_code: 'INVALID_SLOT_TIME' });
    }
    const value = new Date(`${date}T${time}:00.000Z`);
    if (Number.isNaN(value.getTime())) {
      throw new BadRequestException({ message: 'وقت الموعد غير صالح', error_code: 'INVALID_SLOT_TIME' });
    }
    return value;
  }

  private slotDateOnly(date: string) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      throw new BadRequestException({ message: 'صيغة التاريخ يجب أن تكون YYYY-MM-DD', error_code: 'INVALID_SLOT_DATE' });
    }
    return new Date(`${date}T00:00:00.000Z`);
  }

  private async releaseBookingSlot(tx: any, bookingSlotId?: number | null) {
    if (!bookingSlotId) return;
    const slot = await tx.bookingSlot.findUnique({ where: { id: bookingSlotId } });
    if (!slot) return;
    const nextBookedCount = Math.max(Number(slot.bookedCount ?? 0) - 1, 0);
    await tx.bookingSlot.update({
      where: { id: bookingSlotId },
      data: {
        bookedCount: nextBookedCount,
        status: slot.status === 'CLOSED' ? 'CLOSED' : 'AVAILABLE',
      },
    });
  }

  private mapDecimal(value: any) {
    if (value === null || value === undefined) return null;
    return Number(value);
  }

  private mapService(service: any) {
    return {
      id: service.id,
      public_id: service.publicId,
      organization_id: service.organizationId,
      organization_name: service.organization?.displayName,
      branch_id: service.branchId,
      branch_name: service.branch?.branchName,
      city_id: service.cityId,
      city_name: service.city?.nameAr,
      service_id: service.serviceId,
      service_catalog_name_ar: service.service?.nameAr,
      service_catalog_name_en: service.service?.nameEn,
      name_ar: service.nameAr,
      name_en: service.nameEn,
      category_code: service.categoryCode,
      description: service.description,
      estimated_duration_minutes: service.estimatedDurationMinutes,
      base_price: this.mapDecimal(service.basePrice),
      currency: service.currency,
      requires_diagnosis: service.requiresDiagnosis,
      supports_mobile_service: service.supportsMobileService,
      status: service.status,
    };
  }

  private includeServiceDetails() {
    return { organization: true, branch: true, city: true, service: { include: { category: true } } };
  }

  private async resolveOrganizationId(dto: { organizationId?: number; organizationPublicId?: string }) {
    let organizationId = dto.organizationId;
    if (dto.organizationPublicId) {
      const org = await this.prisma.organization.findUnique({ where: { publicId: dto.organizationPublicId } });
      if (!org) throw new NotFoundException({ message: 'Organization not found', error_code: 'ORGANIZATION_NOT_FOUND' });
      organizationId = org.id;
    }
    if (!organizationId) throw new BadRequestException({ message: 'organizationId or organizationPublicId is required', error_code: 'ORGANIZATION_REQUIRED' });
    return organizationId;
  }

  private async assertWorkshopMembership(userId: number, organizationId: number, branchId?: number | null) {
    const member = await this.prisma.organizationMember.findFirst({
      where: { userId, organizationId, status: 'ACTIVE' },
      include: { organization: true, branchAccess: true },
    });
    if (!member) throw new ForbiddenException({ message: 'ليس لديك صلاحية على هذه الورشة', error_code: 'WORKSHOP_ACCESS_DENIED' });
    if (member.organization.organizationType !== 'WORKSHOP') {
      throw new BadRequestException({ message: 'هذه المؤسسة ليست ورشة', error_code: 'ORGANIZATION_NOT_WORKSHOP' });
    }
    if (branchId && !member.allBranches && !member.branchAccess.some((entry: any) => entry.branchId === branchId)) {
      throw new ForbiddenException({ message: 'ليس لديك صلاحية على هذا الفرع', error_code: 'BRANCH_ACCESS_DENIED' });
    }
    return member;
  }

  private async assertApprovedWorkshop(organizationId: number) {
    const organization = await this.prisma.organization.findUnique({ where: { id: organizationId } });
    if (!organization) throw new NotFoundException({ message: 'Organization not found', error_code: 'ORGANIZATION_NOT_FOUND' });
    if (organization.organizationType !== 'WORKSHOP') {
      throw new BadRequestException({ message: 'هذه المؤسسة ليست ورشة', error_code: 'ORGANIZATION_NOT_WORKSHOP' });
    }
    if (organization.status !== 'APPROVED') {
      throw new BadRequestException({ message: 'لا يمكن تشغيل خدمات الورشة قبل اعتمادها', error_code: 'WORKSHOP_NOT_APPROVED' });
    }
    return organization;
  }

  private async assertBranchBelongsToWorkshop(branchId: number | undefined, organizationId: number) {
    if (!branchId) return null;
    const branch = await this.prisma.organizationBranch.findFirst({ where: { id: branchId, organizationId } });
    if (!branch) throw new BadRequestException({ message: 'الفرع لا يتبع هذه الورشة', error_code: 'BRANCH_ACCESS_DENIED' });
    if (!branch.isActive || branch.temporarilyClosed) throw new BadRequestException({ message: 'هذا الفرع غير متاح حاليًا', error_code: 'BRANCH_NOT_AVAILABLE' });
    return branch;
  }


  async serviceCategories() {
    const data = await this.db.serviceCategory.findMany({
      where: { status: 'ACTIVE' },
      include: { services: { where: { status: 'ACTIVE' }, orderBy: { sortOrder: 'asc' } } },
      orderBy: [{ sortOrder: 'asc' }, { nameAr: 'asc' }],
    });
    return { success: true, data };
  }

  async serviceCatalog(query: WorkshopServicesQueryDto) {
    const where: any = { status: 'ACTIVE' };
    if (query.cityId) where.OR = [{ cityId: Number(query.cityId) }, { cityId: null }];
    if (query.categoryCode) where.category = { code: query.categoryCode };
    if (query.q) {
      where.AND = [
        ...(where.AND ?? []),
        { OR: [{ nameAr: { contains: query.q } }, { nameEn: { contains: query.q } }, { description: { contains: query.q } }] },
      ];
    }
    const data = await this.db.serviceCatalog.findMany({
      where,
      include: { category: true },
      orderBy: [{ sortOrder: 'asc' }, { nameAr: 'asc' }],
    });
    return { success: true, data };
  }

  async bookingSlots(query: BookingSlotsQueryDto) {
    const slotDate = this.slotDateOnly(query.date);
    const service = await this.db.workshopService.findFirst({
      where: { id: query.workshopServiceId, status: 'ACTIVE', organization: { status: 'APPROVED' } },
      include: { branch: true },
    });
    if (!service) throw new NotFoundException({ message: 'Workshop service not found', error_code: 'WORKSHOP_SERVICE_NOT_FOUND' });
    const branchId = query.branchId ?? service.branchId;
    if (!branchId) throw new BadRequestException({ message: 'يجب تحديد الفرع لهذه الخدمة', error_code: 'BRANCH_REQUIRED' });
    const data = await this.db.bookingSlot.findMany({
      where: {
        workshopServiceId: service.id,
        branchId,
        slotDate,
        status: { in: ['AVAILABLE', 'FULL'] },
      },
      include: { technician: true, branch: true },
      orderBy: { startAt: 'asc' },
    });
    return { success: true, data };
  }

  async createBookingSlot(userId: number, dto: CreateBookingSlotDto) {
    const service = await this.db.workshopService.findFirst({ where: { id: dto.workshopServiceId }, include: { organization: true, branch: true } });
    if (!service) throw new NotFoundException({ message: 'Workshop service not found', error_code: 'WORKSHOP_SERVICE_NOT_FOUND' });
    await this.assertWorkshopMembership(userId, service.organizationId, dto.branchId ?? service.branchId);
    await this.assertApprovedWorkshop(service.organizationId);
    const branchId = dto.branchId ?? service.branchId;
    if (!branchId) throw new BadRequestException({ message: 'يجب تحديد الفرع لهذا الموعد', error_code: 'BRANCH_REQUIRED' });
    await this.assertBranchBelongsToWorkshop(branchId, service.organizationId);
    if (dto.technicianId) {
      const technician = await this.db.workshopTechnician.findFirst({ where: { id: dto.technicianId, organizationId: service.organizationId, status: 'ACTIVE' } });
      if (!technician) throw new BadRequestException({ message: 'الفني غير متاح أو لا يتبع الورشة', error_code: 'TECHNICIAN_NOT_AVAILABLE' });
    }
    const startAt = this.parseSlotDateTime(dto.date, dto.startTime);
    const endAt = this.parseSlotDateTime(dto.date, dto.endTime);
    if (endAt <= startAt) throw new BadRequestException({ message: 'وقت نهاية الموعد يجب أن يكون بعد وقت البداية', error_code: 'INVALID_SLOT_RANGE' });
    if (startAt < new Date()) throw new BadRequestException({ message: 'لا يمكن إنشاء موعد في الماضي', error_code: 'PAST_SLOT_NOT_ALLOWED' });
    const slotDate = this.slotDateOnly(dto.date);

    const data = await this.db.$transaction(async (tx: any) => {
      await tx.workshopBranch.upsert({
        where: { organizationBranchId: branchId },
        update: { isBookingEnabled: true },
        create: { organizationId: service.organizationId, organizationBranchId: branchId, isBookingEnabled: true, defaultSlotCapacity: dto.capacity ?? 1, slotDurationMinutes: Math.max(15, Math.round((endAt.getTime() - startAt.getTime()) / 60000)) },
      });
      const existing = await tx.bookingSlot.findFirst({ where: { workshopServiceId: service.id, branchId, startAt } });
      if (existing) {
        return tx.bookingSlot.update({
          where: { id: existing.id },
          data: { endAt, technicianId: dto.technicianId ?? existing.technicianId, capacity: dto.capacity ?? existing.capacity, status: dto.status ?? existing.status },
          include: { workshopService: true, branch: true, technician: true },
        });
      }
      return tx.bookingSlot.create({
        data: {
          organizationId: service.organizationId,
          branchId,
          workshopServiceId: service.id,
          technicianId: dto.technicianId ?? null,
          slotDate,
          startAt,
          endAt,
          capacity: dto.capacity ?? 1,
          bookedCount: 0,
          status: dto.status ?? 'AVAILABLE',
        },
        include: { workshopService: true, branch: true, technician: true },
      });
    });
    await this.auditSafe({ actorUserId: userId, action: 'workshop.booking_slot.upserted', entityType: 'BookingSlot', entityId: data.id, metadata: { workshopServiceId: service.id, branchId } });
    return { success: true, message: 'Booking slot saved', data };
  }

  async myWorkshopBookingSlots(userId: number, query?: Partial<BookingSlotsQueryDto>) {
    const memberships = await this.prisma.organizationMember.findMany({ where: { userId, status: 'ACTIVE' }, select: { organizationId: true } });
    const organizationIds = memberships.map((item: any) => item.organizationId);
    const where: any = { organizationId: { in: organizationIds } };
    if (query?.workshopServiceId) where.workshopServiceId = Number(query.workshopServiceId);
    if (query?.branchId) where.branchId = Number(query.branchId);
    if (query?.date) where.slotDate = this.slotDateOnly(query.date);
    const data = await this.db.bookingSlot.findMany({
      where,
      include: { workshopService: true, branch: true, technician: true },
      orderBy: [{ slotDate: 'desc' }, { startAt: 'asc' }],
      take: 100,
    });
    return { success: true, data };
  }

  async searchServices(query: WorkshopServicesQueryDto) {
    const where: any = {
      status: 'ACTIVE',
      organization: { organizationType: 'WORKSHOP', status: 'APPROVED' },
    };
    if (query.cityId) where.cityId = Number(query.cityId);
    if (query.categoryCode) where.categoryCode = query.categoryCode;
    if (query.q) {
      where.OR = [
        { nameAr: { contains: query.q } },
        { nameEn: { contains: query.q } },
        { description: { contains: query.q } },
      ];
    }

    const data = await this.db.workshopService.findMany({
      where,
      include: this.includeServiceDetails(),
      orderBy: [{ categoryCode: 'asc' }, { createdAt: 'desc' }],
    });
    return { success: true, data: data.map((item: any) => this.mapService(item)) };
  }

  async serviceDetails(id: number) {
    const service = await this.db.workshopService.findFirst({
      where: { id, status: 'ACTIVE', organization: { status: 'APPROVED' } },
      include: { organization: { include: { workshopProfile: true } }, branch: { include: { businessHours: true, city: true, district: true, area: true } }, city: true },
    });
    if (!service) throw new NotFoundException({ message: 'Workshop service not found', error_code: 'WORKSHOP_SERVICE_NOT_FOUND' });
    return { success: true, data: this.mapService(service) };
  }

  async createService(userId: number, dto: CreateWorkshopServiceDto) {
    const organizationId = await this.resolveOrganizationId(dto);
    await this.assertWorkshopMembership(userId, organizationId, dto.branchId);
    await this.assertApprovedWorkshop(organizationId);
    const branch = await this.assertBranchBelongsToWorkshop(dto.branchId, organizationId);
    let catalog: any = null;
    if (dto.serviceId) {
      catalog = await this.db.serviceCatalog.findFirst({ where: { id: dto.serviceId, status: 'ACTIVE' }, include: { category: true } });
      if (!catalog) throw new BadRequestException({ message: 'الخدمة الأساسية غير موجودة أو غير مفعلة', error_code: 'SERVICE_CATALOG_NOT_FOUND' });
    }

    const data = await this.db.workshopService.create({
      data: {
        organizationId,
        branchId: dto.branchId ?? null,
        cityId: branch?.cityId ?? null,
        serviceId: dto.serviceId ?? null,
        createdByUserId: userId,
        nameAr: dto.nameAr || catalog?.nameAr,
        nameEn: dto.nameEn ?? catalog?.nameEn ?? null,
        categoryCode: dto.categoryCode ?? catalog?.category?.code ?? 'general',
        description: dto.description ?? catalog?.description ?? null,
        estimatedDurationMinutes: dto.estimatedDurationMinutes ?? catalog?.estimatedDurationMinutes ?? null,
        basePrice: dto.basePrice ?? catalog?.basePrice ?? null,
        currency: dto.currency ?? catalog?.currency ?? 'YER',
        requiresDiagnosis: dto.requiresDiagnosis ?? false,
        supportsMobileService: dto.supportsMobileService ?? false,
        status: 'ACTIVE',
      },
      include: this.includeServiceDetails(),
    });
    await this.auditSafe({ actorUserId: userId, action: 'workshop.service.created', entityType: 'WorkshopService', entityId: data.id, metadata: { organizationId, branchId: dto.branchId ?? null } });
    return { success: true, message: 'Workshop service created', data: this.mapService(data) };
  }

  async updateService(userId: number, id: number, dto: UpdateWorkshopServiceDto) {
    const service = await this.db.workshopService.findUnique({ where: { id } });
    if (!service) throw new NotFoundException({ message: 'Workshop service not found', error_code: 'WORKSHOP_SERVICE_NOT_FOUND' });
    await this.assertWorkshopMembership(userId, service.organizationId, service.branchId);
    if (dto.serviceId) {
      const catalog = await this.db.serviceCatalog.findFirst({ where: { id: dto.serviceId, status: 'ACTIVE' } });
      if (!catalog) throw new BadRequestException({ message: 'الخدمة الأساسية غير موجودة أو غير مفعلة', error_code: 'SERVICE_CATALOG_NOT_FOUND' });
    }

    const data = await this.db.workshopService.update({
      where: { id },
      data: {
        ...(dto.nameAr !== undefined ? { nameAr: dto.nameAr } : {}),
        ...(dto.nameEn !== undefined ? { nameEn: dto.nameEn } : {}),
        ...(dto.serviceId !== undefined ? { serviceId: dto.serviceId } : {}),
        ...(dto.categoryCode !== undefined ? { categoryCode: dto.categoryCode } : {}),
        ...(dto.description !== undefined ? { description: dto.description } : {}),
        ...(dto.estimatedDurationMinutes !== undefined ? { estimatedDurationMinutes: dto.estimatedDurationMinutes } : {}),
        ...(dto.basePrice !== undefined ? { basePrice: dto.basePrice } : {}),
        ...(dto.requiresDiagnosis !== undefined ? { requiresDiagnosis: dto.requiresDiagnosis } : {}),
        ...(dto.supportsMobileService !== undefined ? { supportsMobileService: dto.supportsMobileService } : {}),
      },
      include: this.includeServiceDetails(),
    });
    await this.auditSafe({ actorUserId: userId, action: 'workshop.service.updated', entityType: 'WorkshopService', entityId: id, metadata: { organizationId: service.organizationId } });
    return { success: true, message: 'Workshop service updated', data: this.mapService(data) };
  }

  async updateServiceStatus(userId: number, id: number, dto: UpdateWorkshopServiceStatusDto) {
    const service = await this.db.workshopService.findUnique({ where: { id } });
    if (!service) throw new NotFoundException({ message: 'Workshop service not found', error_code: 'WORKSHOP_SERVICE_NOT_FOUND' });
    await this.assertWorkshopMembership(userId, service.organizationId, service.branchId);
    const data = await this.db.workshopService.update({ where: { id }, data: { status: dto.status }, include: this.includeServiceDetails() });
    await this.auditSafe({ actorUserId: userId, action: 'workshop.service.status_updated', entityType: 'WorkshopService', entityId: id, metadata: { status: dto.status } });
    return { success: true, message: 'Workshop service status updated', data: this.mapService(data) };
  }

  async myWorkshopServices(userId: number) {
    const memberships = await this.prisma.organizationMember.findMany({ where: { userId }, select: { organizationId: true } });
    const organizationIds = memberships.map((item: any) => item.organizationId);
    const data = await this.db.workshopService.findMany({
      where: { organizationId: { in: organizationIds } },
      include: this.includeServiceDetails(),
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data: data.map((item: any) => this.mapService(item)) };
  }

  async createTechnician(userId: number, dto: CreateWorkshopTechnicianDto) {
    const organizationId = await this.resolveOrganizationId(dto);
    await this.assertWorkshopMembership(userId, organizationId, dto.branchId);
    await this.assertApprovedWorkshop(organizationId);
    await this.assertBranchBelongsToWorkshop(dto.branchId, organizationId);

    const data = await this.db.workshopTechnician.create({
      data: {
        organizationId,
        branchId: dto.branchId ?? null,
        userId: dto.userId ?? null,
        fullName: dto.fullName,
        phone: dto.phone ?? null,
        specializations: dto.specializations ?? [],
        maxJobsPerDay: dto.maxJobsPerDay ?? null,
        status: 'ACTIVE',
      },
      include: { branch: true, user: true },
    });
    await this.auditSafe({ actorUserId: userId, action: 'workshop.technician.created', entityType: 'WorkshopTechnician', entityId: data.id, metadata: { organizationId, branchId: dto.branchId ?? null } });
    return { success: true, message: 'Technician created', data };
  }

  async myTechnicians(userId: number) {
    const memberships = await this.prisma.organizationMember.findMany({ where: { userId }, select: { organizationId: true } });
    const organizationIds = memberships.map((item: any) => item.organizationId);
    const data = await this.db.workshopTechnician.findMany({
      where: { organizationId: { in: organizationIds } },
      include: { branch: true, user: true },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data };
  }

  async createBooking(userId: number, dto: CreateWorkshopBookingDto) {
    await this.assertCustomer(userId);
    const service = await this.db.workshopService.findFirst({
      where: { id: dto.workshopServiceId, status: 'ACTIVE' },
      include: { organization: true, branch: true },
    });
    if (!service) throw new NotFoundException({ message: 'Workshop service not found', error_code: 'WORKSHOP_SERVICE_NOT_FOUND' });
    if (service.organization.status !== 'APPROVED') {
      throw new BadRequestException({ message: 'الورشة غير متاحة للحجز حاليًا', error_code: 'WORKSHOP_NOT_APPROVED' });
    }
    if (!service.branchId && !dto.bookingSlotId) {
      throw new BadRequestException({ message: 'يجب اختيار فرع أو موعد محدد قبل تأكيد الحجز', error_code: 'BRANCH_OR_SLOT_REQUIRED' });
    }
    if (dto.customerVehicleId) {
      const vehicle = await this.db.customerVehicle.findFirst({ where: { id: dto.customerVehicleId, userId } });
      if (!vehicle) throw new BadRequestException({ message: 'المركبة لا تتبع حسابك', error_code: 'VEHICLE_ACCESS_DENIED' });
    }

    let selectedSlot: any = null;
    if (dto.bookingSlotId) {
      selectedSlot = await this.db.bookingSlot.findFirst({
        where: { id: dto.bookingSlotId, workshopServiceId: service.id, status: 'AVAILABLE' },
        include: { branch: true, technician: true },
      });
      if (!selectedSlot) throw new BadRequestException({ message: 'الموعد غير متاح', error_code: 'BOOKING_SLOT_NOT_AVAILABLE' });
      if (selectedSlot.bookedCount >= selectedSlot.capacity) throw new BadRequestException({ message: 'الموعد ممتلئ', error_code: 'BOOKING_SLOT_FULL' });
      if (selectedSlot.startAt < new Date()) throw new BadRequestException({ message: 'لا يمكن حجز موعد سابق', error_code: 'PAST_SLOT_NOT_ALLOWED' });
    }

    const preferredDate = selectedSlot ? selectedSlot.startAt : new Date(dto.preferredDate);
    if (Number.isNaN(preferredDate.getTime())) throw new BadRequestException({ message: 'تاريخ الحجز غير صالح', error_code: 'INVALID_BOOKING_DATE' });
    if (preferredDate < new Date()) throw new BadRequestException({ message: 'لا يمكن حجز موعد في الماضي', error_code: 'PAST_BOOKING_NOT_ALLOWED' });

    const data = await this.db.$transaction(async (tx: any) => {
      let slotForCreate = selectedSlot;
      if (selectedSlot) {
        const updated = await tx.bookingSlot.updateMany({
          where: { id: selectedSlot.id, status: 'AVAILABLE', bookedCount: { lt: selectedSlot.capacity } },
          data: { bookedCount: { increment: 1 } },
        });
        if (updated.count !== 1) throw new BadRequestException({ message: 'الموعد أصبح ممتلئًا', error_code: 'BOOKING_SLOT_FULL' });
        slotForCreate = await tx.bookingSlot.findUnique({ where: { id: selectedSlot.id } });
        if (slotForCreate.bookedCount >= slotForCreate.capacity) {
          await tx.bookingSlot.update({ where: { id: selectedSlot.id }, data: { status: 'FULL' } });
        }
      }
      const branchId = selectedSlot?.branchId ?? service.branchId;
      const booking = await tx.workshopBooking.create({
        data: {
          userId,
          customerVehicleId: dto.customerVehicleId ?? null,
          organizationId: service.organizationId,
          branchId,
          workshopServiceId: service.id,
          cityId: selectedSlot?.branch?.cityId ?? service.cityId,
          technicianId: selectedSlot?.technicianId ?? null,
          bookingSlotId: selectedSlot?.id ?? null,
          status: 'REQUESTED',
          preferredDate,
          preferredTimeWindow: selectedSlot ? `${selectedSlot.startAt.toISOString()} - ${selectedSlot.endAt.toISOString()}` : dto.preferredTimeWindow ?? null,
          customerProblemDescription: dto.customerProblemDescription ?? null,
          customerNote: dto.customerNote ?? null,
          estimatedAmount: service.basePrice,
          currency: service.currency,
          statusHistory: { create: { status: 'REQUESTED', changedByUserId: userId, note: 'Booking requested by customer' } },
        },
        include: { bookingSlot: true, workshopService: true, organization: true, branch: true, customerVehicle: true, statusHistory: true },
      });
      return booking;
    });

    await this.auditSafe({ actorUserId: userId, action: 'workshop.booking.created', entityType: 'WorkshopBooking', entityId: data.id, metadata: { workshopServiceId: service.id, bookingSlotId: dto.bookingSlotId ?? null } });
    return { success: true, message: 'Workshop booking created', data };
  }

  async myBookings(userId: number) {
    const data = await this.db.workshopBooking.findMany({
      where: { userId },
      include: { workshopService: true, organization: true, branch: true, technician: true, serviceOrder: true, statusHistory: { orderBy: { createdAt: 'asc' } } },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data };
  }

  async customerBookingDetails(userId: number, id: number) {
    const data = await this.db.workshopBooking.findFirst({
      where: { id, userId },
      include: { workshopService: true, organization: true, branch: true, technician: true, serviceOrder: { include: { diagnosticReports: true, maintenanceRecords: true, statusHistory: true } }, statusHistory: { orderBy: { createdAt: 'asc' } } },
    });
    if (!data) throw new NotFoundException({ message: 'Booking not found', error_code: 'WORKSHOP_BOOKING_NOT_FOUND' });
    return { success: true, data };
  }

  async cancelBooking(userId: number, id: number, dto: CancelWorkshopBookingDto) {
    const booking = await this.db.workshopBooking.findFirst({ where: { id, userId } });
    if (!booking) throw new NotFoundException({ message: 'Booking not found', error_code: 'WORKSHOP_BOOKING_NOT_FOUND' });
    if (!['REQUESTED', 'CONFIRMED'].includes(booking.status)) {
      throw new BadRequestException({ message: 'لا يمكن إلغاء الحجز في هذه الحالة', error_code: 'BOOKING_CANNOT_BE_CANCELLED' });
    }
    const data = await this.db.$transaction(async (tx: any) => {
      const updated = await tx.workshopBooking.update({
        where: { id },
        data: { status: 'CANCELLED', cancellationReason: dto.reason ?? null, cancelledAt: new Date() },
      });
      await this.releaseBookingSlot(tx, booking.bookingSlotId);
      await tx.workshopBookingStatusHistory.create({ data: { bookingId: id, status: 'CANCELLED', changedByUserId: userId, note: dto.reason ?? 'Cancelled by customer' } });
      return updated;
    });
    await this.auditSafe({ actorUserId: userId, action: 'workshop.booking.cancelled_by_customer', entityType: 'WorkshopBooking', entityId: id, metadata: { reason: dto.reason ?? null } });
    return { success: true, message: 'Workshop booking cancelled', data };
  }

  async workshopBookings(userId: number) {
    const memberships = await this.prisma.organizationMember.findMany({ where: { userId }, select: { organizationId: true } });
    const organizationIds = memberships.map((item: any) => item.organizationId);
    const data = await this.db.workshopBooking.findMany({
      where: { organizationId: { in: organizationIds } },
      include: { user: true, customerVehicle: { include: { make: true, model: true, variant: true } }, workshopService: true, branch: true, technician: true, serviceOrder: true, statusHistory: { orderBy: { createdAt: 'asc' } } },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data };
  }

  private validateBookingTransition(currentStatus: string, nextStatus: string) {
    if (TERMINAL_BOOKING_STATUSES.includes(currentStatus)) {
      throw new BadRequestException({ message: 'لا يمكن تعديل حجز مغلق', error_code: 'BOOKING_ALREADY_CLOSED' });
    }
    const allowed = WORKSHOP_BOOKING_TRANSITIONS[currentStatus] ?? [];
    if (!allowed.includes(nextStatus)) {
      throw new BadRequestException({ message: `انتقال حالة الحجز غير مسموح من ${currentStatus} إلى ${nextStatus}`, error_code: 'INVALID_BOOKING_STATUS_TRANSITION' });
    }
  }

  async updateBookingStatus(userId: number, id: number, dto: UpdateWorkshopBookingStatusDto) {
    const booking = await this.db.workshopBooking.findUnique({ where: { id } });
    if (!booking) throw new NotFoundException({ message: 'Booking not found', error_code: 'WORKSHOP_BOOKING_NOT_FOUND' });
    await this.assertWorkshopMembership(userId, booking.organizationId, booking.branchId);
    this.validateBookingTransition(booking.status, dto.status);
    if (dto.technicianId) {
      const technician = await this.db.workshopTechnician.findFirst({ where: { id: dto.technicianId, organizationId: booking.organizationId, status: 'ACTIVE' } });
      if (!technician) throw new BadRequestException({ message: 'الفني غير متاح أو لا يتبع الورشة', error_code: 'TECHNICIAN_NOT_AVAILABLE' });
    }
    const data = await this.db.$transaction(async (tx: any) => {
      const updated = await tx.workshopBooking.update({
        where: { id },
        data: {
          status: dto.status,
          technicianId: dto.technicianId ?? booking.technicianId,
          estimatedAmount: dto.estimatedAmount ?? booking.estimatedAmount,
          workshopNote: dto.note ?? booking.workshopNote,
          ...(dto.status === 'CANCELLED' || dto.status === 'REJECTED' ? { cancelledAt: new Date(), cancellationReason: dto.note ?? null } : {}),
        },
      });
      if (dto.status === 'CANCELLED' || dto.status === 'REJECTED') {
        await this.releaseBookingSlot(tx, booking.bookingSlotId);
      }
      await tx.workshopBookingStatusHistory.create({ data: { bookingId: id, status: dto.status, changedByUserId: userId, note: dto.note } });
      return updated;
    });
    await this.auditSafe({ actorUserId: userId, action: 'workshop.booking.status_updated', entityType: 'WorkshopBooking', entityId: id, metadata: { from: booking.status, to: dto.status } });
    return { success: true, message: 'Booking status updated', data };
  }

  private makeServiceOrderNumber() {
    const d = new Date();
    const date = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
    return `WS-${date}-${Math.floor(100000 + Math.random() * 900000)}`;
  }

  private async createServiceOrderNumber(tx: any) {
    for (let attempt = 0; attempt < 5; attempt += 1) {
      const serviceOrderNumber = this.makeServiceOrderNumber();
      const exists = await tx.serviceOrder.findUnique({ where: { serviceOrderNumber } });
      if (!exists) return serviceOrderNumber;
    }
    throw new BadRequestException({ message: 'تعذر توليد رقم أمر صيانة فريد', error_code: 'SERVICE_ORDER_NUMBER_GENERATION_FAILED' });
  }

  async createServiceOrderFromBooking(userId: number, bookingId: number, dto: CreateServiceOrderFromBookingDto) {
    const booking = await this.db.workshopBooking.findUnique({ where: { id: bookingId }, include: { serviceOrder: true, workshopService: true } });
    if (!booking) throw new NotFoundException({ message: 'Booking not found', error_code: 'WORKSHOP_BOOKING_NOT_FOUND' });
    await this.assertWorkshopMembership(userId, booking.organizationId, booking.branchId);
    if (booking.serviceOrder) throw new BadRequestException({ message: 'تم إنشاء أمر صيانة لهذا الحجز مسبقًا', error_code: 'SERVICE_ORDER_ALREADY_EXISTS' });
    if (!['REQUESTED', 'CONFIRMED', 'IN_PROGRESS'].includes(booking.status)) {
      throw new BadRequestException({ message: 'لا يمكن إنشاء أمر صيانة لهذا الحجز', error_code: 'BOOKING_NOT_ELIGIBLE_FOR_SERVICE_ORDER' });
    }

    const data = await this.db.$transaction(async (tx: any) => {
      const serviceOrder = await tx.serviceOrder.create({
        data: {
          serviceOrderNumber: await this.createServiceOrderNumber(tx),
          userId: booking.userId,
          customerVehicleId: booking.customerVehicleId,
          organizationId: booking.organizationId,
          branchId: booking.branchId,
          bookingId: booking.id,
          workshopServiceId: booking.workshopServiceId,
          technicianId: dto.technicianId ?? booking.technicianId,
          priority: dto.priority ?? 'NORMAL',
          status: 'OPEN',
          problemDescription: dto.problemDescription ?? booking.customerProblemDescription,
          estimatedAmount: dto.estimatedAmount ?? booking.estimatedAmount,
          currency: booking.currency,
          statusHistory: { create: { status: 'OPEN', changedByUserId: userId, note: 'Service order opened from booking' } },
        },
        include: { booking: true, workshopService: true, technician: true, statusHistory: true },
      });
      if (booking.status !== 'IN_PROGRESS') {
        await tx.workshopBooking.update({ where: { id: booking.id }, data: { status: 'IN_PROGRESS' } });
        await tx.workshopBookingStatusHistory.create({ data: { bookingId: booking.id, status: 'IN_PROGRESS', changedByUserId: userId, note: 'Service order opened' } });
      }
      return serviceOrder;
    });

    await this.auditSafe({ actorUserId: userId, action: 'workshop.service_order.created', entityType: 'ServiceOrder', entityId: data.id, metadata: { bookingId } });
    return { success: true, message: 'Service order created', data };
  }

  async workshopServiceOrders(userId: number) {
    const memberships = await this.prisma.organizationMember.findMany({ where: { userId }, select: { organizationId: true } });
    const organizationIds = memberships.map((item: any) => item.organizationId);
    const data = await this.db.serviceOrder.findMany({
      where: { organizationId: { in: organizationIds } },
      include: { user: true, customerVehicle: { include: { make: true, model: true, variant: true } }, booking: true, workshopService: true, technician: true, diagnosticReports: true, maintenanceRecords: true, statusHistory: { orderBy: { createdAt: 'asc' } } },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data };
  }

  private validateServiceOrderTransition(currentStatus: string, nextStatus: string) {
    if (TERMINAL_SERVICE_ORDER_STATUSES.includes(currentStatus)) {
      throw new BadRequestException({ message: 'لا يمكن تعديل أمر صيانة مغلق', error_code: 'SERVICE_ORDER_ALREADY_CLOSED' });
    }
    const allowed = SERVICE_ORDER_TRANSITIONS[currentStatus] ?? [];
    if (!allowed.includes(nextStatus)) {
      throw new BadRequestException({ message: `انتقال حالة أمر الصيانة غير مسموح من ${currentStatus} إلى ${nextStatus}`, error_code: 'INVALID_SERVICE_ORDER_STATUS_TRANSITION' });
    }
  }

  async updateServiceOrderStatus(userId: number, id: number, dto: UpdateServiceOrderStatusDto) {
    const order = await this.db.serviceOrder.findUnique({ where: { id }, include: { booking: true } });
    if (!order) throw new NotFoundException({ message: 'Service order not found', error_code: 'SERVICE_ORDER_NOT_FOUND' });
    await this.assertWorkshopMembership(userId, order.organizationId, order.branchId);
    this.validateServiceOrderTransition(order.status, dto.status);

    const data = await this.db.$transaction(async (tx: any) => {
      const updated = await tx.serviceOrder.update({
        where: { id },
        data: {
          status: dto.status,
          ...(dto.status === 'DIAGNOSIS_IN_PROGRESS' ? { startedAt: order.startedAt ?? new Date() } : {}),
          ...(dto.status === 'COMPLETED' ? { completedAt: new Date(), finalAmount: dto.finalAmount ?? order.finalAmount } : {}),
        },
      });
      await tx.serviceOrderStatusHistory.create({ data: { serviceOrderId: id, status: dto.status, changedByUserId: userId, note: dto.note } });
      if (dto.status === 'COMPLETED' && order.bookingId) {
        await tx.workshopBooking.update({ where: { id: order.bookingId }, data: { status: 'COMPLETED' } });
        await tx.workshopBookingStatusHistory.create({ data: { bookingId: order.bookingId, status: 'COMPLETED', changedByUserId: userId, note: 'Service order completed' } });
      }
      if (dto.status === 'CANCELLED' && order.bookingId && !TERMINAL_BOOKING_STATUSES.includes(order.booking.status)) {
        await tx.workshopBooking.update({ where: { id: order.bookingId }, data: { status: 'CANCELLED', cancelledAt: new Date(), cancellationReason: dto.note ?? null } });
        await tx.workshopBookingStatusHistory.create({ data: { bookingId: order.bookingId, status: 'CANCELLED', changedByUserId: userId, note: dto.note ?? 'Service order cancelled' } });
      }
      return updated;
    });

    await this.auditSafe({ actorUserId: userId, action: 'workshop.service_order.status_updated', entityType: 'ServiceOrder', entityId: id, metadata: { from: order.status, to: dto.status } });
    return { success: true, message: 'Service order status updated', data };
  }

  async createDiagnosticReport(userId: number, serviceOrderId: number, dto: CreateDiagnosticReportDto) {
    const order = await this.db.serviceOrder.findUnique({ where: { id: serviceOrderId } });
    if (!order) throw new NotFoundException({ message: 'Service order not found', error_code: 'SERVICE_ORDER_NOT_FOUND' });
    await this.assertWorkshopMembership(userId, order.organizationId, order.branchId);
    if (dto.technicianId) {
      const technician = await this.db.workshopTechnician.findFirst({ where: { id: dto.technicianId, organizationId: order.organizationId } });
      if (!technician) throw new BadRequestException({ message: 'الفني لا يتبع الورشة', error_code: 'TECHNICIAN_ACCESS_DENIED' });
    }
    const data = await this.db.$transaction(async (tx: any) => {
      const report = await tx.diagnosticReport.create({
        data: {
          serviceOrderId,
          technicianId: dto.technicianId ?? order.technicianId,
          symptoms: dto.symptoms ?? null,
          findings: dto.findings,
          recommendedActions: dto.recommendedActions ?? null,
          estimatedRepairCost: dto.estimatedRepairCost ?? null,
          requiresParts: dto.requiresParts ?? false,
        },
      });
      await tx.serviceOrder.update({
        where: { id: serviceOrderId },
        data: {
          status: 'DIAGNOSIS_IN_PROGRESS',
          diagnosisSummary: dto.findings,
          estimatedAmount: dto.estimatedRepairCost ?? order.estimatedAmount,
          customerApprovalRequired: dto.estimatedRepairCost !== undefined,
        },
      });
      await tx.serviceOrderStatusHistory.create({ data: { serviceOrderId, status: 'DIAGNOSIS_IN_PROGRESS', changedByUserId: userId, note: 'Diagnostic report added' } });
      return report;
    });
    await this.auditSafe({ actorUserId: userId, action: 'workshop.diagnostic_report.created', entityType: 'DiagnosticReport', entityId: data.id, metadata: { serviceOrderId } });
    return { success: true, message: 'Diagnostic report created', data };
  }

  async createMaintenanceRecord(userId: number, serviceOrderId: number, dto: CreateMaintenanceRecordDto) {
    const order = await this.db.serviceOrder.findUnique({ where: { id: serviceOrderId } });
    if (!order) throw new NotFoundException({ message: 'Service order not found', error_code: 'SERVICE_ORDER_NOT_FOUND' });
    await this.assertWorkshopMembership(userId, order.organizationId, order.branchId);
    const vehicle = await this.db.customerVehicle.findFirst({ where: { id: dto.customerVehicleId, userId: order.userId } });
    if (!vehicle) throw new BadRequestException({ message: 'المركبة لا تتبع العميل', error_code: 'VEHICLE_ACCESS_DENIED' });

    const data = await this.db.maintenanceRecord.create({
      data: {
        userId: order.userId,
        customerVehicleId: dto.customerVehicleId,
        organizationId: order.organizationId,
        serviceOrderId,
        title: dto.title,
        description: dto.description ?? null,
        mileage: dto.mileage ?? null,
        serviceDate: dto.serviceDate ? new Date(dto.serviceDate) : new Date(),
        nextServiceDate: dto.nextServiceDate ? new Date(dto.nextServiceDate) : null,
        costAmount: dto.costAmount ?? order.finalAmount ?? order.approvedAmount ?? order.estimatedAmount,
        currency: order.currency,
      },
    });
    await this.auditSafe({ actorUserId: userId, action: 'workshop.maintenance_record.created', entityType: 'MaintenanceRecord', entityId: data.id, metadata: { serviceOrderId } });
    return { success: true, message: 'Maintenance record created', data };
  }

  async submitRating(userId: number, bookingId: number, dto: SubmitWorkshopRatingDto) {
    const booking = await this.db.workshopBooking.findFirst({
      where: { id: bookingId, userId },
      include: { serviceOrder: true },
    });
    if (!booking) throw new NotFoundException({ message: 'Booking not found', error_code: 'WORKSHOP_BOOKING_NOT_FOUND' });
    if (booking.status !== 'COMPLETED') {
      throw new BadRequestException({ message: 'لا يمكن تقييم الخدمة قبل اكتمالها', error_code: 'BOOKING_NOT_COMPLETED' });
    }
    const existing = await this.db.workshopReview.findFirst({
      where: { userId, organizationId: booking.organizationId, serviceOrderId: booking.serviceOrder?.id ?? null },
    });
    if (existing) throw new BadRequestException({ message: 'تم تقييم هذه الخدمة مسبقًا', error_code: 'WORKSHOP_REVIEW_ALREADY_EXISTS' });
    const data = await this.db.workshopReview.create({
      data: {
        userId,
        organizationId: booking.organizationId,
        serviceOrderId: booking.serviceOrder?.id ?? null,
        rating: Math.min(Math.max(Number(dto.rating), 1), 5),
        title: dto.title ?? null,
        body: dto.body ?? null,
        status: 'PUBLISHED',
      },
    });
    await this.auditSafe({ actorUserId: userId, action: 'workshop.review.created', entityType: 'WorkshopReview', entityId: data.id, metadata: { bookingId, organizationId: booking.organizationId } });
    return { success: true, message: 'Workshop rating submitted', data };
  }

  async myMaintenanceRecords(userId: number) {
    const data = await this.db.maintenanceRecord.findMany({
      where: { userId },
      include: { customerVehicle: { include: { make: true, model: true, variant: true } }, organization: true, serviceOrder: true },
      orderBy: { serviceDate: 'desc' },
    });
    return { success: true, data };
  }
}
