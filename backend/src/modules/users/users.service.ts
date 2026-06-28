import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateLocationDto } from './dto/update-location.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  private async userAuthorization(userId: number) {
    const roles = await this.prisma.userRole.findMany({
      where: { userId },
      include: { role: { include: { rolePermissions: { include: { permission: true } } } } },
    });
    return {
      roles: roles.map((item) => item.role.code),
      permissions: Array.from(new Set(roles.flatMap((item) => item.role.rolePermissions.map((rp) => rp.permission.code)))),
    };
  }

  async me(userId: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        customerProfile: {
          include: {
            city: true,
            district: true,
            area: true,
          },
        },
        customerVehicles: {
          include: {
            make: true,
            model: true,
            variant: true,
          },
          orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
        },
        organizationMembers: {
          include: {
            organization: {
              include: {
                verificationRequests: { orderBy: { createdAt: 'desc' }, take: 1 },
              },
            },
          },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!user) throw new NotFoundException('User not found');

    const authz = await this.userAuthorization(user.id);

    return {
      success: true,
      message: 'Current user retrieved successfully',
      data: {
        user: {
          id: user.publicId,
          phone: user.phoneNormalized,
          display_name: user.displayName,
          status: user.status,
          is_phone_verified: user.isPhoneVerified,
          locale: user.locale,
          roles: authz.roles,
          permissions: authz.permissions,
          organizations: user.organizationMembers.map((item) => ({
            id: item.organization.publicId,
            display_name: item.organization.displayName,
            organization_type: item.organization.organizationType,
            status: item.organization.status,
            is_verified: item.organization.isVerified,
            latest_verification_status: item.organization.verificationRequests[0]?.status ?? null,
          })),
        },
        profile: user.customerProfile
          ? {
              display_name: user.customerProfile.displayName,
              city_id: user.customerProfile.cityId,
              district_id: user.customerProfile.districtId,
              area_id: user.customerProfile.areaId,
              city_name: user.customerProfile.city?.nameAr,
              district_name: user.customerProfile.district?.nameAr,
              area_name: user.customerProfile.area?.nameAr,
            }
          : null,
        vehicles: user.customerVehicles.map((vehicle) => ({
          id: vehicle.publicId,
          make_id: vehicle.makeId,
          make_name: vehicle.make.nameAr,
          model_id: vehicle.modelId,
          model_name: vehicle.model.nameAr,
          variant_id: vehicle.variantId,
          variant_name: vehicle.variant?.trimName,
          year_value: vehicle.yearValue,
          is_default: vehicle.isDefault,
        })),
      },
    };
  }

  async updateProfile(userId: number, dto: UpdateProfileDto) {
    const profile = await this.prisma.customerProfile.upsert({
      where: { userId },
      create: {
        userId,
        displayName: dto.displayName,
      },
      update: {
        displayName: dto.displayName,
      },
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: { displayName: dto.displayName },
    });

    return {
      success: true,
      message: 'Profile updated successfully',
      data: {
        display_name: profile.displayName,
      },
    };
  }


  async updateLocale(userId: number, locale: 'ar' | 'en') {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { locale },
      select: { publicId: true, locale: true },
    });
    return {
      success: true,
      message: 'settings.language_changed',
      data: {
        id: user.publicId,
        locale: user.locale,
      },
    };
  }

  async updateLocation(userId: number, dto: UpdateLocationDto) {
    const profile = await this.prisma.customerProfile.upsert({
      where: { userId },
      create: {
        userId,
        cityId: dto.cityId,
        districtId: dto.districtId,
        areaId: dto.areaId,
      },
      update: {
        cityId: dto.cityId,
        districtId: dto.districtId,
        areaId: dto.areaId,
      },
      include: { city: true, district: true, area: true },
    });

    return {
      success: true,
      message: 'Location updated successfully',
      data: {
        city_id: profile.cityId,
        district_id: profile.districtId,
        area_id: profile.areaId,
        city_name: profile.city?.nameAr,
        district_name: profile.district?.nameAr,
        area_name: profile.area?.nameAr,
      },
    };
  }
}
