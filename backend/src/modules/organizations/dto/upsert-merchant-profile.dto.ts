import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class UpsertMerchantProfileDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(50)
  businessCategoryCode?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(10080)
  averagePreparationMinutes?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  warrantyPolicyText?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  returnPolicyText?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  deliveryPolicyText?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  minOrderAmount?: number;
}
