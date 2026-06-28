import { ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdateEmployeePermissionsDto {
  @ApiPropertyOptional({ example: ['merchant.products.manage'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  permissions?: string[];

  @ApiPropertyOptional({ example: false })
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
