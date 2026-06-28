import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsOptional } from 'class-validator';

export class UpdateLocationDto {
  @ApiProperty()
  @IsInt()
  cityId!: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  districtId?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  areaId?: number;
}
