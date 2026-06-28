import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsNumber, IsOptional, IsString, Length, MaxLength, Min } from 'class-validator';

export class CreateAddressDto {
  @IsString()
  @Length(2, 60)
  label!: string;

  @IsString()
  @Length(2, 120)
  recipientName!: string;

  @IsString()
  @Length(7, 20)
  phone!: string;

  @Type(() => Number)
  @IsInt()
  cityId!: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  districtId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  areaId?: number;

  @IsString()
  @Length(5, 255)
  addressLine1!: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  addressLine2?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  longitude?: number;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class UpdateAddressDto {
  @IsOptional()
  @IsString()
  @Length(2, 60)
  label?: string;

  @IsOptional()
  @IsString()
  @Length(2, 120)
  recipientName?: string;

  @IsOptional()
  @IsString()
  @Length(7, 20)
  phone?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  cityId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  districtId?: number | null;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  areaId?: number | null;

  @IsOptional()
  @IsString()
  @Length(5, 255)
  addressLine1?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  addressLine2?: string | null;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  latitude?: number | null;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  longitude?: number | null;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class UpsertCityDto {
  @IsString()
  @Length(2, 120)
  nameAr!: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  nameEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  code?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  stateId?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpsertDistrictDto {
  @IsString()
  @Length(2, 120)
  nameAr!: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  nameEn?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpsertCityDeliveryFeeDto {
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  deliveryFee!: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsOptional()
  @IsBoolean()
  isDeliveryAvailable?: boolean;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  estimatedMinDays?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  estimatedMaxDays?: number;
}

export class UpsertDeliveryZoneDto {
  @Type(() => Number)
  @IsInt()
  cityId!: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  districtId?: number;

  @IsString()
  @Length(2, 120)
  nameAr!: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  nameEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  code?: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  deliveryFee!: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  estimatedMinDays?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  estimatedMaxDays?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
