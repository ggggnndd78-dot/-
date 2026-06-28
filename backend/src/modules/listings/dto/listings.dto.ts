import { Type } from 'class-transformer';
import { IsBoolean, IsEnum, IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export enum DtoProductCondition {
  NEW = 'NEW',
  USED = 'USED',
  REFURBISHED = 'REFURBISHED',
}

export enum DtoListingStatus {
  DRAFT = 'DRAFT',
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  OUT_OF_STOCK = 'OUT_OF_STOCK',
  ARCHIVED = 'ARCHIVED',
}

export class ListingQueryDto {
  @IsOptional() @IsString() q?: string;
  @IsOptional() @Type(() => Number) @IsInt() categoryId?: number;
  @IsOptional() @Type(() => Number) @IsInt() productId?: number;
  @IsOptional() @Type(() => Number) @IsInt() partBrandId?: number;
  @IsOptional() @IsEnum(DtoProductCondition) condition?: DtoProductCondition;
  @IsOptional() @IsString() qualityType?: string;
  @IsOptional() @Type(() => Number) @IsInt() cityId?: number;
  @IsOptional() @Type(() => Number) @IsInt() organizationId?: number;
  @IsOptional() @Type(() => Number) @IsNumber() minPrice?: number;
  @IsOptional() @Type(() => Number) @IsNumber() maxPrice?: number;
  @IsOptional() @Type(() => Number) @IsInt() makeId?: number;
  @IsOptional() @Type(() => Number) @IsInt() modelId?: number;
  @IsOptional() @Type(() => Number) @IsInt() year?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) limit?: number;
}

export class CreateListingDto {
  @Type(() => Number) @IsInt() productId!: number;
  @IsOptional() @Type(() => Number) @IsInt() organizationId?: number;
  @IsOptional() @IsString() organizationPublicId?: string;
  @IsOptional() @Type(() => Number) @IsInt() branchId?: number;
  @IsOptional() @Type(() => Number) @IsInt() cityId?: number;
  @IsString() title!: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsEnum(DtoProductCondition) condition?: DtoProductCondition;
  @IsOptional() @IsString() qualityType?: string;
  @Type(() => Number) @IsNumber() @Min(0) unitPrice!: number;
  @IsOptional() @Type(() => Number) @IsNumber() @Min(0) salePrice?: number;
  @IsOptional() @IsString() currency?: string;
  @Type(() => Number) @IsInt() @Min(0) availableQuantity!: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) minOrderQuantity?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) warrantyDays?: number;
  @IsOptional() @Type(() => Boolean) @IsBoolean() supportsPickup?: boolean;
  @IsOptional() @Type(() => Boolean) @IsBoolean() supportsDelivery?: boolean;
}

export class UpdateListingDto {
  @IsOptional() @IsString() title?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsEnum(DtoProductCondition) condition?: DtoProductCondition;
  @IsOptional() @IsString() qualityType?: string;
  @IsOptional() @Type(() => Number) @IsNumber() @Min(0) unitPrice?: number;
  @IsOptional() @Type(() => Number) @IsNumber() @Min(0) salePrice?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) availableQuantity?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) minOrderQuantity?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) warrantyDays?: number;
  @IsOptional() @Type(() => Boolean) @IsBoolean() supportsPickup?: boolean;
  @IsOptional() @Type(() => Boolean) @IsBoolean() supportsDelivery?: boolean;
}

export class UpdateListingStatusDto {
  @IsEnum(DtoListingStatus) status!: DtoListingStatus;
}
