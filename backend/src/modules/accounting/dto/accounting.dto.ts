import { IsIn, IsInt, IsOptional, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class AccountingListQueryDto {
  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  sourceType?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  organizationId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  accountId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  take?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  skip?: number;
}

export class InitializeChartDto {
  @IsOptional()
  @IsString()
  note?: string;
}

export class ManualJournalLineDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  accountId!: number;

  @IsOptional()
  @Type(() => Number)
  organizationId?: number;

  @IsOptional()
  debitAmount?: number;

  @IsOptional()
  creditAmount?: number;

  @IsOptional()
  @IsString()
  memo?: string;
}
