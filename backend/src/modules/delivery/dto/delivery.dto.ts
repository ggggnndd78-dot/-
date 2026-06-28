import { IsBoolean, IsDateString, IsEnum, IsInt, IsNumber, IsOptional, IsString, Length, Min } from 'class-validator';

export enum DtoShipmentStatus {
  PENDING = 'PENDING',
  READY_FOR_PICKUP = 'READY_FOR_PICKUP',
  PICKED_UP = 'PICKED_UP',
  IN_TRANSIT = 'IN_TRANSIT',
  OUT_FOR_DELIVERY = 'OUT_FOR_DELIVERY',
  DELIVERED = 'DELIVERED',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED',
  RETURNED = 'RETURNED',
}

export enum DtoDriverType {
  INTERNAL = 'INTERNAL',
  EXTERNAL = 'EXTERNAL',
}

export enum DtoDriverStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  SUSPENDED = 'SUSPENDED',
}

export enum DtoDeliveryFeeScope {
  CITY = 'CITY',
  BRANCH = 'BRANCH',
  METHOD = 'METHOD',
}

export class CreateShipmentFromOrderDto {
  @IsOptional()
  @IsNumber()
  deliveryMethodId?: number;

  @IsOptional()
  @IsNumber()
  deliveryFeeId?: number;

  @IsOptional()
  @IsNumber()
  driverId?: number;

  @IsOptional()
  @IsNumber()
  shippingCompanyId?: number;

  @IsOptional()
  @IsString()
  @Length(0, 80)
  trackingNumber?: string;

  @IsOptional()
  @IsString()
  @Length(0, 120)
  externalShipmentNumber?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  externalTrackingUrl?: string;

  @IsOptional()
  @IsString()
  @Length(0, 120)
  courierName?: string;

  @IsOptional()
  @IsString()
  @Length(0, 120)
  recipientName?: string;

  @IsOptional()
  @IsString()
  @Length(0, 20)
  recipientPhone?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  deliveryAddress?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  deliveryFee?: number;

  @IsOptional()
  @IsDateString()
  estimatedDeliveryAt?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  notes?: string;
}

export class UpdateShipmentStatusDto {
  @IsEnum(DtoShipmentStatus)
  status!: DtoShipmentStatus;

  @IsOptional()
  @IsString()
  @Length(0, 180)
  locationText?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;
}

export class AssignShipmentDto {
  @IsOptional()
  @IsNumber()
  driverId?: number;

  @IsOptional()
  @IsNumber()
  shippingCompanyId?: number;

  @IsOptional()
  @IsString()
  @Length(0, 120)
  externalShipmentNumber?: string;

  @IsOptional()
  @IsString()
  @Length(0, 80)
  trackingNumber?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  externalTrackingUrl?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;
}

export class CreateDriverDto {
  @IsString()
  @Length(2, 140)
  fullName!: string;

  @IsOptional()
  @IsNumber()
  userId?: number;

  @IsOptional()
  @IsNumber()
  organizationId?: number;

  @IsOptional()
  @IsNumber()
  branchId?: number;

  @IsOptional()
  @IsString()
  @Length(0, 30)
  phone?: string;

  @IsOptional()
  @IsEnum(DtoDriverType)
  driverType?: DtoDriverType;

  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  @IsOptional()
  @IsString()
  @Length(0, 80)
  vehicleType?: string;

  @IsOptional()
  @IsString()
  @Length(0, 40)
  vehiclePlate?: string;

  @IsOptional()
  @IsNumber()
  currentCityId?: number;
}

export class UpdateDriverDto {
  @IsOptional()
  @IsString()
  @Length(2, 140)
  fullName?: string;

  @IsOptional()
  @IsString()
  @Length(0, 30)
  phone?: string;

  @IsOptional()
  @IsEnum(DtoDriverStatus)
  status?: DtoDriverStatus;

  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  @IsOptional()
  @IsString()
  @Length(0, 80)
  vehicleType?: string;

  @IsOptional()
  @IsString()
  @Length(0, 40)
  vehiclePlate?: string;

  @IsOptional()
  @IsNumber()
  currentCityId?: number;
}

export class CreateShippingCompanyDto {
  @IsString()
  @Length(2, 160)
  nameAr!: string;

  @IsOptional()
  @IsString()
  @Length(0, 160)
  nameEn?: string;

  @IsOptional()
  @IsString()
  @Length(0, 60)
  code?: string;

  @IsOptional()
  @IsNumber()
  organizationId?: number;

  @IsOptional()
  @IsNumber()
  cityId?: number;

  @IsOptional()
  @IsString()
  @Length(0, 30)
  phone?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  trackingUrlTemplate?: string;

  @IsOptional()
  @IsString()
  @Length(0, 80)
  integrationCode?: string;

  @IsOptional()
  @IsBoolean()
  supportsCod?: boolean;
}

export class UpdateShippingCompanyDto {
  @IsOptional()
  @IsString()
  @Length(2, 160)
  nameAr?: string;

  @IsOptional()
  @IsString()
  @Length(0, 160)
  nameEn?: string;

  @IsOptional()
  @IsNumber()
  cityId?: number;

  @IsOptional()
  @IsString()
  @Length(0, 30)
  phone?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  trackingUrlTemplate?: string;

  @IsOptional()
  @IsString()
  @Length(0, 80)
  integrationCode?: string;

  @IsOptional()
  @IsBoolean()
  supportsCod?: boolean;

  @IsOptional()
  @IsString()
  @Length(0, 20)
  status?: string;
}

export class UpsertDeliveryFeeDto {
  @IsOptional()
  @IsEnum(DtoDeliveryFeeScope)
  scope?: DtoDeliveryFeeScope;

  @IsOptional()
  @IsNumber()
  organizationId?: number;

  @IsOptional()
  @IsNumber()
  branchId?: number;

  @IsOptional()
  @IsNumber()
  cityId?: number;

  @IsOptional()
  @IsNumber()
  deliveryMethodId?: number;

  @IsOptional()
  @IsString()
  @Length(0, 140)
  label?: string;

  @IsNumber()
  @Min(0)
  baseFee!: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  minFee?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  maxFee?: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  estimatedMinDays?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  estimatedMaxDays?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
