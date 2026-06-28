import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateAddressDto,
  UpdateAddressDto,
  UpsertCityDeliveryFeeDto,
  UpsertCityDto,
  UpsertDeliveryZoneDto,
  UpsertDistrictDto,
} from './dto/locations.dto';

@Injectable()
export class LocationsService {
  constructor(private readonly prisma: PrismaService) {}

  async countries() {
    const items = await this.prisma.country.findMany({
      where: { isActive: true },
      orderBy: { nameAr: 'asc' },
    });
    return { success: true, message: 'Countries retrieved successfully', data: items };
  }

  async states(countryId?: number) {
    const items = await this.prisma.state.findMany({
      where: { isActive: true, ...(countryId ? { countryId } : {}) },
      orderBy: { nameAr: 'asc' },
    });
    return { success: true, message: 'States retrieved successfully', data: items };
  }

  async cities(stateId?: number) {
    const items = await this.prisma.city.findMany({
      where: { isActive: true, ...(stateId ? { stateId } : {}) },
      include: { deliveryFee: true },
      orderBy: { nameAr: 'asc' },
    });
    return { success: true, message: 'Cities retrieved successfully', data: items };
  }

  async districts(cityId?: number) {
    const items = await this.prisma.district.findMany({
      where: { isActive: true, ...(cityId ? { cityId } : {}) },
      orderBy: { nameAr: 'asc' },
    });
    return { success: true, message: 'Districts retrieved successfully', data: items };
  }

  async areas(districtId?: number) {
    const items = await this.prisma.area.findMany({
      where: { isActive: true, ...(districtId ? { districtId } : {}) },
      orderBy: { nameAr: 'asc' },
    });
    return { success: true, message: 'Areas retrieved successfully', data: items };
  }

  async deliveryFees(cityId?: number) {
    const items = await this.prisma.cityDeliveryFee.findMany({
      where: cityId ? { cityId } : undefined,
      include: { city: true },
      orderBy: { city: { nameAr: 'asc' } },
    });
    return { success: true, message: 'City delivery fees retrieved successfully', data: items };
  }

  async deliveryZones(cityId?: number) {
    const items = await this.prisma.deliveryZone.findMany({
      where: { isActive: true, ...(cityId ? { cityId } : {}) },
      include: { city: true, district: true },
      orderBy: [{ city: { nameAr: 'asc' } }, { nameAr: 'asc' }],
    });
    return { success: true, message: 'Delivery zones retrieved successfully', data: items };
  }

  async myAddresses(userId: number) {
    const items = await this.prisma.address.findMany({
      where: { userId, isActive: true },
      include: { city: true, district: true, area: true },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });
    return { success: true, message: 'Addresses retrieved successfully', data: items };
  }

  async createAddress(userId: number, dto: CreateAddressDto) {
    await this.validateLocation(dto.cityId, dto.districtId, dto.areaId);

    const address = await this.prisma.$transaction(async (tx) => {
      if (dto.isDefault) {
        await tx.address.updateMany({ where: { userId }, data: { isDefault: false } });
      }

      const existing = await tx.address.count({ where: { userId, isActive: true } });
      return tx.address.create({
        data: {
          userId,
          label: dto.label,
          recipientName: dto.recipientName,
          phone: dto.phone,
          cityId: dto.cityId,
          districtId: dto.districtId,
          areaId: dto.areaId,
          addressLine1: dto.addressLine1,
          addressLine2: dto.addressLine2,
          latitude: dto.latitude,
          longitude: dto.longitude,
          isDefault: dto.isDefault ?? existing === 0,
        },
        include: { city: true, district: true, area: true },
      });
    });

    return { success: true, message: 'Address created successfully', data: address };
  }

  async updateAddress(userId: number, publicId: string, dto: UpdateAddressDto) {
    const existing = await this.prisma.address.findFirst({ where: { publicId, userId, isActive: true } });
    if (!existing) throw new NotFoundException({ message: 'Address not found', error_code: 'ADDRESS_NOT_FOUND' });

    const cityId = dto.cityId ?? existing.cityId;
    const districtId = dto.districtId === undefined ? existing.districtId ?? undefined : dto.districtId ?? undefined;
    const areaId = dto.areaId === undefined ? existing.areaId ?? undefined : dto.areaId ?? undefined;
    await this.validateLocation(cityId, districtId, areaId);

    const address = await this.prisma.$transaction(async (tx) => {
      if (dto.isDefault) {
        await tx.address.updateMany({ where: { userId }, data: { isDefault: false } });
      }
      return tx.address.update({
        where: { id: existing.id },
        data: {
          label: dto.label,
          recipientName: dto.recipientName,
          phone: dto.phone,
          cityId: dto.cityId,
          districtId: dto.districtId,
          areaId: dto.areaId,
          addressLine1: dto.addressLine1,
          addressLine2: dto.addressLine2,
          latitude: dto.latitude,
          longitude: dto.longitude,
          isDefault: dto.isDefault,
        },
        include: { city: true, district: true, area: true },
      });
    });

    return { success: true, message: 'Address updated successfully', data: address };
  }

  async deleteAddress(userId: number, publicId: string) {
    const existing = await this.prisma.address.findFirst({ where: { publicId, userId, isActive: true } });
    if (!existing) throw new NotFoundException({ message: 'Address not found', error_code: 'ADDRESS_NOT_FOUND' });
    await this.prisma.address.update({ where: { id: existing.id }, data: { isActive: false, isDefault: false } });
    return { success: true, message: 'Address deleted successfully' };
  }

  async adminCities() {
    const items = await this.prisma.city.findMany({
      include: { state: { include: { country: true } }, deliveryFee: true, _count: { select: { districts: true } } },
      orderBy: { nameAr: 'asc' },
    });
    return { success: true, message: 'Admin cities retrieved successfully', data: items };
  }

  async createCity(dto: UpsertCityDto) {
    const state = await this.defaultState(dto.stateId);
    const city = await this.prisma.city.create({
      data: {
        stateId: state.id,
        nameAr: dto.nameAr,
        nameEn: dto.nameEn ?? dto.nameAr,
        code: dto.code ?? this.cityCode(dto.nameAr),
        isActive: dto.isActive ?? true,
      },
    });
    return { success: true, message: 'City created successfully', data: city };
  }

  async updateCity(id: number, dto: UpsertCityDto) {
    const city = await this.prisma.city.update({
      where: { id },
      data: {
        stateId: dto.stateId,
        nameAr: dto.nameAr,
        nameEn: dto.nameEn,
        code: dto.code,
        isActive: dto.isActive,
      },
    }).catch(() => null);
    if (!city) throw new NotFoundException({ message: 'City not found', error_code: 'CITY_NOT_FOUND' });
    return { success: true, message: 'City updated successfully', data: city };
  }

  async createDistrict(cityId: number, dto: UpsertDistrictDto) {
    await this.requireCity(cityId);
    const district = await this.prisma.district.create({
      data: { cityId, nameAr: dto.nameAr, nameEn: dto.nameEn ?? dto.nameAr, isActive: dto.isActive ?? true },
    });
    return { success: true, message: 'District created successfully', data: district };
  }

  async updateDistrict(id: number, dto: UpsertDistrictDto) {
    const district = await this.prisma.district.update({
      where: { id },
      data: { nameAr: dto.nameAr, nameEn: dto.nameEn, isActive: dto.isActive },
    }).catch(() => null);
    if (!district) throw new NotFoundException({ message: 'District not found', error_code: 'DISTRICT_NOT_FOUND' });
    return { success: true, message: 'District updated successfully', data: district };
  }

  async upsertCityDeliveryFee(cityId: number, dto: UpsertCityDeliveryFeeDto) {
    await this.requireCity(cityId);
    const fee = await this.prisma.cityDeliveryFee.upsert({
      where: { cityId },
      update: {
        deliveryFee: dto.deliveryFee,
        currency: dto.currency ?? 'YER',
        isDeliveryAvailable: dto.isDeliveryAvailable ?? true,
        estimatedMinDays: dto.estimatedMinDays,
        estimatedMaxDays: dto.estimatedMaxDays,
      },
      create: {
        cityId,
        deliveryFee: dto.deliveryFee,
        currency: dto.currency ?? 'YER',
        isDeliveryAvailable: dto.isDeliveryAvailable ?? true,
        estimatedMinDays: dto.estimatedMinDays,
        estimatedMaxDays: dto.estimatedMaxDays,
      },
    });
    return { success: true, message: 'City delivery fee saved successfully', data: fee };
  }

  async adminDeliveryZones() {
    const zones = await this.prisma.deliveryZone.findMany({
      include: { city: true, district: true },
      orderBy: [{ city: { nameAr: 'asc' } }, { nameAr: 'asc' }],
    });
    return { success: true, message: 'Admin delivery zones retrieved successfully', data: zones };
  }

  async createDeliveryZone(dto: UpsertDeliveryZoneDto) {
    await this.validateLocation(dto.cityId, dto.districtId, undefined);
    const zone = await this.prisma.deliveryZone.create({
      data: {
        cityId: dto.cityId,
        districtId: dto.districtId,
        nameAr: dto.nameAr,
        nameEn: dto.nameEn ?? dto.nameAr,
        code: dto.code,
        deliveryFee: dto.deliveryFee,
        currency: dto.currency ?? 'YER',
        estimatedMinDays: dto.estimatedMinDays,
        estimatedMaxDays: dto.estimatedMaxDays,
        isActive: dto.isActive ?? true,
      },
    });
    return { success: true, message: 'Delivery zone created successfully', data: zone };
  }

  async updateDeliveryZone(id: number, dto: UpsertDeliveryZoneDto) {
    await this.validateLocation(dto.cityId, dto.districtId, undefined);
    const zone = await this.prisma.deliveryZone.update({
      where: { id },
      data: {
        cityId: dto.cityId,
        districtId: dto.districtId,
        nameAr: dto.nameAr,
        nameEn: dto.nameEn,
        code: dto.code,
        deliveryFee: dto.deliveryFee,
        currency: dto.currency ?? 'YER',
        estimatedMinDays: dto.estimatedMinDays,
        estimatedMaxDays: dto.estimatedMaxDays,
        isActive: dto.isActive,
      },
    }).catch(() => null);
    if (!zone) throw new NotFoundException({ message: 'Delivery zone not found', error_code: 'DELIVERY_ZONE_NOT_FOUND' });
    return { success: true, message: 'Delivery zone updated successfully', data: zone };
  }

  private async validateLocation(cityId: number, districtId?: number, areaId?: number) {
    await this.requireCity(cityId);
    if (districtId) {
      const district = await this.prisma.district.findFirst({ where: { id: districtId, cityId, isActive: true } });
      if (!district) throw new BadRequestException({ message: 'District does not belong to selected city', error_code: 'INVALID_DISTRICT' });
    }
    if (areaId) {
      if (!districtId) throw new BadRequestException({ message: 'Area requires a district', error_code: 'AREA_REQUIRES_DISTRICT' });
      const area = await this.prisma.area.findFirst({ where: { id: areaId, districtId, isActive: true } });
      if (!area) throw new BadRequestException({ message: 'Area does not belong to selected district', error_code: 'INVALID_AREA' });
    }
  }

  private async requireCity(cityId: number) {
    const city = await this.prisma.city.findFirst({ where: { id: cityId, isActive: true } });
    if (!city) throw new NotFoundException({ message: 'City not found', error_code: 'CITY_NOT_FOUND' });
    return city;
  }

  private async defaultState(stateId?: number) {
    if (stateId) {
      const state = await this.prisma.state.findFirst({ where: { id: stateId, isActive: true } });
      if (!state) throw new NotFoundException({ message: 'State not found', error_code: 'STATE_NOT_FOUND' });
      return state;
    }

    const country = await this.prisma.country.upsert({
      where: { isoCode: 'YE' },
      update: { isActive: true },
      create: { isoCode: 'YE', nameAr: 'اليمن', nameEn: 'Yemen', phoneCode: '+967' },
    });
    return this.prisma.state.upsert({
      where: { id: 1 },
      update: { countryId: country.id, isActive: true },
      create: { id: 1, countryId: country.id, nameAr: 'اليمن', nameEn: 'Yemen', code: 'YE-ALL' },
    });
  }

  private cityCode(name: string) {
    return name.trim().toLowerCase().replace(/\s+/g, '-').slice(0, 20) || 'city';
  }
}
