import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class AdminReviewVerificationDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;

  @ApiPropertyOptional({ enum: ['SMS', 'EMAIL', 'BOTH'], example: 'BOTH' })
  @IsOptional()
  @IsIn(['SMS', 'EMAIL', 'BOTH'])
  notificationChannel?: 'SMS' | 'EMAIL' | 'BOTH';
}
