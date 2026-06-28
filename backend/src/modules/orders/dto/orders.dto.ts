import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Length, Min } from 'class-validator';

export enum DtoFulfillmentMethod {
  PICKUP = 'PICKUP',
  DELIVERY = 'DELIVERY',
}

export enum DtoPaymentMethod {
  CASH_ON_DELIVERY = 'CASH_ON_DELIVERY',
  CASH_ON_PICKUP = 'CASH_ON_PICKUP',
  BANK_TRANSFER = 'BANK_TRANSFER',
  WALLET = 'WALLET',
}

export enum DtoOrderStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  PROCESSING = 'PROCESSING',
  READY_FOR_PICKUP = 'READY_FOR_PICKUP',
  OUT_FOR_DELIVERY = 'OUT_FOR_DELIVERY',
  DELIVERED = 'DELIVERED',
  CANCELLED = 'CANCELLED',
  RETURN_REQUESTED = 'RETURN_REQUESTED',
  REFUNDED = 'REFUNDED',
}

export class CheckoutPreviewDto {
  @IsOptional()
  @IsEnum(DtoFulfillmentMethod)
  fulfillmentMethod?: DtoFulfillmentMethod;

  @IsOptional()
  @IsString()
  @Length(1, 40)
  couponCode?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  addressId?: number;
}

export class CreateOrderDto {
  @IsOptional()
  @IsEnum(DtoFulfillmentMethod)
  fulfillmentMethod?: DtoFulfillmentMethod;

  @IsOptional()
  @IsEnum(DtoPaymentMethod)
  paymentMethod?: DtoPaymentMethod;

  @IsOptional()
  @IsString()
  @Length(1, 40)
  couponCode?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  addressId?: number;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  customerNote?: string;
}

export class UpdateOrderStatusDto {
  @IsEnum(DtoOrderStatus)
  status!: DtoOrderStatus;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;
}

export class CancelOrderDto {
  @IsOptional()
  @IsString()
  @Length(0, 500)
  reason?: string;
}
