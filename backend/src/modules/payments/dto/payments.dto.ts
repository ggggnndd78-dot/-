import { IsEnum, IsInt, IsNumber, IsOptional, IsString, Length, Min } from 'class-validator';

export enum DtoPaymentMethod {
  CASH_ON_DELIVERY = 'CASH_ON_DELIVERY',
  CASH_ON_PICKUP = 'CASH_ON_PICKUP',
  BANK_TRANSFER = 'BANK_TRANSFER',
  WALLET = 'WALLET',
  LOCAL_WALLET = 'LOCAL_WALLET',
  PAYMENT_GATEWAY = 'PAYMENT_GATEWAY',
}

export enum DtoPaymentProvider {
  MANUAL = 'MANUAL',
  CASH = 'CASH',
  BANK_TRANSFER = 'BANK_TRANSFER',
  WALLET = 'WALLET',
  LOCAL_WALLET = 'LOCAL_WALLET',
  EXTERNAL = 'EXTERNAL',
  PAYMENT_GATEWAY = 'PAYMENT_GATEWAY',
}

export class CreateOrderPaymentDto {
  @IsOptional()
  @IsEnum(DtoPaymentMethod)
  paymentMethod?: DtoPaymentMethod;

  @IsOptional()
  @IsString()
  @Length(1, 60)
  paymentMethodCode?: string;

  @IsOptional()
  @IsEnum(DtoPaymentProvider)
  provider?: DtoPaymentProvider;

  @IsOptional()
  @IsString()
  @Length(1, 120)
  externalReference?: string;

  @IsOptional()
  @IsString()
  @Length(1, 120)
  idempotencyKey?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  receiptUrl?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;
}

export class CreateManualServicePaymentDto {
  @IsNumber()
  @Min(1)
  amount!: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsOptional()
  @IsEnum(DtoPaymentMethod)
  paymentMethod?: DtoPaymentMethod;

  @IsOptional()
  @IsString()
  @Length(1, 60)
  paymentMethodCode?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;
}

export class UploadPaymentProofDto {
  @IsString()
  @Length(5, 500)
  fileUrl!: string;

  @IsOptional()
  @IsString()
  @Length(0, 255)
  fileName?: string;

  @IsOptional()
  @IsString()
  @Length(0, 80)
  fileType?: string;

  @IsOptional()
  @IsNumber()
  @Min(1)
  amount?: number;

  @IsOptional()
  @IsString()
  @Length(0, 120)
  referenceNumber?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;
}

export class ReviewPaymentProofDto {
  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;
}

export class MarkPaymentDto {
  @IsOptional()
  @IsString()
  @Length(0, 120)
  externalReference?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  receiptUrl?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;
}

export class PaymentWebhookDto {
  @IsString()
  @Length(1, 180)
  idempotencyKey!: string;

  @IsString()
  @Length(1, 100)
  eventType!: string;

  @IsOptional()
  @IsString()
  @Length(0, 140)
  providerReference?: string;

  @IsOptional()
  @IsString()
  @Length(0, 80)
  paymentReference?: string;

  @IsOptional()
  @IsString()
  @Length(0, 40)
  status?: string;

  @IsOptional()
  @IsNumber()
  @Min(1)
  amount?: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsOptional()
  payload?: Record<string, unknown>;
}

export class CreateRefundDto {
  @IsOptional()
  @IsInt()
  paymentId?: number;

  @IsOptional()
  @IsInt()
  orderId?: number;

  @IsOptional()
  @IsInt()
  serviceOrderId?: number;

  @IsNumber()
  @Min(1)
  amount!: number;

  @IsString()
  @Length(5, 500)
  reason!: string;
}

export class ReviewRefundDto {
  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;

  @IsOptional()
  @IsString()
  @Length(0, 140)
  providerReference?: string;
}

export class CreateSettlementDto {
  @IsInt()
  organizationId!: number;

  @IsNumber()
  @Min(1)
  amount!: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsString()
  @Length(10, 10)
  periodStart!: string;

  @IsString()
  @Length(10, 10)
  periodEnd!: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  notes?: string;
}
