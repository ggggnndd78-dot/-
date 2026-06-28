
import { IsBoolean, IsIn, IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateQaRunDto {
  @IsString()
  @MaxLength(180)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  scope?: string;

  @IsOptional()
  @IsIn(['LOCAL', 'STAGING', 'PRODUCTION'])
  environment?: 'LOCAL' | 'STAGING' | 'PRODUCTION';
}

export class RecordQaResultDto {
  @IsString()
  @MaxLength(120)
  suite!: string;

  @IsString()
  @MaxLength(160)
  caseKey!: string;

  @IsString()
  @MaxLength(240)
  caseTitle!: string;

  @IsIn(['PASSED', 'FAILED', 'SKIPPED', 'BLOCKED'])
  status!: 'PASSED' | 'FAILED' | 'SKIPPED' | 'BLOCKED';

  @IsOptional()
  @IsInt()
  @Min(0)
  durationMs?: number;

  @IsOptional()
  @IsString()
  errorMessage?: string;
}

export class UpdateReleaseChecklistItemDto {
  @IsIn(['PENDING', 'PASSED', 'FAILED', 'WAIVED'])
  status!: 'PENDING' | 'PASSED' | 'FAILED' | 'WAIVED';

  @IsOptional()
  @IsString()
  @MaxLength(500)
  evidenceUrl?: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class CreateDeploymentRunDto {
  @IsIn(['LOCAL', 'STAGING', 'PRODUCTION'])
  environment!: 'LOCAL' | 'STAGING' | 'PRODUCTION';

  @IsString()
  @MaxLength(80)
  version!: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  commitSha?: string;

  @IsOptional()
  @IsString()
  releaseNotes?: string;
}

export class CompleteDeploymentRunDto {
  @IsIn(['PASSED', 'FAILED', 'ROLLED_BACK'])
  status!: 'PASSED' | 'FAILED' | 'ROLLED_BACK';
}
