import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { CreateAdminUserDto, ResolveSystemFindingDto, UpdateAdminLocaleDto, UpdateAdminUserDto, UpdateUserStatusDto, UpsertFeatureFlagDto, UpsertSystemSettingDto, UpsertTranslationEntryDto } from './dto/admin.dto';
import { normalizeYemeniMobile } from '../../common/utils/yemen-phone.util';

const TERMINAL_ORDER_STATUSES = ['CANCELLED', 'REFUNDED'];


const ADMIN_CONTROL_MODULES = [
  { code: 'dashboard', titleAr: 'لوحة المؤشرات', titleEn: 'Dashboard', route: '/admin/dashboard', icon: 'dashboard', permission: 'view_admin_panel', group: 'operations' },
  { code: 'analytics', titleAr: 'التحليلات', titleEn: 'Analytics', route: '/admin/analytics', icon: 'analytics', permission: 'view_reports', group: 'analytics' },
  { code: 'users', titleAr: 'المستخدمون', titleEn: 'Users', route: '/admin/users', icon: 'users', permission: 'manage_users', group: 'identity' },
  { code: 'verifications', titleAr: 'طلبات الاعتماد', titleEn: 'Verifications', route: '/admin/verifications', icon: 'verified', permission: 'review_verifications', group: 'identity' },
  { code: 'locations', titleAr: 'المدن ورسوم التوصيل', titleEn: 'Locations & Fees', route: '/admin/locations', icon: 'map', permission: 'manage_location', group: 'operations' },
  { code: 'orders', titleAr: 'الطلبات', titleEn: 'Orders', route: '/admin/orders', icon: 'orders', permission: 'admin.orders.view', group: 'commerce' },
  { code: 'delivery', titleAr: 'الشحن والتوصيل', titleEn: 'Delivery', route: '/admin/delivery', icon: 'local_shipping', permission: 'delivery.shipments.manage', group: 'logistics' },
  { code: 'payment_transactions', titleAr: 'مراجعة المدفوعات', titleEn: 'Payments Review', route: '/finance/review', icon: 'payments', permission: 'finance.payments.review', group: 'finance' },
  { code: 'accounting', titleAr: 'القيود المحاسبية', titleEn: 'Accounting Ledger', route: '/finance/accounting', icon: 'account_balance', permission: 'finance.accounting.manage', group: 'finance' },
  { code: 'quality_release', titleAr: 'الجودة والإصدار', titleEn: 'Quality & Release', route: '/admin/quality-release', icon: 'fact_check', permission: 'release.manage', group: 'operations' },
  { code: 'refunds', titleAr: 'الاستردادات', titleEn: 'Refunds', route: '/finance/refunds', icon: 'undo', permission: 'finance.payments.review', group: 'finance' },
  { code: 'settlements', titleAr: 'التسويات', titleEn: 'Settlements', route: '/finance/settlements', icon: 'receipt_long', permission: 'finance.payments.review', group: 'finance' },
  { code: 'coupons', titleAr: 'الكوبونات', titleEn: 'Coupons', route: '/admin/coupons', icon: 'local_offer', permission: 'coupons.manage', group: 'loyalty' },
  { code: 'support', titleAr: 'مركز الدعم', titleEn: 'Support Center', route: '/support/center', icon: 'support_agent', permission: 'support.tickets.manage', group: 'support' },
  { code: 'reviews', titleAr: 'المراجعات والسمعة', titleEn: 'Reviews & Reputation', route: '/support/reviews', icon: 'star_rate', permission: 'manage_reviews', group: 'trust' },
  { code: 'notifications', titleAr: 'الإشعارات', titleEn: 'Notifications', route: '/customer/notifications', icon: 'notifications', permission: 'manage_notifications', group: 'content' },
  { code: 'audit', titleAr: 'سجل التدقيق', titleEn: 'Audit Logs', route: '/admin/audit-logs', icon: 'history', permission: 'view_audit_logs', group: 'security' },
  { code: 'settings', titleAr: 'إعدادات النظام', titleEn: 'System Settings', route: '/admin/settings', icon: 'settings', permission: 'manage_settings', group: 'system' },
  { code: 'hardening', titleAr: 'تقسية النظام', titleEn: 'System Hardening', route: '/admin/system-hardening', icon: 'security', permission: 'manage_settings', group: 'system' },
];

const ADMIN_ORDER_STATUS_TRANSITIONS: Record<string, string[]> = {
  PENDING: ['CONFIRMED', 'CANCELLED'],
  CONFIRMED: ['PROCESSING', 'CANCELLED'],
  PROCESSING: ['READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'CANCELLED'],
  READY_FOR_PICKUP: ['DELIVERED', 'CANCELLED'],
  OUT_FOR_DELIVERY: ['DELIVERED', 'CANCELLED'],
  DELIVERED: ['RETURN_REQUESTED'],
  RETURN_REQUESTED: ['REFUNDED'],
};

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}


  private async getUserPermissionCodes(userId: number): Promise<Set<string>> {
    const roles = await this.prisma.userRole.findMany({
      where: { userId },
      include: { role: { include: { rolePermissions: { include: { permission: true } } } } },
    });
    const codes = new Set<string>();
    for (const row of roles) {
      for (const rp of row.role.rolePermissions) codes.add(rp.permission.code);
    }
    return codes;
  }

  async controlCenter(actorUserId: number, locale = 'ar') {
    const permissions = await this.getUserPermissionCodes(actorUserId);
    const can = (permission: string) => permissions.has(permission) || permissions.has('manage_system');
    const modules = ADMIN_CONTROL_MODULES
      .filter((module) => can(module.permission))
      .map((module) => ({
        code: module.code,
        title: locale === 'en' ? module.titleEn : module.titleAr,
        titleAr: module.titleAr,
        titleEn: module.titleEn,
        route: module.route,
        icon: module.icon,
        permission: module.permission,
        group: module.group,
      }));

    const [users, organizations, orders, bookings, payments, tickets, reviews, shipments] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.organization.count(),
      (this.prisma as any).order.count().catch(() => 0),
      (this.prisma as any).workshopBooking.count().catch(() => 0),
      (this.prisma as any).paymentTransaction.count().catch(() => 0),
      (this.prisma as any).supportTicket.count().catch(() => 0),
      (this.prisma as any).productReview.count().catch(() => 0),
      (this.prisma as any).shipment.count().catch(() => 0),
    ]);

    return {
      success: true,
      data: {
        locale: locale === 'en' ? 'en' : 'ar',
        direction: locale === 'en' ? 'ltr' : 'rtl',
        modules,
        kpis: [
          { code: 'users', labelAr: 'المستخدمون', labelEn: 'Users', value: users },
          { code: 'organizations', labelAr: 'المؤسسات', labelEn: 'Organizations', value: organizations },
          { code: 'orders', labelAr: 'الطلبات', labelEn: 'Orders', value: orders },
          { code: 'bookings', labelAr: 'الحجوزات', labelEn: 'Bookings', value: bookings },
          { code: 'payments', labelAr: 'عمليات الدفع', labelEn: 'Payments', value: payments },
          { code: 'shipments', labelAr: 'الشحنات', labelEn: 'Shipments', value: shipments },
          { code: 'support', labelAr: 'تذاكر الدعم', labelEn: 'Support Tickets', value: tickets },
          { code: 'reviews', labelAr: 'التقييمات', labelEn: 'Reviews', value: reviews },
        ],
      },
    };
  }

  async enterpriseAnalytics() {
    const [usersByStatus, organizationsByStatus, ordersByStatus, paymentsByStatus, ticketsByStatus, shipmentsByStatus, reviewsByStatus] = await Promise.all([
      this.prisma.user.groupBy({ by: ['status'], _count: { _all: true } }).catch(() => []),
      this.prisma.organization.groupBy({ by: ['status'], _count: { _all: true } }).catch(() => []),
      (this.prisma as any).order.groupBy({ by: ['status'], _count: { _all: true }, _sum: { grandTotal: true } }).catch(() => []),
      (this.prisma as any).paymentTransaction.groupBy({ by: ['status'], _count: { _all: true }, _sum: { amount: true } }).catch(() => []),
      (this.prisma as any).supportTicket.groupBy({ by: ['status'], _count: { _all: true } }).catch(() => []),
      (this.prisma as any).shipment.groupBy({ by: ['status'], _count: { _all: true } }).catch(() => []),
      (this.prisma as any).reviewReputationSummary.findMany({ orderBy: { averageRating: 'desc' }, take: 10 }).catch(() => []),
    ]);
    return { success: true, data: { usersByStatus, organizationsByStatus, ordersByStatus, paymentsByStatus, ticketsByStatus, shipmentsByStatus, topReputation: reviewsByStatus } };
  }

  async localization() {
    const settings = await this.prisma.systemSetting.findMany({
      where: { key: { in: ['platform.default_locale', 'platform.supported_locales', 'platform.rtl_locales', 'platform.date_format', 'platform.currency'] } },
      orderBy: { key: 'asc' },
    });
    return {
      success: true,
      data: {
        supportedLocales: ['ar', 'en'],
        rtlLocales: ['ar'],
        defaultLocale: 'ar',
        settings,
      },
    };
  }

  async updateDefaultLocale(actorUserId: number, dto: UpdateAdminLocaleDto) {
    const setting = await this.prisma.systemSetting.upsert({
      where: { key: 'platform.default_locale' },
      update: { valueText: dto.locale, value: { locale: dto.locale } as any, isPublic: true, updatedByUserId: actorUserId },
      create: { key: 'platform.default_locale', valueText: dto.locale, value: { locale: dto.locale } as any, description: 'Default platform locale', isPublic: true, updatedByUserId: actorUserId },
    });
    await this.audit.write({ actorUserId, action: 'admin.localization.default_locale_updated', entityType: 'system_setting', entityId: setting.key, metadata: { locale: dto.locale } });
    return { success: true, data: setting };
  }

  async featureFlags() {
    const settings = await this.prisma.systemSetting.findMany({ where: { key: { startsWith: 'feature.' } }, orderBy: { key: 'asc' } });
    return { success: true, data: settings };
  }

  async upsertFeatureFlag(actorUserId: number, key: string, dto: UpsertFeatureFlagDto) {
    const normalizedKey = key.startsWith('feature.') ? key : `feature.${key}`;
    const setting = await this.prisma.systemSetting.upsert({
      where: { key: normalizedKey },
      update: { value: { enabled: dto.enabled } as any, valueText: dto.enabled ? 'enabled' : 'disabled', description: dto.description, isPublic: true, updatedByUserId: actorUserId },
      create: { key: normalizedKey, value: { enabled: dto.enabled } as any, valueText: dto.enabled ? 'enabled' : 'disabled', description: dto.description, isPublic: true, updatedByUserId: actorUserId },
    });
    await this.audit.write({ actorUserId, action: 'admin.feature_flag.upserted', entityType: 'system_setting', entityId: normalizedKey, metadata: { enabled: dto.enabled } });
    return { success: true, data: setting };
  }


  async dashboardSummary() {
    const rows = await this.prisma.$queryRawUnsafe<any[]>('SELECT * FROM view_admin_dashboard_summary LIMIT 1');
    return { success: true, data: rows[0] ?? {} };
  }

  async orderMetrics() {
    const rows = await this.prisma.$queryRawUnsafe<any[]>('SELECT * FROM view_order_status_metrics ORDER BY orders_count DESC');
    return { success: true, data: rows };
  }

  async revenueDaily() {
    const rows = await this.prisma.$queryRawUnsafe<any[]>('SELECT * FROM view_revenue_daily ORDER BY revenue_date DESC LIMIT 90');
    return { success: true, data: rows };
  }

  async supportMetrics() {
    const rows = await this.prisma.$queryRawUnsafe<any[]>('SELECT * FROM view_support_status_metrics ORDER BY record_type, records_count DESC');
    return { success: true, data: rows };
  }

  async merchantPerformance() {
    const rows = await this.prisma.$queryRawUnsafe<any[]>('SELECT * FROM view_merchant_performance ORDER BY gross_sales DESC, orders_count DESC LIMIT 50');
    return { success: true, data: rows };
  }

  private normalizeAdminPhone(phone: string) {
    try {
      return normalizeYemeniMobile(phone);
    } catch {
      throw new BadRequestException({ message: 'Invalid Yemen mobile number', error_code: 'YEMEN_PHONE_INVALID' });
    }
  }

  private normalizeRoleCodes(roleCodes?: string[]) {
    return Array.from(new Set((roleCodes ?? [])
      .map((item) => String(item ?? '').trim().toLowerCase())
      .filter(Boolean)));
  }

  private async replaceUserRoles(tx: any, userId: number, roleCodes?: string[]) {
    if (roleCodes === undefined) return;
    const codes = this.normalizeRoleCodes(roleCodes);
    const roles = codes.length
      ? await tx.role.findMany({ where: { code: { in: codes } }, select: { id: true, code: true } })
      : [];
    const foundCodes = new Set(roles.map((role: any) => role.code));
    const missing = codes.filter((code) => !foundCodes.has(code));
    if (missing.length) {
      throw new BadRequestException({ message: `Unknown roles: ${missing.join(', ')}`, error_code: 'ROLE_NOT_FOUND' });
    }
    await tx.userRole.deleteMany({ where: { userId } });
    if (roles.length) {
      await tx.userRole.createMany({
        data: roles.map((role: any) => ({ userId, roleId: role.id })),
        skipDuplicates: true,
      });
    }
  }

  async users(query: { q?: string; take?: number; skip?: number }) {
    const take = Math.min(Math.max(query.take ?? 50, 1), 100);
    const q = query.q?.trim();
    const users = await this.prisma.user.findMany({
      where: q
        ? {
            OR: [
              { displayName: { contains: q } },
              { phoneNormalized: { contains: q } },
              { email: { contains: q } },
            ],
          }
        : undefined,
      select: {
        id: true,
        publicId: true,
        phoneNormalized: true,
        email: true,
        displayName: true,
        status: true,
        locale: true,
        createdAt: true,
        userRoles: { select: { role: { select: { code: true, name: true } } } },
      },
      orderBy: { createdAt: 'desc' },
      take,
      skip: query.skip ?? 0,
    });
    return { success: true, data: users };
  }


  async createUser(actorUserId: number, dto: CreateAdminUserDto) {
    const phone = this.normalizeAdminPhone(dto.phone);
    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ phoneNormalized: phone.local }, { phoneE164: phone.e164 }, ...(dto.email ? [{ email: dto.email.trim().toLowerCase() }] : [])] as any },
      select: { id: true, phoneNormalized: true, email: true },
    });
    if (existing) {
      throw new BadRequestException({ message: 'Phone or email already exists', error_code: 'USER_ALREADY_EXISTS' });
    }

    const user = await this.prisma.$transaction(async (tx) => {
      const created = await tx.user.create({
        data: {
          phoneE164: phone.e164,
          phoneNormalized: phone.local,
          email: dto.email ? dto.email.trim().toLowerCase() : null,
          displayName: dto.displayName?.trim() || phone.local,
          status: (dto.status ?? 'ACTIVE') as any,
          locale: dto.locale ?? 'ar',
          isPhoneVerified: true,
        },
      });
      await this.replaceUserRoles(tx, created.id, dto.roleCodes ?? ['customer']);
      await tx.customerProfile.create({ data: { userId: created.id, displayName: created.displayName } }).catch(() => null);
      return tx.user.findUnique({
        where: { id: created.id },
        select: { id: true, publicId: true, phoneNormalized: true, phoneE164: true, email: true, displayName: true, status: true, locale: true, createdAt: true, userRoles: { select: { role: { select: { code: true, name: true } } } } },
      });
    });

    await this.audit.write({ actorUserId, action: 'admin.user.created', entityType: 'user', entityId: user?.id, metadata: { phone: phone.local, roles: dto.roleCodes ?? ['customer'] } });
    return { success: true, data: user };
  }

  async updateUser(actorUserId: number, userId: number, dto: UpdateAdminUserDto) {
    let phone: ReturnType<typeof normalizeYemeniMobile> | undefined;
    if (dto.phone !== undefined && dto.phone.trim().length > 0) phone = this.normalizeAdminPhone(dto.phone);
    if (actorUserId === userId && dto.status === 'BLOCKED') {
      throw new BadRequestException({ message: 'You cannot block your own account', error_code: 'SELF_BLOCK_FORBIDDEN' });
    }
    const current = await this.prisma.user.findUnique({ where: { id: userId }, select: { id: true } });
    if (!current) throw new NotFoundException({ message: 'User not found', error_code: 'USER_NOT_FOUND' });

    if (phone || dto.email) {
      const duplicated = await this.prisma.user.findFirst({
        where: {
          id: { not: userId },
          OR: [
            ...(phone ? [{ phoneNormalized: phone.local }, { phoneE164: phone.e164 }] : []),
            ...(dto.email ? [{ email: dto.email.trim().toLowerCase() }] : []),
          ] as any,
        },
        select: { id: true },
      });
      if (duplicated) throw new BadRequestException({ message: 'Phone or email already exists', error_code: 'USER_ALREADY_EXISTS' });
    }

    const user = await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: {
          phoneE164: phone?.e164,
          phoneNormalized: phone?.local,
          email: dto.email === undefined ? undefined : (dto.email ? dto.email.trim().toLowerCase() : null),
          displayName: dto.displayName === undefined ? undefined : (dto.displayName?.trim() || null),
          status: dto.status as any,
          locale: dto.locale,
          isPhoneVerified: phone ? true : undefined,
        },
      });
      await this.replaceUserRoles(tx, userId, dto.roleCodes);
      return tx.user.findUnique({
        where: { id: userId },
        select: { id: true, publicId: true, phoneNormalized: true, phoneE164: true, email: true, displayName: true, status: true, locale: true, createdAt: true, userRoles: { select: { role: { select: { code: true, name: true } } } } },
      });
    });

    await this.audit.write({ actorUserId, action: 'admin.user.updated', entityType: 'user', entityId: userId, metadata: { roles: dto.roleCodes } });
    return { success: true, data: user };
  }

  async deleteUser(actorUserId: number, userId: number) {
    if (actorUserId === userId) {
      throw new BadRequestException({ message: 'You cannot delete your own account', error_code: 'SELF_DELETE_FORBIDDEN' });
    }
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { id: true, publicId: true, displayName: true, phoneNormalized: true, email: true } });
    if (!user) throw new NotFoundException({ message: 'User not found', error_code: 'USER_NOT_FOUND' });

    // Enterprise-safe delete: preserve relational history, but revoke access and free unique phone/email for future use.
    const deletedMarker = `deleted_${userId}`;
    const data = await this.prisma.user.update({
      where: { id: userId },
      data: {
        status: 'BLOCKED' as any,
        phoneE164: deletedMarker,
        phoneNormalized: deletedMarker,
        email: user.email ? `${deletedMarker}@deleted.local` : null,
        displayName: user.displayName ? `${user.displayName} (deleted)` : deletedMarker,
        refreshTokens: { updateMany: { where: { revokedAt: null }, data: { revokedAt: new Date() } } },
        trustedDevices: { updateMany: { where: { revokedAt: null }, data: { revokedAt: new Date(), status: 'REVOKED' } } },
        authSessions: { updateMany: { where: { revokedAt: null }, data: { revokedAt: new Date(), status: 'REVOKED' } } },
      },
      select: { id: true, publicId: true, displayName: true, phoneNormalized: true, email: true, status: true },
    });
    await this.audit.write({ actorUserId, action: 'admin.user.archived', entityType: 'user', entityId: userId, metadata: { publicId: user.publicId, old_phone: user.phoneNormalized, safe_delete: true } });
    return { success: true, message: 'User archived and access revoked safely', data };
  }

  async updateUserStatus(actorUserId: number, userId: number, dto: UpdateUserStatusDto) {
    if (actorUserId === userId && dto.status === 'BLOCKED') {
      throw new BadRequestException({ message: 'You cannot block your own account', error_code: 'SELF_BLOCK_FORBIDDEN' });
    }
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { status: dto.status },
      select: { id: true, publicId: true, displayName: true, status: true },
    }).catch(() => null);
    if (!user) throw new NotFoundException({ message: 'User not found', error_code: 'USER_NOT_FOUND' });
    await this.audit.write({ actorUserId, action: 'admin.user.status_updated', entityType: 'user', entityId: userId, metadata: { status: dto.status } });
    return { success: true, data: user };
  }

  async roles() {
    const roles = await this.prisma.role.findMany({
      include: { rolePermissions: { include: { permission: true } } },
      orderBy: { code: 'asc' },
    });
    return { success: true, data: roles };
  }

  async permissions() {
    const permissions = await this.prisma.permission.findMany({ orderBy: [{ moduleCode: 'asc' }, { code: 'asc' }] });
    return { success: true, data: permissions };
  }

  async grantPermission(actorUserId: number, roleId: number, permissionId: number) {
    const grant = await this.prisma.rolePermission.upsert({
      where: { roleId_permissionId: { roleId, permissionId } },
      update: {},
      create: { roleId, permissionId },
    });
    await this.audit.write({ actorUserId, action: 'admin.role.permission_granted', entityType: 'role_permission', entityId: grant.id, metadata: { roleId, permissionId } });
    return { success: true, data: grant };
  }

  async revokePermission(actorUserId: number, roleId: number, permissionId: number) {
    await this.prisma.rolePermission.delete({ where: { roleId_permissionId: { roleId, permissionId } } }).catch(() => null);
    await this.audit.write({ actorUserId, action: 'admin.role.permission_revoked', entityType: 'role_permission', metadata: { roleId, permissionId } });
    return { success: true };
  }

  async settings(publicOnly = false) {
    const data = await this.prisma.systemSetting.findMany({
      where: publicOnly ? { isPublic: true } : undefined,
      orderBy: { key: 'asc' },
    });
    return { success: true, data };
  }

  async upsertSetting(actorUserId: number, key: string, dto: UpsertSystemSettingDto) {
    const setting = await this.prisma.systemSetting.upsert({
      where: { key },
      update: {
        value: dto.value === undefined ? undefined : (dto.value as any),
        valueText: dto.valueText,
        description: dto.description,
        isPublic: dto.isPublic,
        updatedByUserId: actorUserId,
      },
      create: {
        key,
        value: dto.value === undefined ? undefined : (dto.value as any),
        valueText: dto.valueText,
        description: dto.description,
        isPublic: dto.isPublic ?? false,
        updatedByUserId: actorUserId,
      },
    });
    await this.audit.write({ actorUserId, action: 'admin.setting.upserted', entityType: 'system_setting', entityId: key, metadata: { isPublic: setting.isPublic } });
    return { success: true, data: setting };
  }


  async orders(query: { status?: string; take?: number; skip?: number }) {
    const take = Math.min(Math.max(query.take ?? 50, 1), 100);
    const data = await (this.prisma as any).order.findMany({
      where: query.status ? { status: query.status } : undefined,
      include: {
        user: { select: { id: true, displayName: true, phoneNormalized: true, email: true } },
        organization: true,
        branch: true,
        items: true,
        invoices: true,
        fees: true,
        statusHistory: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
      orderBy: { createdAt: 'desc' },
      take,
      skip: query.skip ?? 0,
    });
    return { success: true, data };
  }

  async orderDetails(id: number) {
    const data = await (this.prisma as any).order.findUnique({
      where: { id },
      include: {
        user: { select: { id: true, displayName: true, phoneNormalized: true, email: true } },
        organization: true,
        branch: true,
        items: { include: { listing: { include: { product: true } } } },
        invoices: true,
        fees: true,
        statusHistory: { include: { changedBy: { select: { id: true, displayName: true, phoneNormalized: true } } }, orderBy: { createdAt: 'asc' } },
      },
    });
    if (!data) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
    return { success: true, data };
  }


  private validateOrderTransition(currentStatus: string, nextStatus: string) {
    if (TERMINAL_ORDER_STATUSES.includes(currentStatus)) {
      throw new BadRequestException({ message: 'لا يمكن تعديل طلب مغلق', error_code: 'ORDER_ALREADY_CLOSED' });
    }
    const allowed = ADMIN_ORDER_STATUS_TRANSITIONS[currentStatus] ?? [];
    if (!allowed.includes(nextStatus)) {
      throw new BadRequestException({ message: `انتقال حالة غير مسموح من ${currentStatus} إلى ${nextStatus}`, error_code: 'INVALID_ORDER_STATUS_TRANSITION' });
    }
  }

  private async releaseReservedStock(tx: any, order: any, actorUserId: number) {
    for (const item of order.items) {
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
          reason: 'Order cancelled by admin',
          referenceType: 'ORDER',
          referenceId: String(order.id),
          createdByUserId: actorUserId,
        },
      }).catch(() => null);
    }
  }

  private async commitDeliveredStock(tx: any, order: any, actorUserId: number) {
    for (const item of order.items) {
      const listing = await tx.listing.findUnique({ where: { id: item.listingId } });
      const beforeAvailable = Number(listing?.availableQuantity ?? 0);
      const quantity = Number(item.quantity);
      await tx.listing.update({
        where: { id: item.listingId },
        data: { reservedQuantity: { decrement: quantity }, availableQuantity: { decrement: quantity } },
      });
      await tx.listingInventory.update({
        where: { listingId: item.listingId },
        data: { reservedQuantity: { decrement: quantity }, availableQuantity: { decrement: quantity } },
      }).catch(() => null);
      await tx.stockMovement.create({
        data: {
          listingId: item.listingId,
          movementType: 'ORDER_SOLD',
          quantity: -quantity,
          quantityBefore: beforeAvailable,
          quantityAfter: beforeAvailable - quantity,
          reason: 'Order delivered by admin',
          referenceType: 'ORDER',
          referenceId: String(order.id),
          createdByUserId: actorUserId,
        },
      }).catch(() => null);
    }
  }

  async updateOrderStatus(actorUserId: number, id: number, dto: { status: string; note?: string }) {
    const order = await (this.prisma as any).order.findUnique({ where: { id }, include: { items: true } });
    if (!order) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
    this.validateOrderTransition(order.status, dto.status);

    const data = await (this.prisma as any).$transaction(async (tx: any) => {
      const updatePayload: any = { status: dto.status };
      if (dto.status === 'CANCELLED') updatePayload.cancellationReason = dto.note ?? null;
      const updated = await tx.order.update({ where: { id }, data: updatePayload });
      await tx.orderStatusHistory.create({ data: { orderId: id, status: dto.status, changedByUserId: actorUserId, note: dto.note ?? 'Updated by admin' } });
      if (dto.status === 'DELIVERED') await this.commitDeliveredStock(tx, order, actorUserId);
      if (dto.status === 'CANCELLED') await this.releaseReservedStock(tx, order, actorUserId);
      return updated;
    });

    await this.audit.write({ actorUserId, action: 'admin.order.status_updated', entityType: 'order', entityId: id, metadata: { status: dto.status, note: dto.note ?? null } }).catch(() => null);
    return { success: true, message: 'Order status updated', data };
  }


  private async countModel(modelName: string): Promise<number> {
    const delegate = (this.prisma as any)[modelName];
    if (!delegate?.count) return 0;
    return delegate.count().catch(() => 0);
  }

  private severityRank(severity: string): number {
    const ranks: Record<string, number> = { CRITICAL: 4, HIGH: 3, MEDIUM: 2, LOW: 1 };
    return ranks[severity] ?? 0;
  }

  private async ensureSystemModuleRegistry() {
    const existing = await (this.prisma as any).systemModule.count().catch(() => 0);
    if (existing > 0) return;
    await (this.prisma as any).systemModule.createMany({
      skipDuplicates: true,
      data: ADMIN_CONTROL_MODULES.map((module, index) => ({
        code: module.code,
        nameAr: module.titleAr,
        nameEn: module.titleEn,
        route: module.route,
        icon: module.icon,
        groupCode: module.group,
        permissionCode: module.permission,
        sourceModule: module.code,
        sortOrder: (index + 1) * 10,
      })),
    }).catch(() => null);
  }

  async systemModuleRegistry(actorUserId: number, locale = 'ar') {
    await this.ensureSystemModuleRegistry();
    const permissions = await this.getUserPermissionCodes(actorUserId);
    const can = (permission?: string | null) => !permission || permissions.has(permission) || permissions.has('manage_system');
    const rows = await (this.prisma as any).systemModule.findMany({
      where: { status: 'ACTIVE' },
      orderBy: [{ groupCode: 'asc' }, { sortOrder: 'asc' }],
    }).catch(() => []);
    return {
      success: true,
      data: rows.filter((row: any) => can(row.permissionCode)).map((row: any) => ({
        ...row,
        title: locale === 'en' ? row.nameEn : row.nameAr,
        direction: locale === 'en' ? 'ltr' : 'rtl',
      })),
    };
  }

  async systemAuditOverview() {
    const [tables, modulesCount, translationsCount, snapshotsCount, openFindings, lastAuditLog] = await Promise.all([
      this.prisma.$queryRawUnsafe<any[]>(
        "SELECT TABLE_NAME AS tableName FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME",
      ).catch(() => []),
      (this.prisma as any).systemModule.count().catch(() => 0),
      (this.prisma as any).translationEntry.count().catch(() => 0),
      (this.prisma as any).analyticsMetricSnapshot.count().catch(() => 0),
      (this.prisma as any).systemAuditFinding.findMany({ where: { status: 'OPEN' }, orderBy: [{ severity: 'desc' }, { createdAt: 'desc' }], take: 25 }).catch(() => []),
      this.prisma.auditLog.findFirst({ orderBy: { id: 'desc' } }).catch(() => null),
    ]);

    const tableNames = tables.map((row: any) => String(row.tableName ?? row.TABLE_NAME ?? ''));
    const computedFindings = [] as Array<Record<string, unknown>>;
    const requiredTables = ['users', 'iam_roles', 'iam_permissions', 'organizations', 'orders', 'payment_transactions', 'audit_logs', 'system_settings'];
    const missingRequiredTables = requiredTables.filter((table) => !tableNames.includes(table));
    if (missingRequiredTables.length) {
      computedFindings.push({
        severity: 'CRITICAL',
        category: 'database',
        sourceLayer: 'database',
        reference: 'required_tables',
        description: `Missing required operational tables: ${missingRequiredTables.join(', ')}`,
        rootCause: 'Schema drift or incomplete migration chain.',
        impact: 'Core platform operations may fail.',
        recommendation: 'Run migrations from the latest production-safe ZIP and verify migration history.',
      });
    }
    if (translationsCount === 0) {
      computedFindings.push({
        severity: 'HIGH',
        category: 'i18n',
        sourceLayer: 'backend',
        reference: 'translation_entries',
        description: 'Runtime translation catalog is empty.',
        rootCause: 'Localization depends on hardcoded fallback strings only.',
        impact: 'Admin-editable bilingual content and notification localization will be limited.',
        recommendation: 'Seed translation_entries and migrate screens to translation keys gradually.',
      });
    }
    if (modulesCount === 0) {
      computedFindings.push({
        severity: 'HIGH',
        category: 'admin',
        sourceLayer: 'backend',
        reference: 'system_modules',
        description: 'Unified module registry is empty.',
        rootCause: 'Admin modules are only defined as hardcoded arrays.',
        impact: 'Control Center cannot be configured or audited centrally.',
        recommendation: 'Seed system_modules and use registry-driven navigation.',
      });
    }
    if (snapshotsCount === 0) {
      computedFindings.push({
        severity: 'MEDIUM',
        category: 'analytics',
        sourceLayer: 'backend',
        reference: 'analytics_metric_snapshots',
        description: 'No analytics snapshots exist yet.',
        rootCause: 'Metrics are still calculated live on request.',
        impact: 'Dashboard performance may degrade under high data volume.',
        recommendation: 'Run analytics snapshot refresh and schedule periodic aggregation later.',
      });
    }

    const allFindings = [...computedFindings, ...openFindings];
    const summary = allFindings.reduce((acc: any, finding: any) => {
      acc[finding.severity] = (acc[finding.severity] ?? 0) + 1;
      return acc;
    }, {});

    return {
      success: true,
      data: {
        generatedAt: new Date().toISOString(),
        database: { tableCount: tableNames.length, requiredTables, missingRequiredTables },
        modules: { registered: modulesCount },
        i18n: { translationEntries: translationsCount, supportedLocales: ['ar', 'en'] },
        analytics: { snapshots: snapshotsCount },
        audit: { lastAuditLogId: lastAuditLog?.id ?? null, immutablePolicy: true },
        summary,
        findings: allFindings.sort((a: any, b: any) => this.severityRank(b.severity) - this.severityRank(a.severity)),
      },
    };
  }

  async namingStandardReport() {
    const tables = await this.prisma.$queryRawUnsafe<any[]>(
      "SELECT TABLE_NAME AS tableName FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME",
    ).catch(() => []);
    const tableNames = tables.map((row: any) => String(row.tableName ?? row.TABLE_NAME ?? ''));
    const violations = tableNames
      .map((name) => {
        const issues = [] as string[];
        if (!/^[a-z][a-z0-9_]*$/.test(name)) issues.push('not_snake_case');
        if (name.length > 64) issues.push('too_long');
        if (/(merchant_merchant|workshop_workshop|order_order|payment_payment|delivery_delivery)/.test(name)) issues.push('repeated_context_word');
        return { name, issues };
      })
      .filter((row) => row.issues.length > 0);
    return {
      success: true,
      data: {
        ruleSet: ['snake_case_only', 'short_names', 'no_repeated_context_words', '3nf_first'],
        tableCount: tableNames.length,
        violationCount: violations.length,
        violations,
        compatibilityPolicy: 'Do not rename existing production tables in Phase 22. Add compatibility views or aliases when refactoring is required.',
      },
    };
  }

  async translationCatalog(query: { locale?: string; namespace?: string; q?: string; take?: number; skip?: number }) {
    const take = Math.min(Math.max(query.take ?? 100, 1), 300);
    const whereKey: any = {
      ...(query.namespace ? { namespace: query.namespace } : {}),
      ...(query.q ? { OR: [{ key: { contains: query.q } }, { description: { contains: query.q } }] } : {}),
    };
    const data = await (this.prisma as any).translationKey.findMany({
      where: whereKey,
      include: {
        values: {
          where: query.locale ? { locale: query.locale } : undefined,
          orderBy: [{ locale: 'asc' }, { platform: 'asc' }],
        },
      },
      orderBy: [{ namespace: 'asc' }, { key: 'asc' }],
      take,
      skip: query.skip ?? 0,
    }).catch(async () => {
      return (this.prisma as any).translationEntry.findMany({
        where: {
          locale: query.locale,
          namespace: query.namespace,
          ...(query.q ? { OR: [{ translationKey: { contains: query.q } }, { value: { contains: query.q } }] } : {}),
        },
        orderBy: [{ namespace: 'asc' }, { translationKey: 'asc' }, { locale: 'asc' }],
        take,
        skip: query.skip ?? 0,
      }).catch(() => []);
    });
    return { success: true, data };
  }

  async upsertTranslationEntry(actorUserId: number, key: string, dto: UpsertTranslationEntryDto) {
    const platform = dto.platform ?? 'GLOBAL';
    const status = dto.status ?? 'PUBLISHED';
    const translationKey = await (this.prisma as any).translationKey.upsert({
      where: { key },
      update: { namespace: dto.namespace ?? 'app', status: 'PUBLISHED' },
      create: { key, namespace: dto.namespace ?? 'app', status: 'PUBLISHED', isSystem: false },
    });
    const value = await (this.prisma as any).translationValue.upsert({
      where: { translationKeyId_locale_platform: { translationKeyId: translationKey.id, locale: dto.locale, platform } },
      update: { value: dto.value, status, updatedByUserId: actorUserId, publishedAt: status === 'PUBLISHED' ? new Date() : null },
      create: { translationKeyId: translationKey.id, locale: dto.locale, platform, value: dto.value, status, updatedByUserId: actorUserId, publishedAt: status === 'PUBLISHED' ? new Date() : null },
    });
    const legacyEntry = await (this.prisma as any).translationEntry.upsert({
      where: { translationKey_locale_platform: { translationKey: key, locale: dto.locale, platform } },
      update: { value: dto.value, namespace: dto.namespace ?? 'app', updatedByUserId: actorUserId },
      create: { translationKey: key, locale: dto.locale, value: dto.value, namespace: dto.namespace ?? 'app', platform, updatedByUserId: actorUserId },
    }).catch(() => null);
    await this.audit.write({ actorUserId, action: 'admin.i18n.translation_upserted', entityType: 'translation_value', entityId: value.id, metadata: { key, locale: dto.locale, namespace: dto.namespace ?? 'app', status, legacyEntryId: legacyEntry?.id ?? null } });
    return { success: true, data: { key: translationKey, value } };
  }

  async analyticsSnapshots(query: { group?: string; take?: number; skip?: number }) {
    const take = Math.min(Math.max(query.take ?? 100, 1), 300);
    const data = await (this.prisma as any).analyticsMetricSnapshot.findMany({
      where: query.group ? { metricGroup: query.group } : undefined,
      orderBy: { calculatedAt: 'desc' },
      take,
      skip: query.skip ?? 0,
    }).catch(() => []);
    return { success: true, data };
  }

  async refreshAnalyticsSnapshots(actorUserId: number) {
    const metrics = [
      { key: 'users.total', group: 'identity', labelAr: 'إجمالي المستخدمين', labelEn: 'Total Users', value: await this.countModel('user'), source: 'users' },
      { key: 'organizations.total', group: 'identity', labelAr: 'إجمالي المؤسسات', labelEn: 'Total Organizations', value: await this.countModel('organization'), source: 'organizations' },
      { key: 'orders.total', group: 'commerce', labelAr: 'إجمالي الطلبات', labelEn: 'Total Orders', value: await this.countModel('order'), source: 'orders' },
      { key: 'bookings.total', group: 'workshops', labelAr: 'إجمالي الحجوزات', labelEn: 'Total Bookings', value: await this.countModel('workshopBooking'), source: 'workshops' },
      { key: 'payments.total', group: 'finance', labelAr: 'عمليات الدفع', labelEn: 'Payments', value: await this.countModel('paymentTransaction'), source: 'payments' },
      { key: 'shipments.total', group: 'logistics', labelAr: 'الشحنات', labelEn: 'Shipments', value: await this.countModel('shipment'), source: 'delivery' },
      { key: 'tickets.total', group: 'support', labelAr: 'تذاكر الدعم', labelEn: 'Support Tickets', value: await this.countModel('supportTicket'), source: 'support' },
      { key: 'reviews.total', group: 'trust', labelAr: 'التقييمات', labelEn: 'Reviews', value: (await this.countModel('productReview')) + (await this.countModel('merchantReview')) + (await this.countModel('workshopReview')) + (await this.countModel('serviceReview')), source: 'reviews' },
    ];
    const created = [] as any[];
    for (const metric of metrics) {
      const row = await (this.prisma as any).analyticsMetricSnapshot.create({
        data: {
          metricKey: metric.key,
          metricGroup: metric.group,
          metricLabelAr: metric.labelAr,
          metricLabelEn: metric.labelEn,
          numericValue: String(metric.value),
          sourceModule: metric.source,
        },
      }).catch(() => null);
      if (row) created.push(row);
    }
    await this.audit.write({ actorUserId, action: 'admin.analytics.snapshots_refreshed', entityType: 'analytics_metric_snapshot', metadata: { created: created.length } });
    return { success: true, data: { created: created.length, metrics } };
  }

  async auditIntegrityCheckpoint(actorUserId: number) {
    const logs = await this.prisma.auditLog.findMany({ orderBy: { id: 'asc' }, take: 5000 });
    const source = logs.map((log) => `${log.id}|${log.actorUserId ?? ''}|${log.action}|${log.entityType ?? ''}|${log.entityId ?? ''}|${log.createdAt.toISOString()}`).join('\n');
    const checksum = createHash('sha256').update(source).digest('hex');
    const lastAuditLogId = logs.length ? logs[logs.length - 1].id : null;
    const checkpoint = await (this.prisma as any).auditIntegrityCheckpoint.upsert({
      where: { checkpointKey: 'audit_logs:first_5000' },
      update: { lastAuditLogId, checksum, recordCount: logs.length, metadata: { strategy: 'first_5000_ordered_by_id' } },
      create: { checkpointKey: 'audit_logs:first_5000', lastAuditLogId, checksum, recordCount: logs.length, metadata: { strategy: 'first_5000_ordered_by_id' } },
    }).catch(() => ({ checksum, lastAuditLogId, recordCount: logs.length }));
    await this.audit.write({ actorUserId, action: 'admin.audit.integrity_checkpoint_created', entityType: 'audit_integrity_checkpoint', entityId: (checkpoint as any).id ?? 'audit_logs:first_5000', metadata: { lastAuditLogId, recordCount: logs.length } }).catch(() => null);
    return { success: true, data: checkpoint };
  }

  async resolveSystemFinding(actorUserId: number, id: number, dto: ResolveSystemFindingDto) {
    const finding = await (this.prisma as any).systemAuditFinding.update({
      where: { id },
      data: { status: 'RESOLVED', resolvedByUserId: actorUserId, resolvedAt: new Date(), recommendation: dto.note ?? undefined },
    }).catch(() => null);
    if (!finding) throw new NotFoundException({ message: 'System audit finding not found', error_code: 'SYSTEM_FINDING_NOT_FOUND' });
    await this.audit.write({ actorUserId, action: 'admin.system_audit.finding_resolved', entityType: 'system_audit_finding', entityId: id, metadata: { note: dto.note ?? null } });
    return { success: true, data: finding };
  }


  async auditLogs(query: { take?: number; skip?: number; actorUserId?: number; action?: string }) {
    const data = await this.audit.list(query);
    return { success: true, data };
  }
}
