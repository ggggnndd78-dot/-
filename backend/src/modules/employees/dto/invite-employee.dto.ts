import { ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsBoolean, IsEmail, IsOptional, IsString, Length, ValidateIf } from 'class-validator';

export class InviteEmployeeDto {
  @ApiPropertyOptional({ example: 'موظف المبيعات' })
  @IsOptional()
  @IsString()
  @Length(2, 140)
  displayName?: string;

  @ApiPropertyOptional({ example: 'employee@merchant.com' })
  @ValidateIf((dto) => !dto.phone)
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: '733333333' })
  @ValidateIf((dto) => !dto.email)
  @IsString()
  @Length(9, 20)
  phone?: string;

  @ApiPropertyOptional({ example: ['merchant.products.manage', 'merchant.orders.manage'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  permissions?: string[];

  @ApiPropertyOptional({ example: true, description: 'Allow access to all current and future organization branches.' })
  @IsOptional()
  @IsBoolean()
  allBranches?: boolean;

  @ApiPropertyOptional({ example: ['br_xxxxx'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(30)
  @IsString({ each: true })
  branchIds?: string[];
}
