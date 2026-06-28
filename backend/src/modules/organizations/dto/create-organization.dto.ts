import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, Length } from 'class-validator';

export enum DtoOrganizationType {
  MERCHANT = 'MERCHANT',
  WORKSHOP = 'WORKSHOP',
  WAREHOUSE = 'WAREHOUSE',
}

export class CreateOrganizationDto {
  @ApiProperty({ enum: DtoOrganizationType })
  @IsEnum(DtoOrganizationType)
  organizationType!: DtoOrganizationType;

  @ApiProperty()
  @IsString()
  @Length(2, 150)
  displayName!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(2, 150)
  legalName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(9, 20)
  primaryPhone?: string;
}
