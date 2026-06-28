import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsEmail, IsIn, IsInt, IsNumber, IsOptional, IsString, Length, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { VerifyTrustedDeviceOtpDto } from './trusted-device.dto';

export class VerificationDocumentUploadDto {
  @ApiProperty({ enum: ['NATIONAL_ID', 'PASSPORT', 'BANK_STATEMENT', 'COMMERCIAL_REGISTRATION'], example: 'NATIONAL_ID' })
  @IsIn(['NATIONAL_ID', 'PASSPORT', 'BANK_STATEMENT', 'COMMERCIAL_REGISTRATION'])
  documentType!: 'NATIONAL_ID' | 'PASSPORT' | 'BANK_STATEMENT' | 'COMMERCIAL_REGISTRATION';

  @ApiPropertyOptional({ enum: ['FRONT', 'BACK', 'MAIN'], example: 'FRONT' })
  @IsOptional()
  @IsIn(['FRONT', 'BACK', 'MAIN'])
  side?: 'FRONT' | 'BACK' | 'MAIN';

  @ApiProperty({ example: 'national-id-front.jpg' })
  @IsString()
  @Length(3, 255)
  fileName!: string;

  @ApiProperty({ example: 'image/jpeg' })
  @IsString()
  @Length(5, 120)
  mimeType!: string;

  @ApiProperty({ description: 'Base64 file content without data URL prefix.' })
  @IsString()
  @Length(20)
  fileContentBase64!: string;

  @ApiPropertyOptional({ example: 120433 })
  @IsOptional()
  @IsInt()
  fileSizeBytes?: number;
}

export class RegisterCustomerDto extends VerifyTrustedDeviceOtpDto {
  @ApiPropertyOptional({ example: 'customer@ghiyarak.com' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: 'أحمد محمد' })
  @IsOptional()
  @IsString()
  @Length(2, 120)
  fullName?: string;
}

export class RegisterBusinessDto extends VerifyTrustedDeviceOtpDto {
  @ApiProperty({ enum: ['MERCHANT', 'WORKSHOP', 'WAREHOUSE'], example: 'MERCHANT' })
  @IsIn(['MERCHANT', 'WORKSHOP', 'WAREHOUSE'])
  accountType!: 'MERCHANT' | 'WORKSHOP' | 'WAREHOUSE';

  @ApiProperty({ example: 'أحمد محمد' })
  @IsString()
  @Length(2, 120)
  fullName!: string;

  @ApiProperty({ example: 'owner@business.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 1 })
  @IsNumber()
  cityId!: number;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsNumber()
  districtId?: number;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsNumber()
  areaId?: number;

  @ApiPropertyOptional({ example: 15.3694 })
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional({ example: 44.1910 })
  @IsOptional()
  @IsNumber()
  longitude?: number;

  @ApiPropertyOptional({ example: 'https://www.google.com/maps/search/?api=1&query=15.3694000,44.1910000' })
  @IsOptional()
  @IsString()
  @Length(10, 500)
  mapUrl?: string;

  @ApiProperty({ example: 'شارع الستين، صنعاء' })
  @IsString()
  @Length(3, 255)
  address!: string;

  @ApiProperty({ example: 'متجر غيارك' })
  @IsString()
  @Length(2, 150)
  businessName!: string;

  @ApiPropertyOptional({ example: 'الفرع الرئيسي' })
  @IsOptional()
  @IsString()
  @Length(2, 150)
  branchName?: string;

  @ApiProperty({ example: 'متجر متخصص في قطع غيار السيارات الأصلية.' })
  @IsString()
  @Length(10, 1000)
  businessDescription!: string;

  @ApiPropertyOptional({ type: [VerificationDocumentUploadDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => VerificationDocumentUploadDto)
  documents?: VerificationDocumentUploadDto[];
}
