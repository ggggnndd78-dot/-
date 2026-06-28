import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';

@Injectable()
export class VehiclesService {
  constructor(private readonly prisma: PrismaService) {}

  private async assertVehicleLookup(makeId: number, modelId: number, yearValue: number, variantId?: number | null) {
    const model = await this.prisma.vehicleModel.findFirst({ where: { id: modelId, makeId, isActive: true } });
    if (!model) throw new BadRequestException({ message: 'الموديل لا يتبع هذه الماركة', error_code: 'INVALID_VEHICLE_MODEL' });
    if (variantId) {
      const variant = await this.prisma.vehicleVariant.findFirst({ where: { id: variantId, modelId, isActive: true } });
      if (!variant) throw new BadRequestException({ message: 'الفئة لا تتبع هذا الموديل', error_code: 'INVALID_VEHICLE_TRIM' });
      if (yearValue < variant.yearFrom || (variant.yearTo && yearValue > variant.yearTo)) {
        throw new BadRequestException({ message: 'سنة السيارة غير متوافقة مع الفئة المختارة', error_code: 'INVALID_VEHICLE_YEAR' });
      }
    }
  }

  async makes() {
    const data = await this.prisma.vehicleMake.findMany({ where: { isActive: true }, orderBy: { nameAr: 'asc' } });
    return { success: true, message: 'Vehicle makes retrieved successfully', data };
  }

  async models(makeId?: number) {
    const data = await this.prisma.vehicleModel.findMany({
      where: { isActive: true, ...(makeId ? { makeId } : {}) },
      orderBy: { nameAr: 'asc' },
    });
    return { success: true, message: 'Vehicle models retrieved successfully', data };
  }

  async years(modelId?: number) {
    const variants = await this.prisma.vehicleVariant.findMany({
      where: { isActive: true, ...(modelId ? { modelId } : {}) },
      select: { yearFrom: true, yearTo: true },
    });
    const currentYear = new Date().getFullYear() + 1;
    const years = new Set<number>();
    for (const variant of variants) {
      const from = variant.yearFrom;
      const to = variant.yearTo ?? currentYear;
      for (let year = from; year <= to; year += 1) years.add(year);
    }
    const data = Array.from(years).sort((a, b) => b - a).map((year) => ({ id: year, year }));
    return { success: true, message: 'Vehicle years retrieved successfully', data };
  }

  async variants(modelId?: number, year?: number) {
    const data = await this.prisma.vehicleVariant.findMany({
      where: {
        isActive: true,
        ...(modelId ? { modelId } : {}),
        ...(year ? { yearFrom: { lte: year }, OR: [{ yearTo: null }, { yearTo: { gte: year } }] } : {}),
      },
      orderBy: [{ yearFrom: 'desc' }, { trimName: 'asc' }],
    });
    return { success: true, message: 'Vehicle variants retrieved successfully', data };
  }

  async engines(modelId?: number, year?: number) {
    const compatibilities = await (this.prisma as any).productCompatibility.findMany({
      where: {
        engineCode: { not: null },
        ...(modelId ? { modelId } : {}),
        ...(year ? { AND: [
          { OR: [{ yearFrom: null }, { yearFrom: { lte: year } }] },
          { OR: [{ yearTo: null }, { yearTo: { gte: year } }] },
        ] } : {}),
      },
      select: { engineCode: true },
      distinct: ['engineCode'],
      take: 50,
    }).catch(() => []);
    const data = compatibilities.map((item: any, index: number) => ({ id: index + 1, engine_code: item.engineCode }));
    return { success: true, message: 'Vehicle engines retrieved successfully', data };
  }

  async myVehicles(userId: number) {
    const data = await this.prisma.customerVehicle.findMany({
      where: { userId },
      include: { make: true, model: true, variant: true },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });

    return {
      success: true,
      message: 'Customer vehicles retrieved successfully',
      data: data.map((vehicle) => ({
        id: vehicle.publicId,
        make_id: vehicle.makeId,
        make_name: vehicle.make.nameAr,
        model_id: vehicle.modelId,
        model_name: vehicle.model.nameAr,
        variant_id: vehicle.variantId,
        variant_name: vehicle.variant?.trimName,
        nickname: vehicle.nickname,
        year_value: vehicle.yearValue,
        is_default: vehicle.isDefault,
      })),
    };
  }

  async create(userId: number, dto: CreateVehicleDto) {
    await this.assertVehicleLookup(dto.makeId, dto.modelId, dto.yearValue, dto.variantId);

    if (dto.isDefault) {
      await this.prisma.customerVehicle.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    }

    const existingCount = await this.prisma.customerVehicle.count({ where: { userId } });

    const created = await this.prisma.customerVehicle.create({
      data: {
        userId,
        makeId: dto.makeId,
        modelId: dto.modelId,
        variantId: dto.variantId,
        nickname: dto.nickname,
        yearValue: dto.yearValue,
        isDefault: dto.isDefault ?? existingCount === 0,
      },
      include: { make: true, model: true, variant: true },
    });

    return {
      success: true,
      message: 'Vehicle created successfully',
      data: {
        id: created.publicId,
        make_name: created.make.nameAr,
        model_name: created.model.nameAr,
        variant_name: created.variant?.trimName,
        year_value: created.yearValue,
        is_default: created.isDefault,
      },
    };
  }

  async update(userId: number, publicId: string, dto: UpdateVehicleDto) {
    const vehicle = await this.prisma.customerVehicle.findFirst({
      where: { publicId, userId },
    });
    if (!vehicle) throw new NotFoundException('Vehicle not found');

    await this.assertVehicleLookup(
      dto.makeId ?? vehicle.makeId,
      dto.modelId ?? vehicle.modelId,
      dto.yearValue ?? vehicle.yearValue,
      dto.variantId ?? vehicle.variantId,
    );

    if (dto.isDefault) {
      await this.prisma.customerVehicle.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    }

    const updated = await this.prisma.customerVehicle.update({
      where: { id: vehicle.id },
      data: {
        makeId: dto.makeId ?? vehicle.makeId,
        modelId: dto.modelId ?? vehicle.modelId,
        variantId: dto.variantId ?? vehicle.variantId,
        nickname: dto.nickname ?? vehicle.nickname,
        yearValue: dto.yearValue ?? vehicle.yearValue,
        isDefault: dto.isDefault ?? vehicle.isDefault,
      },
      include: { make: true, model: true, variant: true },
    });

    return {
      success: true,
      message: 'Vehicle updated successfully',
      data: {
        id: updated.publicId,
        make_name: updated.make.nameAr,
        model_name: updated.model.nameAr,
        variant_name: updated.variant?.trimName,
        year_value: updated.yearValue,
        is_default: updated.isDefault,
      },
    };
  }

  async remove(userId: number, publicId: string) {
    const vehicle = await this.prisma.customerVehicle.findFirst({ where: { publicId, userId } });
    if (!vehicle) throw new NotFoundException('Vehicle not found');

    await this.prisma.customerVehicle.delete({ where: { id: vehicle.id } });
    return { success: true, message: 'Vehicle deleted successfully', data: null };
  }

  async setDefault(userId: number, publicId: string) {
    const vehicle = await this.prisma.customerVehicle.findFirst({ where: { publicId, userId } });
    if (!vehicle) throw new NotFoundException('Vehicle not found');

    await this.prisma.customerVehicle.updateMany({ where: { userId }, data: { isDefault: false } });
    await this.prisma.customerVehicle.update({ where: { id: vehicle.id }, data: { isDefault: true } });

    return { success: true, message: 'Default vehicle updated successfully', data: null };
  }
}
