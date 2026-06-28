import { IsArray, IsBoolean, IsEnum, IsInt, IsNumber, IsOptional, IsPositive, IsString, MaxLength, Min } from 'class-validator';

export class WalletTopUpDto {
  @IsNumber()
  @IsPositive()
  amount!: number;

  @IsOptional()
  @IsString()
  @MaxLength(3)
  currency?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  externalReference?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  receiptUrl?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;

  @IsOptional()
  @IsString()
  @MaxLength(180)
  idempotencyKey?: string;
}

export class WalletAdjustmentDto {
  @IsInt()
  userId!: number;

  @IsNumber()
  @IsPositive()
  amount!: number;

  @IsEnum(['CREDIT', 'DEBIT'])
  direction!: 'CREDIT' | 'DEBIT';

  @IsOptional()
  @IsString()
  @MaxLength(3)
  currency?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;

  @IsOptional()
  @IsString()
  @MaxLength(180)
  idempotencyKey?: string;
}

export class RedeemPointsDto {
  @IsInt()
  @Min(100)
  points!: number;

  @IsOptional()
  @IsString()
  @MaxLength(180)
  idempotencyKey?: string;
}

export class CreateCouponDto {
  @IsString()
  @MaxLength(40)
  code!: string;

  @IsString()
  @MaxLength(160)
  titleAr!: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  titleEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsEnum(['PERCENTAGE', 'FIXED_AMOUNT', 'FREE_DELIVERY'])
  discountType!: 'PERCENTAGE' | 'FIXED_AMOUNT' | 'FREE_DELIVERY';

  @IsNumber()
  @Min(0)
  discountValue!: number;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  maxDiscountAmount?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  minOrderAmount?: number;

  @IsOptional()
  @IsEnum(['MARKETPLACE', 'WORKSHOP', 'ALL'])
  scope?: 'MARKETPLACE' | 'WORKSHOP' | 'ALL';

  @IsOptional()
  @IsBoolean()
  stackable?: boolean;

  @IsOptional()
  @IsArray()
  eligibleCategoryIds?: number[];

  @IsOptional()
  @IsArray()
  eligibleServiceIds?: number[];

  @IsOptional()
  @IsArray()
  eligibleMerchantIds?: number[];

  @IsOptional()
  @IsArray()
  eligibleWorkshopIds?: number[];

  @IsOptional()
  @IsInt()
  @Min(1)
  usageLimit?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  perUserLimit?: number;

  @IsOptional()
  @IsString()
  startsAt?: string;

  @IsOptional()
  @IsString()
  endsAt?: string;

  @IsOptional()
  @IsEnum(['DRAFT', 'ACTIVE', 'PAUSED', 'EXPIRED'])
  status?: 'DRAFT' | 'ACTIVE' | 'PAUSED' | 'EXPIRED';
}

export class UpdateCouponStatusDto {
  @IsEnum(['DRAFT', 'ACTIVE', 'PAUSED', 'EXPIRED'])
  status!: 'DRAFT' | 'ACTIVE' | 'PAUSED' | 'EXPIRED';
}

export class ValidateCouponDto {
  @IsString()
  @MaxLength(40)
  code!: string;

  @IsNumber()
  @Min(0)
  amount!: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  deliveryFee?: number;

  @IsOptional()
  @IsEnum(['MARKETPLACE', 'WORKSHOP', 'ALL'])
  scope?: 'MARKETPLACE' | 'WORKSHOP' | 'ALL';

  @IsOptional()
  @IsInt()
  merchantId?: number;

  @IsOptional()
  @IsInt()
  workshopId?: number;

  @IsOptional()
  @IsArray()
  categoryIds?: number[];

  @IsOptional()
  @IsArray()
  serviceIds?: number[];
}

export class RedeemCouponDto {
  @IsString()
  @MaxLength(40)
  code!: string;

  @IsOptional()
  @IsString()
  @MaxLength(180)
  idempotencyKey?: string;
}

export class AwardPointsDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  points?: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;

  @IsOptional()
  @IsString()
  @MaxLength(180)
  idempotencyKey?: string;
}

export class ReversePointsDto {
  @IsInt()
  @Min(1)
  points!: number;

  @IsString()
  @MaxLength(500)
  reason!: string;

  @IsOptional()
  @IsString()
  @MaxLength(180)
  idempotencyKey?: string;
}

export class ApplyReferralDto {
  @IsString()
  @MaxLength(40)
  code!: string;
}

export class QualifyReferralDto {
  @IsOptional()
  @IsInt()
  orderId?: number;

  @IsOptional()
  @IsInt()
  serviceOrderId?: number;

  @IsOptional()
  @IsInt()
  referrerPoints?: number;

  @IsOptional()
  @IsInt()
  referredPoints?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  walletAmount?: number;

  @IsOptional()
  @IsString()
  @MaxLength(180)
  idempotencyKey?: string;
}

export class CreateRetentionCampaignDto {
  @IsString()
  @MaxLength(180)
  title!: string;

  @IsOptional()
  @IsEnum(['IN_APP', 'FCM'])
  channel?: 'IN_APP' | 'FCM';

  @IsEnum(['ALL_CUSTOMERS', 'BRONZE_CUSTOMERS', 'SILVER_CUSTOMERS', 'GOLD_CUSTOMERS', 'PLATINUM_CUSTOMERS', 'INACTIVE_CUSTOMERS'])
  audienceType!: 'ALL_CUSTOMERS' | 'BRONZE_CUSTOMERS' | 'SILVER_CUSTOMERS' | 'GOLD_CUSTOMERS' | 'PLATINUM_CUSTOMERS' | 'INACTIVE_CUSTOMERS';

  @IsString()
  @MaxLength(160)
  messageTitle!: string;

  @IsString()
  @MaxLength(500)
  messageBody!: string;

  @IsOptional()
  @IsInt()
  couponId?: number;

  @IsOptional()
  @IsString()
  startsAt?: string;

  @IsOptional()
  @IsString()
  endsAt?: string;
}
