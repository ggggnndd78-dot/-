import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateBankAccountDto {
  @ApiProperty()
  @IsString()
  @MaxLength(120)
  bankName!: string;

  @ApiProperty()
  @IsString()
  @MaxLength(120)
  accountName!: string;

  @ApiProperty()
  @IsString()
  @MaxLength(50)
  accountNumber!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(64)
  iban?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isPrimary?: boolean;
}
