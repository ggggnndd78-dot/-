import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService, type JwtSignOptions } from '@nestjs/jwt';
import { createHash, randomBytes, randomInt } from 'crypto';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../../prisma/prisma.service';
import { OtpDeliveryService } from '../communications/otp-delivery.service';
import { EventBusService } from '../../common/events/event-bus.service';
import { I18nService } from '../../common/i18n/i18n.service';
import { normalizeYemeniMobile } from '../../common/utils/yemen-phone.util';
import { CreateGuestSessionDto } from './dto/create-guest-session.dto';
import { GuestSessionLocationDto } from './dto/guest-session-location.dto';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { RegisterBusinessDto, RegisterCustomerDto, VerificationDocumentUploadDto } from './dto/registration.dto';
import { StartPhoneLoginDto, ValidateSessionDto, VerifyTrustedDeviceOtpDto } from './dto/trusted-device.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly jwtService: JwtService,
    private readonly otpDelivery: OtpDeliveryService,
    private readonly eventBus: EventBusService,
    private readonly i18n: I18nService,
  ) {}

  private normalizePhone(phone: string): string {
    try {
      return normalizeYemeniMobile(phone).local;
    } catch {
      throw new BadRequestException({
        message: 'auth.validation.yemeni_phone',
        error_code: 'YEMEN_MOBILE_INVALID',
      });
    }
  }

  private phoneE164(phone: string): string {
    return normalizeYemeniMobile(phone).e164;
  }

  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  private resolveOtpTarget(dto: RequestOtpDto | VerifyOtpDto): {
    targetType: 'phone' | 'email';
    targetValue: string;
    deliveryChannel: 'SMS' | 'EMAIL';
    purpose: 'LOGIN' | 'REGISTER' | 'EMPLOYEE_INVITE' | 'PASSWORD_RESET';
  } {
    if (dto.email?.trim()) {
      return {
        targetType: 'email',
        targetValue: this.normalizeEmail(dto.email),
        deliveryChannel: 'EMAIL',
        purpose: dto.purpose ?? 'LOGIN',
      };
    }

    if (dto.phone?.trim()) {
      const phoneNormalized = this.normalizePhone(dto.phone);
      if (phoneNormalized.length < 9) {
        throw new BadRequestException({
          message: 'validation.phone',
          error_code: 'VALIDATION_ERROR',
        });
      }
      return {
        targetType: 'phone',
        targetValue: phoneNormalized,
        deliveryChannel: 'SMS',
        purpose: dto.purpose ?? 'LOGIN',
      };
    }

    throw new BadRequestException({
      message: 'validation.required',
      error_code: 'OTP_TARGET_REQUIRED',
    });
  }

  private generateOtpCode(): string {
    return String(randomInt(100000, 1000000));
  }

  private maskTarget(targetType: 'phone' | 'email', value: string): string {
    if (targetType === 'email') {
      const [name, domain] = value.split('@');
      return `${name.slice(0, 2)}***@${domain}`;
    }
    return `${value.slice(0, 3)}****${value.slice(-2)}`;
  }

  private get refreshTokenDays(): number {
    return Number(this.config.get('JWT_REFRESH_EXPIRES_IN_DAYS', 30));
  }

  private signAccessToken(user: { id: number; publicId: string; phoneNormalized: string | null; email?: string | null }) {
    const secret = this.config.get<string>('JWT_ACCESS_SECRET')?.trim();
    if (!secret) {
      throw new InternalServerErrorException({
        message: 'JWT access secret is not configured',
        error_code: 'JWT_ACCESS_SECRET_REQUIRED',
      });
    }
    const expiresIn = this.config.get<string>('JWT_ACCESS_EXPIRES_IN', '15m') as JwtSignOptions['expiresIn'];

    return this.jwtService.sign(
      { sub: user.id, publicId: user.publicId, phone: user.phoneNormalized, email: user.email ?? null },
      { secret, expiresIn },
    );
  }


  private async userAuthorization(userId: number) {
    const roles = await this.prisma.userRole.findMany({
      where: { userId },
      include: { role: { include: { rolePermissions: { include: { permission: true } } } } },
    });
    const roleCodes: string[] = roles.map((item) => String(item.role.code));
    const permissionCodes: string[] = Array.from(new Set<string>(
      roles.flatMap((item) => item.role.rolePermissions.map((rp) => String(rp.permission.code))),
    ));
    return { roles: roleCodes, permissions: permissionCodes };
  }

  private async userOrganizations(userId: number) {
    const memberships = await this.prisma.organizationMember.findMany({
      where: { userId },
      include: {
        organization: {
          include: {
            verificationRequests: { orderBy: { createdAt: 'desc' }, take: 1 },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return memberships.map((membership) => ({
      id: membership.organization.publicId,
      display_name: membership.organization.displayName,
      organization_type: membership.organization.organizationType,
      status: membership.organization.status,
      is_verified: membership.organization.isVerified,
      latest_verification_status: membership.organization.verificationRequests[0]?.status ?? null,
    }));
  }

  private async issueRefreshToken(
    userId: number,
    meta: { deviceId?: number | null; sessionId?: number | null; ipAddress?: string | null; userAgent?: string | null } = {},
  ) {
    const plainToken = randomBytes(48).toString('hex');
    const tokenHash = await bcrypt.hash(plainToken, 10);
    const expiresAt = new Date(Date.now() + this.refreshTokenDays * 24 * 60 * 60 * 1000);

    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash,
        expiresAt,
        deviceId: meta.deviceId ?? undefined,
        sessionId: meta.sessionId ?? undefined,
        ipAddress: meta.ipAddress ?? undefined,
        userAgent: meta.userAgent ?? undefined,
      },
    });

    return plainToken;
  }

  private dashboardFor(authz: { roles: string[]; permissions: string[] }, organizations: Array<{ status: string; organization_type: string }>) {
    if (authz.roles.includes('admin_super')) return '/admin/control-center';
    if (authz.roles.includes('admin_operations')) return '/admin/control-center';
    if (authz.roles.includes('finance_manager')) return '/finance/dashboard';
    if (authz.roles.includes('support_agent')) return '/support/operations';
    if (authz.roles.includes('driver')) return '/driver/shipments';
    if (authz.roles.includes('merchant_owner')) return '/merchant/hub';
    if (authz.roles.includes('workshop_owner')) return '/workshop/operations';
    if (authz.roles.includes('warehouse_owner')) return '/warehouse/hub';
    const approvedMerchant = organizations.find((o) => o.organization_type === 'MERCHANT' && o.status === 'APPROVED');
    if (approvedMerchant) return '/merchant/hub';
    const approvedWorkshop = organizations.find((o) => o.organization_type === 'WORKSHOP' && o.status === 'APPROVED');
    if (approvedWorkshop) return '/workshop/operations';
    const approvedWarehouse = organizations.find((o) => o.organization_type === 'WAREHOUSE' && o.status === 'APPROVED');
    if (approvedWarehouse) return '/warehouse/hub';
    if (organizations.some((o) => ['PENDING_REVIEW', 'DOCUMENTS_REQUIRED'].includes(o.status))) return '/provider-onboarding/status';
    if (authz.roles.includes('customer')) return '/marketplace';
    return '/unauthorized';
  }

  private permissionsHash(permissionCodes: string[]) {
    return createHash('sha256').update(permissionCodes.sort().join('|')).digest('hex');
  }

  private async createAuthSession(userId: number, meta: { deviceId?: number | null; ipAddress?: string | null; userAgent?: string | null; permissions: string[] }) {
    const expiresAt = new Date(Date.now() + this.refreshTokenDays * 24 * 60 * 60 * 1000);
    return this.prisma.authSession.create({
      data: {
        userId,
        deviceId: meta.deviceId ?? undefined,
        ipAddress: meta.ipAddress ?? undefined,
        userAgent: meta.userAgent ?? undefined,
        permissionsHash: this.permissionsHash(meta.permissions),
        expiresAt,
      },
    });
  }

  private async issueAuthPayload(
    user: { id: number; publicId: string; phoneNormalized: string | null; email?: string | null; displayName: string | null; status?: string },
    meta: { deviceId?: number | null; ipAddress?: string | null; userAgent?: string | null; deviceToken?: string | null } = {},
  ) {
    if (user.status === 'BLOCKED') {
      throw new ForbiddenException({ message: 'auth.account_blocked', error_code: 'ACCOUNT_BLOCKED' });
    }
    const authz = await this.userAuthorization(user.id);
    const organizations = await this.userOrganizations(user.id);
    const session = await this.createAuthSession(user.id, {
      deviceId: meta.deviceId ?? null,
      ipAddress: meta.ipAddress ?? null,
      userAgent: meta.userAgent ?? null,
      permissions: authz.permissions,
    });
    const accessToken = this.signAccessToken(user);
    const refreshToken = await this.issueRefreshToken(user.id, {
      deviceId: meta.deviceId ?? null,
      sessionId: session.id,
      ipAddress: meta.ipAddress ?? null,
      userAgent: meta.userAgent ?? null,
    });

    await this.prisma.user.update({ where: { id: user.id }, data: { lastLoginAt: new Date(), failedLoginCount: 0, lockedUntil: null } });

    return {
      user: {
        id: user.publicId,
        phone: user.phoneNormalized,
        email: user.email ?? null,
        display_name: user.displayName,
        status: user.status,
        roles: authz.roles,
        permissions: authz.permissions,
        organizations,
        dashboard_route: this.dashboardFor(authz, organizations),
      },
      access_token: accessToken,
      refresh_token: refreshToken,
      session_id: session.publicId,
      device_token: meta.deviceToken ?? undefined,
    };
  }

  private async ensureCustomerRole() {
    return this.prisma.role.upsert({
      where: { code: 'customer' },
      update: {},
      create: { code: 'customer', name: 'Customer' },
    });
  }

  private async findOrCreateUser(phone: string, displayName?: string) {
    return this.findOrCreateUserForOtp('phone', this.normalizePhone(phone), displayName);
  }

  private async findOrCreateUserForOtp(targetType: 'phone' | 'email', targetValue: string, displayName?: string, locale: 'ar' | 'en' = 'ar') {
    await this.ensureCustomerRole();

    const where = targetType === 'email'
      ? { email: targetValue }
      : { phoneNormalized: targetValue };

    let user = await this.prisma.user.findFirst({
      where,
      include: { customerProfile: true },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          phoneE164: targetType === 'phone' ? this.phoneE164(targetValue) : null,
          phoneNormalized: targetType === 'phone' ? targetValue : null,
          email: targetType === 'email' ? targetValue : null,
          displayName,
          status: 'ACTIVE',
          isPhoneVerified: targetType === 'phone',
          locale,
          customerProfile: { create: { displayName } },
          userRoles: {
            create: {
              role: { connect: { code: 'customer' } },
            },
          },
        },
        include: { customerProfile: true },
      });
    } else {
      const updateData: Record<string, unknown> = {};
      if (displayName && !user.displayName) updateData.displayName = displayName;
      if (user.locale !== locale) updateData.locale = locale;
      if (targetType === 'phone' && !user.isPhoneVerified) updateData.isPhoneVerified = true;
      if (Object.keys(updateData).length > 0) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: updateData,
          include: { customerProfile: true },
        });
      }
      if (!user.customerProfile) {
        await this.prisma.customerProfile.create({ data: { userId: user.id, displayName } });
        user = await this.prisma.user.findUniqueOrThrow({
          where: { id: user.id },
          include: { customerProfile: true },
        });
      }
    }

    return user;
  }


  async requestOtp(dto: RequestOtpDto, requestLocale?: string) {
    const target = this.resolveOtpTarget(dto);

    if (target.targetType === 'phone' && target.purpose === 'REGISTER') {
      const existing = await this.prisma.user.findFirst({ where: { phoneNormalized: target.targetValue } });
      if (existing) {
        throw new BadRequestException({ message: 'auth.phone_already_registered', error_code: 'PHONE_ALREADY_REGISTERED' });
      }
    }

    const recentWindow = new Date(Date.now() - 10 * 60 * 1000);
    const recentRequests = await this.prisma.otpRequest.count({
      where: { targetType: target.targetType, targetValue: target.targetValue, createdAt: { gte: recentWindow } },
    });
    if (recentRequests >= Number(this.config.get('OTP_MAX_REQUESTS_PER_10_MIN', 5))) {
      throw new HttpException(
        {
          message: 'auth.otp_rate_limited',
          error_code: 'OTP_RATE_LIMITED',
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const otpCode = this.generateOtpCode();
    const otpHash = await bcrypt.hash(otpCode, 10);
    const otpTtlMinutes = Number(this.config.get('OTP_TTL_MINUTES', this.config.get('OTP_EXPIRES_MINUTES', 5)));
    const expiresAt = new Date(Date.now() + otpTtlMinutes * 60 * 1000);

    await this.prisma.otpRequest.create({
      data: {
        targetType: target.targetType,
        targetValue: target.targetValue,
        purpose: target.purpose as any,
        otpHash,
        expiresAt,
        status: 'PENDING',
      },
    });

    await this.otpDelivery.sendOtp({
      channel: target.deliveryChannel,
      target: target.targetValue,
      code: otpCode,
      purpose: target.purpose,
      locale: this.i18n.normalize(requestLocale),
    });

    await this.eventBus.publish({
      name: 'OtpRequested',
      aggregateType: 'otp',
      aggregateId: target.targetValue,
      payload: {
        target_type: target.targetType,
        target: this.maskTarget(target.targetType, target.targetValue),
        channel: target.deliveryChannel,
        purpose: target.purpose,
      },
    });

    const smsProviderForDev = this.config.get<string>('SMS_PROVIDER', 'CONSOLE').toUpperCase();
    const isDevVisibleOtpProvider = smsProviderForDev === 'CONSOLE'
      || smsProviderForDev === 'DEV_CONSOLE'
      || smsProviderForDev === 'LOG_ONLY';
    const exposeDevOtp = target.deliveryChannel === 'SMS' && isDevVisibleOtpProvider && this.config.get<string>('NODE_ENV', 'development') !== 'production';

    return {
      success: true,
      message: 'common.success',
      data: {
        channel: target.deliveryChannel,
        target: this.maskTarget(target.targetType, target.targetValue),
        expires_at: expiresAt.toISOString(),
        provider: target.deliveryChannel === 'SMS' ? this.config.get<string>('SMS_PROVIDER', 'CONSOLE') : this.config.get<string>('EMAIL_PROVIDER', 'CONSOLE'),
        if_dev_mode_otp: exposeDevOtp ? otpCode : undefined,
      },
    };
  }

  async verifyOtp(dto: VerifyOtpDto, requestLocale?: string) {
    const target = this.resolveOtpTarget(dto);
    const request = await this.prisma.otpRequest.findFirst({
      where: {
        targetType: target.targetType,
        targetValue: target.targetValue,
        purpose: target.purpose as any,
        consumedAt: null,
        status: 'PENDING',
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!request) {
      throw new BadRequestException({
        message: 'auth.otp_not_found',
        error_code: 'OTP_NOT_FOUND',
      });
    }

    if (request.expiresAt < new Date()) {
      await this.prisma.otpRequest.update({
        where: { id: request.id },
        data: { status: 'EXPIRED' },
      });
      throw new BadRequestException({
        message: 'auth.otp_expired',
        error_code: 'OTP_EXPIRED',
      });
    }

    if (request.attempts >= request.maxAttempts) {
      throw new BadRequestException({
        message: 'auth.otp_max_attempts',
        error_code: 'OTP_MAX_ATTEMPTS_REACHED',
      });
    }

    const isValid = await bcrypt.compare(dto.otpCode, request.otpHash);
    if (!isValid) {
      await this.prisma.otpRequest.update({
        where: { id: request.id },
        data: { attempts: request.attempts + 1 },
      });
      throw new UnauthorizedException({
        message: 'auth.invalid_otp',
        error_code: 'INVALID_OTP',
      });
    }

    const user = await this.findOrCreateUserForOtp(target.targetType, target.targetValue, dto.displayName, this.i18n.normalize(requestLocale));

    await this.prisma.otpRequest.update({
      where: { id: request.id },
      data: { consumedAt: new Date(), status: 'CONSUMED' },
    });

    await this.eventBus.publish({
      name: 'OtpVerified',
      aggregateType: 'user',
      aggregateId: user.publicId,
      actorUserId: user.id,
      payload: {
        target_type: target.targetType,
        target: this.maskTarget(target.targetType, target.targetValue),
        purpose: target.purpose,
      },
    });

    return {
      success: true,
      message: 'common.success',
      data: await this.issueAuthPayload(user),
    };
  }

  async refresh(refreshToken: string) {
    if (!refreshToken) {
      throw new UnauthorizedException({ message: 'auth.refresh_required', error_code: 'REFRESH_TOKEN_REQUIRED' });
    }

    const tokens = await this.prisma.refreshToken.findMany({
      where: { revokedAt: null, expiresAt: { gt: new Date() } },
      include: { user: true },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });

    for (const tokenRecord of tokens) {
      const isMatch = await bcrypt.compare(refreshToken, tokenRecord.tokenHash);
      if (!isMatch) continue;

      await this.prisma.refreshToken.update({
        where: { id: tokenRecord.id },
        data: { revokedAt: new Date() },
      });

      return {
        success: true,
        message: 'common.success',
        data: await this.issueAuthPayload(tokenRecord.user),
      };
    }

    throw new UnauthorizedException({ message: 'auth.invalid_token', error_code: 'INVALID_REFRESH_TOKEN' });
  }

  async createGuestSession(dto: CreateGuestSessionDto = {}) {
    const plainToken = randomBytes(32).toString('hex');
    const guestTokenHash = await bcrypt.hash(plainToken, 10);
    const expiresAt = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000);

    // MySQL migrations keep publicId as NOT NULL without a DB default because
    // Prisma normally generates cuid() on the client. Providing it explicitly
    // makes guest session creation deterministic across generated clients,
    // shadow databases, and production deploys.
    const publicId = `gst_${randomBytes(12).toString('hex')}`;

    const data: {
      publicId: string;
      guestTokenHash: string;
      cityId?: number;
      districtId?: number;
      areaId?: number;
      expiresAt: Date;
    } = {
      publicId,
      guestTokenHash,
      expiresAt,
    };

    if (dto.cityId != null) data.cityId = dto.cityId;
    if (dto.districtId != null) data.districtId = dto.districtId;
    if (dto.areaId != null) data.areaId = dto.areaId;

    try {
      const guest = await this.prisma.guestSession.create({ data });

      await this.eventBus.publish({
        name: 'GuestSessionCreated',
        aggregateType: 'guest_session',
        aggregateId: guest.publicId,
        payload: { expires_at: expiresAt.toISOString() },
      });

      return {
        success: true,
        message: 'Guest session created successfully',
        data: {
          id: guest.publicId,
          guest_token: plainToken,
          expires_at: expiresAt.toISOString(),
        },
      };
    } catch (error) {
      // Defensive production fallback:
      // If Prisma Client is stale or generated from a slightly different schema,
      // keep the guest flow working through the exact SQL table/columns created by migrations.
      // This prevents the public entry flow from failing with 500 while still storing data in DB.
      // The original error is logged for engineering diagnostics.
      // eslint-disable-next-line no-console
      console.error('[AuthService.createGuestSession] Prisma create failed, using raw SQL fallback:', error);

      await this.prisma.$executeRaw`
        INSERT INTO iam_guest_sessions
          (publicId, guest_token_hash, city_id, district_id, area_id, expires_at)
        VALUES
          (${publicId}, ${guestTokenHash}, ${data.cityId ?? null}, ${data.districtId ?? null}, ${data.areaId ?? null}, ${expiresAt})
      `;

      const rows = await this.prisma.$queryRaw<Array<{ publicId: string; expires_at: Date }>>`
        SELECT publicId, expires_at
        FROM iam_guest_sessions
        WHERE publicId = ${publicId}
        LIMIT 1
      `;

      const created = rows[0];
      if (!created) {
        throw new HttpException(
          {
            message: 'تعذر إنشاء جلسة الزائر',
            error_code: 'GUEST_SESSION_CREATE_FAILED',
          },
          HttpStatus.INTERNAL_SERVER_ERROR,
        );
      }

      return {
        success: true,
        message: 'Guest session created successfully',
        data: {
          id: created.publicId,
          guest_token: plainToken,
          expires_at: new Date(created.expires_at).toISOString(),
        },
      };
    }
  }

  async updateGuestSessionLocation(dto: GuestSessionLocationDto) {
    type GuestSessionCandidate = {
      id: number;
      publicId: string;
      guestTokenHash: string;
    };

    let sessions: GuestSessionCandidate[];
    try {
      sessions = await this.prisma.guestSession.findMany({
        where: { expiresAt: { gt: new Date() }, consumedByUserId: null },
        orderBy: { createdAt: 'desc' },
        take: 100,
        select: { id: true, publicId: true, guestTokenHash: true },
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('[AuthService.updateGuestSessionLocation] Prisma read failed, using raw SQL fallback:', error);
      const rows = await this.prisma.$queryRaw<Array<{ id: number; publicId: string; guest_token_hash: string }>>`
        SELECT id, publicId, guest_token_hash
        FROM iam_guest_sessions
        WHERE expires_at > NOW(3) AND consumed_by_user_id IS NULL
        ORDER BY created_at DESC
        LIMIT 100
      `;
      sessions = rows.map((row) => ({
        id: row.id,
        publicId: row.publicId,
        guestTokenHash: row.guest_token_hash,
      }));
    }

    for (const session of sessions) {
      const isMatch = await bcrypt.compare(dto.guestToken, session.guestTokenHash);
      if (!isMatch) continue;

      try {
        const updated = await this.prisma.guestSession.update({
          where: { id: session.id },
          data: { cityId: dto.cityId, districtId: dto.districtId, areaId: dto.areaId },
        });

        return {
          success: true,
          message: 'Guest location updated successfully',
          data: { id: updated.publicId, city_id: updated.cityId, district_id: updated.districtId, area_id: updated.areaId },
        };
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error('[AuthService.updateGuestSessionLocation] Prisma update failed, using raw SQL fallback:', error);
        await this.prisma.$executeRaw`
          UPDATE iam_guest_sessions
          SET city_id = ${dto.cityId ?? null}, district_id = ${dto.districtId ?? null}, area_id = ${dto.areaId ?? null}
          WHERE id = ${session.id}
        `;

        return {
          success: true,
          message: 'Guest location updated successfully',
          data: { id: session.publicId, city_id: dto.cityId ?? null, district_id: dto.districtId ?? null, area_id: dto.areaId ?? null },
        };
      }
    }

    throw new UnauthorizedException({ message: 'Guest token is invalid or expired', error_code: 'INVALID_GUEST_TOKEN' });
  }


  private normalizePlatform(platform?: string) {
    return (platform ?? 'UNKNOWN').toUpperCase();
  }

  private async assertNotLocked(user: { id: number; lockedUntil?: Date | null; status?: string }) {
    if (user.status === 'BLOCKED') {
      throw new ForbiddenException({ message: 'auth.account_blocked', error_code: 'ACCOUNT_BLOCKED' });
    }
    if (user.lockedUntil && user.lockedUntil > new Date()) {
      throw new ForbiddenException({ message: 'auth.account_locked', error_code: 'ACCOUNT_LOCKED', locked_until: user.lockedUntil.toISOString() });
    }
  }

  private async findTrustedDevice(userId: number, deviceFingerprint: string, deviceToken?: string) {
    const device = await this.prisma.authTrustedDevice.findFirst({
      where: {
        userId,
        deviceFingerprint,
        status: 'TRUSTED',
        revokedAt: null,
      },
    });
    if (!device || !deviceToken) return null;
    const isTokenValid = await bcrypt.compare(deviceToken, device.deviceTokenHash);
    if (!isTokenValid) return null;
    await this.prisma.authTrustedDevice.update({ where: { id: device.id }, data: { lastUsedAt: new Date() } });
    return device;
  }

  private async trustDevice(userId: number, dto: { deviceFingerprint: string; deviceName?: string; platform?: string }, meta: { ipAddress?: string | null; userAgent?: string | null }) {
    const plainDeviceToken = randomBytes(48).toString('hex');
    const deviceTokenHash = await bcrypt.hash(plainDeviceToken, 10);
    const existing = await this.prisma.authTrustedDevice.findFirst({
      where: { userId, deviceFingerprint: dto.deviceFingerprint },
    });
    const device = existing
      ? await this.prisma.authTrustedDevice.update({
          where: { id: existing.id },
          data: {
            deviceTokenHash,
            deviceName: dto.deviceName ?? existing.deviceName,
            platform: this.normalizePlatform(dto.platform),
            ipAddress: meta.ipAddress ?? undefined,
            userAgent: meta.userAgent ?? undefined,
            status: 'TRUSTED',
            trustedAt: new Date(),
            lastUsedAt: new Date(),
            revokedAt: null,
          },
        })
      : await this.prisma.authTrustedDevice.create({
          data: {
            userId,
            deviceFingerprint: dto.deviceFingerprint,
            deviceTokenHash,
            deviceName: dto.deviceName,
            platform: this.normalizePlatform(dto.platform),
            ipAddress: meta.ipAddress ?? undefined,
            userAgent: meta.userAgent ?? undefined,
            lastUsedAt: new Date(),
          },
        });

    await this.auditDevice(userId, 'auth.device.trusted', device.publicId, meta);
    return { device, plainDeviceToken };
  }

  private async auditDevice(userId: number | null, action: string, deviceId: string | null, meta: { ipAddress?: string | null; userAgent?: string | null }) {
    await this.prisma.auditLog.create({
      data: {
        actorUserId: userId ?? undefined,
        action,
        entityType: 'auth_device',
        entityId: deviceId ?? undefined,
        ipAddress: meta.ipAddress ?? undefined,
        userAgent: meta.userAgent ?? undefined,
        metadata: {},
      },
    });
  }

  private async sendLoginOtp(phoneNormalized: string, meta: { ipAddress?: string | null; userAgent?: string | null; locale?: string | null }) {
    return this.requestOtp({ phone: phoneNormalized, purpose: 'LOGIN', channel: 'SMS' }, meta.locale ?? undefined);
  }

  async startPhoneLogin(dto: StartPhoneLoginDto, meta: { ipAddress?: string | null; userAgent?: string | null; locale?: string | null }) {
    const phoneNormalized = this.normalizePhone(dto.phone);
    const user = await this.prisma.user.findFirst({ where: { phoneNormalized } });
    if (!user) {
      throw new NotFoundException({
        message: 'auth.phone_not_registered',
        error_code: 'PHONE_NOT_REGISTERED',
      });
    }

    await this.assertNotLocked(user);
    const trustedDevice = await this.findTrustedDevice(user.id, dto.deviceFingerprint, dto.deviceToken);
    if (trustedDevice) {
      await this.auditDevice(user.id, 'auth.login.trusted_device', trustedDevice.publicId, meta);
      return {
        success: true,
        message: 'auth.login_success',
        data: {
          otp_required: false,
          trusted_device: true,
          ...(await this.issueAuthPayload(user, { deviceId: trustedDevice.id, ipAddress: meta.ipAddress, userAgent: meta.userAgent })),
        },
      };
    }

    await this.sendLoginOtp(phoneNormalized, meta);
    await this.auditDevice(user.id, 'auth.login.otp_required', null, meta);
    return {
      success: true,
      message: 'auth.otp_required',
      data: { otp_required: true, trusted_device: false, account_exists: true, phone: phoneNormalized },
    };
  }

  private async verifyOtpChallenge(phone: string, otpCode: string, purpose: 'LOGIN' | 'REGISTER' | 'EMPLOYEE_INVITE') {
    const phoneNormalized = this.normalizePhone(phone);
    const request = await this.prisma.otpRequest.findFirst({
      where: { targetType: 'phone', targetValue: phoneNormalized, purpose: purpose as any, consumedAt: null, status: 'PENDING' },
      orderBy: { createdAt: 'desc' },
    });
    if (!request) throw new BadRequestException({ message: 'auth.otp_not_found', error_code: 'OTP_NOT_FOUND' });
    if (request.expiresAt < new Date()) {
      await this.prisma.otpRequest.update({ where: { id: request.id }, data: { status: 'EXPIRED' } });
      throw new BadRequestException({ message: 'auth.otp_expired', error_code: 'OTP_EXPIRED' });
    }
    if (request.attempts >= request.maxAttempts) {
      throw new BadRequestException({ message: 'auth.otp_max_attempts', error_code: 'OTP_MAX_ATTEMPTS_REACHED' });
    }
    const isValid = await bcrypt.compare(otpCode, request.otpHash);
    if (!isValid) {
      await this.prisma.otpRequest.update({ where: { id: request.id }, data: { attempts: request.attempts + 1 } });
      throw new UnauthorizedException({ message: 'auth.invalid_otp', error_code: 'INVALID_OTP' });
    }
    await this.prisma.otpRequest.update({ where: { id: request.id }, data: { consumedAt: new Date(), status: 'CONSUMED' } });
    return phoneNormalized;
  }

  async verifyTrustedDeviceOtp(dto: VerifyTrustedDeviceOtpDto, meta: { ipAddress?: string | null; userAgent?: string | null; locale?: string | null }) {
    const phoneNormalized = this.normalizePhone(dto.phone);
    const request = await this.prisma.otpRequest.findFirst({
      where: { targetType: 'phone', targetValue: phoneNormalized, purpose: (dto.purpose ?? 'LOGIN') as any, consumedAt: null, status: 'PENDING' },
      orderBy: { createdAt: 'desc' },
    });
    if (!request) throw new BadRequestException({ message: 'auth.otp_not_found', error_code: 'OTP_NOT_FOUND' });
    if (request.expiresAt < new Date()) {
      await this.prisma.otpRequest.update({ where: { id: request.id }, data: { status: 'EXPIRED' } });
      throw new BadRequestException({ message: 'auth.otp_expired', error_code: 'OTP_EXPIRED' });
    }
    const isValid = await bcrypt.compare(dto.otpCode, request.otpHash);
    if (!isValid) {
      await this.prisma.otpRequest.update({ where: { id: request.id }, data: { attempts: request.attempts + 1 } });
      const user = await this.prisma.user.findFirst({ where: { phoneNormalized } });
      if (user && request.attempts + 1 >= request.maxAttempts) {
        await this.prisma.user.update({ where: { id: user.id }, data: { failedLoginCount: { increment: 1 }, lockedUntil: new Date(Date.now() + 15 * 60 * 1000) } });
      }
      throw new UnauthorizedException({ message: 'auth.invalid_otp', error_code: 'INVALID_OTP' });
    }

    const user = await this.prisma.user.findFirst({ where: { phoneNormalized } });
    if (!user) {
      throw new NotFoundException({ message: 'auth.phone_not_registered', error_code: 'PHONE_NOT_REGISTERED' });
    }
    await this.assertNotLocked(user);
    await this.prisma.otpRequest.update({ where: { id: request.id }, data: { consumedAt: new Date(), status: 'CONSUMED', userId: user.id } });
    const trusted = await this.trustDevice(user.id, dto, meta);
    await this.eventBus.publish({
      name: 'auth.device_trusted',
      aggregateType: 'user',
      aggregateId: user.publicId,
      actorUserId: user.id,
      payload: { device_id: trusted.device.publicId, platform: dto.platform ?? 'UNKNOWN' },
    });
    return { success: true, message: 'auth.login_success', data: await this.issueAuthPayload(user, { deviceId: trusted.device.id, ipAddress: meta.ipAddress, userAgent: meta.userAgent, deviceToken: trusted.plainDeviceToken }) };
  }

  async validateSession(userId: number, dto: ValidateSessionDto, meta: { ipAddress?: string | null; userAgent?: string | null }) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException({ message: 'auth.invalid_token', error_code: 'INVALID_USER' });
    await this.assertNotLocked(user);
    const trustedDevice = await this.findTrustedDevice(user.id, dto.deviceFingerprint, dto.deviceToken);
    if (!trustedDevice) {
      throw new UnauthorizedException({ message: 'auth.device_not_trusted', error_code: 'DEVICE_NOT_TRUSTED' });
    }
    await this.prisma.authSession.updateMany({ where: { userId, status: 'ACTIVE', revokedAt: null }, data: { lastSeenAt: new Date(), ipAddress: meta.ipAddress ?? undefined, userAgent: meta.userAgent ?? undefined } });
    const authz = await this.userAuthorization(user.id);
    const organizations = await this.userOrganizations(user.id);
    return {
      success: true,
      message: 'common.success',
      data: {
        valid: true,
        user: {
          id: user.publicId,
          phone: user.phoneNormalized,
          email: user.email,
          display_name: user.displayName,
          roles: authz.roles,
          permissions: authz.permissions,
          organizations,
          dashboard_route: this.dashboardFor(authz, organizations),
        },
      },
    };
  }

  private validateDocumentUpload(document: VerificationDocumentUploadDto) {
    const mime = document.mimeType.toLowerCase();
    if (document.documentType === 'BANK_STATEMENT' && mime !== 'application/pdf') {
      throw new BadRequestException({ message: 'validation.file_pdf_required', error_code: 'PDF_REQUIRED' });
    }
    if (document.documentType === 'NATIONAL_ID' && !['image/jpeg', 'image/jpg', 'image/png'].includes(mime)) {
      throw new BadRequestException({ message: 'validation.file_image_required', error_code: 'IMAGE_REQUIRED' });
    }
    if (document.documentType === 'PASSPORT' && !['image/jpeg', 'image/jpg', 'image/png'].includes(mime)) {
      throw new BadRequestException({ message: 'validation.file_image_required', error_code: 'IMAGE_REQUIRED' });
    }
    if (document.documentType === 'COMMERCIAL_REGISTRATION' && !['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'].includes(mime)) {
      throw new BadRequestException({ message: 'validation.file_image_or_pdf_required', error_code: 'IMAGE_OR_PDF_REQUIRED' });
    }
  }

  private validateBusinessDocuments(documents: VerificationDocumentUploadDto[] = []) {
    if (!documents.length) {
      throw new BadRequestException({ message: 'validation.documents_required', error_code: 'DOCUMENTS_REQUIRED' });
    }
    for (const doc of documents) this.validateDocumentUpload(doc);
    const documentTypes = new Set(documents.map((d) => d.documentType));
    if (documentTypes.size !== 1) {
      throw new BadRequestException({ message: 'validation.one_document_type_required', error_code: 'ONE_DOCUMENT_TYPE_REQUIRED' });
    }
    const documentType = documents[0].documentType;
    if (documentType === 'NATIONAL_ID') {
      const sides = new Set(documents.map((d) => d.side));
      if (!sides.has('FRONT') || !sides.has('BACK')) {
        throw new BadRequestException({ message: 'validation.national_id_front_back_required', error_code: 'NATIONAL_ID_SIDES_REQUIRED' });
      }
    }
    if (documentType === 'PASSPORT' && !documents.some((d) => (d.side ?? 'MAIN') === 'MAIN')) {
      throw new BadRequestException({ message: 'validation.passport_image_required', error_code: 'PASSPORT_IMAGE_REQUIRED' });
    }
    if (documentType === 'BANK_STATEMENT' && !documents.some((d) => d.mimeType.toLowerCase() === 'application/pdf')) {
      throw new BadRequestException({ message: 'validation.bank_statement_pdf_required', error_code: 'BANK_STATEMENT_PDF_REQUIRED' });
    }
    if (documentType === 'COMMERCIAL_REGISTRATION' && documents.length < 1) {
      throw new BadRequestException({ message: 'validation.commercial_registration_required', error_code: 'COMMERCIAL_REGISTRATION_REQUIRED' });
    }
  }

  private async validateBusinessLocation(cityId: number, districtId?: number, areaId?: number) {
    const city = await this.prisma.city.findUnique({ where: { id: cityId } });
    if (!city || !city.isActive) throw new BadRequestException({ message: 'validation.city_required', error_code: 'CITY_REQUIRED' });
    if (districtId != null) {
      const district = await this.prisma.district.findUnique({ where: { id: districtId } });
      if (!district || district.cityId !== cityId || !district.isActive) throw new BadRequestException({ message: 'validation.district_required', error_code: 'DISTRICT_REQUIRED' });
    }
    if (areaId != null) {
      const area = await this.prisma.area.findUnique({ where: { id: areaId } });
      if (!area || !area.isActive) throw new BadRequestException({ message: 'validation.area_required', error_code: 'AREA_REQUIRED' });
      if (districtId != null && area.districtId !== districtId) throw new BadRequestException({ message: 'validation.area_required', error_code: 'AREA_REQUIRED' });
    }
  }

  async registerCustomer(dto: RegisterCustomerDto, meta: { ipAddress?: string | null; userAgent?: string | null; locale?: string | null }) {
    const phoneNormalized = this.normalizePhone(dto.phone);
    const existing = await this.prisma.user.findFirst({ where: { phoneNormalized } });
    if (existing) {
      throw new BadRequestException({ message: 'auth.phone_already_registered', error_code: 'PHONE_ALREADY_REGISTERED' });
    }
    await this.verifyOtpChallenge(phoneNormalized, dto.otpCode, 'REGISTER');
    const customerRole = await this.ensureCustomerRole();
    const user = await this.prisma.user.create({
      data: {
        phoneE164: this.phoneE164(phoneNormalized),
        phoneNormalized,
        email: dto.email ? this.normalizeEmail(dto.email) : null,
        displayName: dto.fullName?.trim() || phoneNormalized,
        status: 'ACTIVE',
        isPhoneVerified: true,
        locale: this.i18n.normalize(meta.locale),
        customerProfile: { create: { displayName: dto.fullName?.trim() || phoneNormalized } },
        userRoles: { create: { role: { connect: { id: customerRole.id } } } },
      },
    });
    await this.prisma.auditLog.create({ data: { actorUserId: user.id, action: 'auth.customer.registered', entityType: 'user', entityId: user.publicId, ipAddress: meta.ipAddress ?? undefined, userAgent: meta.userAgent ?? undefined } });
    const trusted = await this.trustDevice(user.id, dto, meta);
    return { success: true, message: 'auth.customer_registered', data: await this.issueAuthPayload(user, { deviceId: trusted.device.id, ipAddress: meta.ipAddress, userAgent: meta.userAgent, deviceToken: trusted.plainDeviceToken }) };
  }

  private roleCodeForBusiness(type: 'MERCHANT' | 'WORKSHOP' | 'WAREHOUSE') {
    if (type === 'MERCHANT') return 'merchant_owner';
    if (type === 'WORKSHOP') return 'workshop_owner';
    return 'warehouse_owner';
  }

  async registerBusiness(dto: RegisterBusinessDto, meta: { ipAddress?: string | null; userAgent?: string | null; locale?: string | null }) {
    this.validateBusinessDocuments(dto.documents ?? []);
    await this.validateBusinessLocation(dto.cityId, dto.districtId, dto.areaId);
    if (dto.latitude == null || dto.longitude == null || !dto.mapUrl?.trim()) {
      throw new BadRequestException({ message: 'auth.map.location_required', error_code: 'MAP_LOCATION_REQUIRED' });
    }
    if (dto.latitude < 12 || dto.latitude > 19 || dto.longitude < 42 || dto.longitude > 55) {
      throw new BadRequestException({ message: 'auth.map.location_outside_yemen', error_code: 'LOCATION_OUTSIDE_YEMEN' });
    }
    const phoneNormalized = this.normalizePhone(dto.phone);
    const existing = await this.prisma.user.findFirst({ where: { phoneNormalized } });
    if (existing) {
      throw new BadRequestException({ message: 'auth.phone_already_registered', error_code: 'PHONE_ALREADY_REGISTERED' });
    }
    await this.verifyOtpChallenge(phoneNormalized, dto.otpCode, 'REGISTER');

    const role = await this.prisma.role.upsert({
      where: { code: this.roleCodeForBusiness(dto.accountType) },
      update: {},
      create: { code: this.roleCodeForBusiness(dto.accountType), name: this.roleCodeForBusiness(dto.accountType) },
    });

    const created = await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          phoneE164: this.phoneE164(phoneNormalized),
          phoneNormalized,
          email: this.normalizeEmail(dto.email),
          displayName: dto.fullName,
          isPhoneVerified: true,
          status: 'ACTIVE',
          locale: this.i18n.normalize(meta.locale),
          customerProfile: { create: { displayName: dto.fullName } },
          userRoles: { create: { role: { connect: { id: role.id } } } },
        },
      });

      const organization = await tx.organization.create({
        data: {
          organizationType: dto.accountType,
          displayName: dto.businessName,
          legalName: dto.businessName,
          primaryPhone: phoneNormalized,
          status: 'PENDING_REVIEW',
          submittedAt: new Date(),
          members: { create: { userId: user.id, memberRole: 'owner', status: 'ACTIVE' } },
          branches: {
            create: {
              branchName: dto.branchName?.trim() || dto.businessName,
              cityId: dto.cityId,
              districtId: dto.districtId,
              areaId: dto.areaId,
              addressLine1: dto.address,
              latitude: dto.latitude,
              longitude: dto.longitude,
              mapUrl: dto.mapUrl ?? (dto.latitude != null && dto.longitude != null ? `https://www.google.com/maps/search/?api=1&query=${dto.latitude},${dto.longitude}` : undefined),
              mapProvider: 'GOOGLE_MAPS',
              locationSelectedAt: dto.latitude != null && dto.longitude != null ? new Date() : undefined,
              isHeadOffice: true,
              supportsPickup: dto.accountType === 'MERCHANT',
              supportsDelivery: dto.accountType === 'MERCHANT',
              supportsInstallation: dto.accountType === 'WORKSHOP',
            },
          },
          ...(dto.accountType === 'MERCHANT'
            ? { merchantProfile: { create: { warrantyPolicyText: dto.businessDescription, deliveryPolicyText: dto.businessDescription } } }
            : dto.accountType === 'WORKSHOP'
              ? { workshopProfile: { create: { serviceModeCode: 'GENERAL', acceptsDiagnosis: true, acceptsInstallation: true } } }
              : {}),
        },
      });

      const verification = await tx.verificationRequest.create({
        data: {
          organizationId: organization.id,
          submittedByUserId: user.id,
          status: 'PENDING_REVIEW',
          notes: dto.businessDescription,
          submittedAt: new Date(),
          documents: {
            create: (dto.documents ?? []).map((doc) => ({
              documentType: doc.documentType as any,
              fileName: doc.fileName,
              fileUrl: '',
              mimeType: doc.mimeType,
              fileSizeBytes: doc.fileSizeBytes,
              fileContentBase64: doc.fileContentBase64.replace(/^data:[^;]+;base64,/, ''),
              storageProvider: 'DATABASE',
              storageKey: `${organization.publicId}/${doc.documentType}/${doc.side ?? 'MAIN'}/${doc.fileName}`,
              uploadStatus: 'UPLOADED',
              side: doc.side ?? 'MAIN',
            })),
          },
        },
      });

      await (tx as any).verificationStatusHistory.create({ data: { verificationRequestId: verification.id, organizationId: organization.id, fromStatus: null, toStatus: 'PENDING_REVIEW', changedByUserId: user.id, reason: 'Submitted through enterprise registration flow' } });
      await tx.auditLog.create({ data: { actorUserId: user.id, action: 'membership.application.submitted', entityType: 'verification_request', entityId: verification.publicId, ipAddress: meta.ipAddress ?? undefined, userAgent: meta.userAgent ?? undefined, metadata: { organization_id: organization.publicId, account_type: dto.accountType } } });
      return { user, organization, verification };
    });

    await this.eventBus.publish({ name: 'membership.application_submitted', aggregateType: 'verification_request', aggregateId: created.verification.publicId, actorUserId: created.user.id, payload: { organization_id: created.organization.publicId, account_type: dto.accountType } });
    const trusted = await this.trustDevice(created.user.id, dto, meta);
    return {
      success: true,
      message: 'membership.application_submitted',
      data: {
        status: 'PENDING_APPROVAL',
        organization_id: created.organization.publicId,
        verification_request_id: created.verification.publicId,
        submission_message: 'membership.submitted_under_review',
        auth: await this.issueAuthPayload(created.user, { deviceId: trusted.device.id, ipAddress: meta.ipAddress, userAgent: meta.userAgent, deviceToken: trusted.plainDeviceToken }),
      },
    };
  }

  async listTrustedDevices(userId: number) {
    const devices = await this.prisma.authTrustedDevice.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } });
    return { success: true, message: 'common.success', data: devices.map((device) => ({ id: device.publicId, device_name: device.deviceName, platform: device.platform, status: device.status, trusted_at: device.trustedAt, last_used_at: device.lastUsedAt, revoked_at: device.revokedAt })) };
  }

  async revokeTrustedDevice(userId: number, devicePublicId: string, meta: { ipAddress?: string | null; userAgent?: string | null }) {
    const device = await this.prisma.authTrustedDevice.findFirst({ where: { publicId: devicePublicId, userId } });
    if (!device) throw new NotFoundException({ message: 'auth.device_not_found', error_code: 'DEVICE_NOT_FOUND' });
    await this.prisma.$transaction([
      this.prisma.authTrustedDevice.update({ where: { id: device.id }, data: { status: 'REVOKED', revokedAt: new Date() } }),
      this.prisma.authSession.updateMany({ where: { deviceId: device.id, status: 'ACTIVE' }, data: { status: 'REVOKED', revokedAt: new Date() } }),
      this.prisma.refreshToken.updateMany({ where: { deviceId: device.id, revokedAt: null }, data: { revokedAt: new Date() } }),
    ]);
    await this.auditDevice(userId, 'auth.device.revoked', device.publicId, meta);
    return { success: true, message: 'common.success', data: null };
  }

  async logoutAllDevices(userId: number, meta: { ipAddress?: string | null; userAgent?: string | null }) {
    await this.prisma.$transaction([
      this.prisma.authTrustedDevice.updateMany({ where: { userId, revokedAt: null }, data: { status: 'REVOKED', revokedAt: new Date() } }),
      this.prisma.authSession.updateMany({ where: { userId, status: 'ACTIVE' }, data: { status: 'REVOKED', revokedAt: new Date() } }),
      this.prisma.refreshToken.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: new Date() } }),
    ]);
    await this.auditDevice(userId, 'auth.logout_all_devices', null, meta);
    return { success: true, message: 'common.success', data: null };
  }

  async logout(userId: number, refreshToken?: string) {
    if (refreshToken) {
      const tokens = await this.prisma.refreshToken.findMany({
        where: { userId, revokedAt: null },
      });
      for (const tokenRecord of tokens) {
        const isMatch = await bcrypt.compare(refreshToken, tokenRecord.tokenHash);
        if (isMatch) {
          await this.prisma.refreshToken.update({ where: { id: tokenRecord.id }, data: { revokedAt: new Date() } });
          break;
        }
      }
    }

    return {
      success: true,
      message: 'common.success',
      data: null,
    };
  }
}
