import { Type } from 'class-transformer';
import { IsArray, IsEnum, IsInt, IsOptional, IsString, Length, Max, Min, ValidateNested } from 'class-validator';

export enum DtoReviewTargetType {
  PRODUCT = 'PRODUCT',
  MERCHANT = 'MERCHANT',
  WORKSHOP = 'WORKSHOP',
  SERVICE = 'SERVICE',
}

export enum DtoReviewStatus {
  PENDING = 'PENDING',
  PUBLISHED = 'PUBLISHED',
  HIDDEN = 'HIDDEN',
  REJECTED = 'REJECTED',
}

export enum DtoReviewModerationActionType {
  REPORTED = 'REPORTED',
  HIDDEN = 'HIDDEN',
  RESTORED = 'RESTORED',
  REJECTED = 'REJECTED',
}

export class ReviewMediaInputDto {
  @IsString()
  @Length(5, 500)
  mediaUrl!: string;

  @IsOptional()
  @IsString()
  @Length(1, 30)
  mediaType?: string;
}

export class BaseReviewDto {
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  @Length(1, 160)
  title?: string;

  @IsOptional()
  @IsString()
  @Length(1, 4000)
  body?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ReviewMediaInputDto)
  media?: ReviewMediaInputDto[];
}

export class CreateProductReviewDto extends BaseReviewDto {
  @IsInt()
  productId!: number;

  @IsInt()
  orderId!: number;
}

export class CreateMerchantReviewDto extends BaseReviewDto {
  @IsInt()
  organizationId!: number;

  @IsInt()
  orderId!: number;
}

export class CreateWorkshopReviewDto extends BaseReviewDto {
  @IsInt()
  organizationId!: number;

  @IsInt()
  serviceOrderId!: number;
}

export class CreateServiceReviewDto extends BaseReviewDto {
  @IsInt()
  serviceOrderId!: number;
}

export class ReplyToReviewDto {
  @IsEnum(DtoReviewTargetType)
  targetType!: DtoReviewTargetType;

  @IsInt()
  reviewId!: number;

  @IsInt()
  organizationId!: number;

  @IsString()
  @Length(2, 3000)
  body!: string;
}

export class ModerateReviewDto {
  @IsEnum(DtoReviewTargetType)
  targetType!: DtoReviewTargetType;

  @IsInt()
  reviewId!: number;

  @IsEnum(DtoReviewModerationActionType)
  action!: DtoReviewModerationActionType;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  reason?: string;
}

export class ReportReviewDto {
  @IsEnum(DtoReviewTargetType)
  targetType!: DtoReviewTargetType;

  @IsInt()
  reviewId!: number;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  reason?: string;
}
