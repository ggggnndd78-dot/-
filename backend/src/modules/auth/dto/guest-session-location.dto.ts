import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString } from 'class-validator';

export class GuestSessionLocationDto {
  @ApiProperty()
  @IsString()
  guestToken!: string;

  @ApiProperty()
  @Type(() => Number)
  @IsInt()
  cityId!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  districtId?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  areaId?: number;
}
