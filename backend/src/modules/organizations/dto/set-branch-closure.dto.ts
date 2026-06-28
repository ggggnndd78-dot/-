import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsISO8601, IsOptional, IsString, Length, ValidateIf } from 'class-validator';

export class SetBranchClosureDto {
  @ApiProperty({ default: true })
  @IsBoolean()
  temporarilyClosed!: boolean;

  @ApiPropertyOptional({ example: '2026-07-01T12:00:00.000Z' })
  @ValidateIf((dto) => dto.temporarilyClosed === true)
  @IsOptional()
  @IsISO8601()
  closedUntil?: string;

  @ApiPropertyOptional({ example: 'إغلاق مؤقت للصيانة' })
  @ValidateIf((dto) => dto.temporarilyClosed === true)
  @IsOptional()
  @IsString()
  @Length(2, 500)
  closedReason?: string;
}
