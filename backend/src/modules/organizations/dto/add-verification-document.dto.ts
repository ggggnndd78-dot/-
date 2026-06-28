import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsIn, IsInt, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export enum DtoVerificationDocumentType {
  COMMERCIAL_REGISTRATION = 'COMMERCIAL_REGISTRATION',
  SHOP_GUARANTEE = 'SHOP_GUARANTEE',
  NATIONAL_ID = 'NATIONAL_ID',
  STORE_FRONT = 'STORE_FRONT',
  BANK_PROOF = 'BANK_PROOF',
  PASSPORT = 'PASSPORT',
  BANK_STATEMENT = 'BANK_STATEMENT',
  OTHER = 'OTHER',
}

export class AddVerificationDocumentDto {
  @ApiProperty({ enum: DtoVerificationDocumentType })
  @IsEnum(DtoVerificationDocumentType)
  documentType!: DtoVerificationDocumentType;

  @ApiProperty()
  @IsString()
  @MaxLength(255)
  fileName!: string;

  @ApiPropertyOptional({ description: 'External/object storage reference. Can be empty when fileContentBase64 is provided.' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  fileUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(120)
  mimeType?: string;

  @ApiPropertyOptional({ description: 'Base64 content for database-backed storage.' })
  @IsOptional()
  @IsString()
  @MinLength(20)
  fileContentBase64?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  fileSizeBytes?: number;

  @ApiPropertyOptional({ enum: ['FRONT', 'BACK', 'MAIN'] })
  @IsOptional()
  @IsIn(['FRONT', 'BACK', 'MAIN'])
  side?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
