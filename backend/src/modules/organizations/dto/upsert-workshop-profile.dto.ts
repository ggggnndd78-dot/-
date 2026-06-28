import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsInt, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class UpsertWorkshopProfileDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(50)
  serviceModeCode?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  acceptsDiagnosis?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  acceptsInstallation?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(500)
  capacityPerDay?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  supportsEmergencyService?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  defaultDiagnosisFee?: number;
}
