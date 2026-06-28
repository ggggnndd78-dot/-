import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, Length } from 'class-validator';

export class UpdateEmployeeStatusDto {
  @ApiProperty({ enum: ['ACTIVE', 'SUSPENDED', 'REMOVED'] })
  @IsIn(['ACTIVE', 'SUSPENDED', 'REMOVED'])
  status!: 'ACTIVE' | 'SUSPENDED' | 'REMOVED';

  @IsOptional()
  @IsString()
  @Length(2, 500)
  reason?: string;
}
