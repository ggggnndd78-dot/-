import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateVehicleDto {
  @ApiProperty()
  @IsInt()
  makeId!: number;

  @ApiProperty()
  @IsInt()
  modelId!: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  variantId?: number;

  @ApiProperty()
  @IsInt()
  @Min(1980)
  @Max(2035)
  yearValue!: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  nickname?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}
