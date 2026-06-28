import { IsArray, IsBoolean, IsEmail, IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateAdminUserDto {
  @IsString()
  @MaxLength(30)
  phone!: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  displayName?: string;

  @IsOptional()
  @IsIn(['ACTIVE', 'BLOCKED'])
  status?: 'ACTIVE' | 'BLOCKED';

  @IsOptional()
  @IsIn(['ar', 'en'])
  locale?: 'ar' | 'en';

  @IsOptional()
  @IsArray()
  roleCodes?: string[];
}

export class UpdateAdminUserDto {
  @IsOptional()
  @IsString()
  @MaxLength(30)
  phone?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  displayName?: string;

  @IsOptional()
  @IsIn(['ACTIVE', 'BLOCKED'])
  status?: 'ACTIVE' | 'BLOCKED';

  @IsOptional()
  @IsIn(['ar', 'en'])
  locale?: 'ar' | 'en';

  @IsOptional()
  @IsArray()
  roleCodes?: string[];
}

export class UpdateUserStatusDto {
  @IsIn(['ACTIVE', 'BLOCKED'])
  status!: 'ACTIVE' | 'BLOCKED';
}

export class UpsertSystemSettingDto {
  @IsOptional()
  value?: unknown;

  @IsOptional()
  @IsString()
  valueText?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsOptional()
  @IsBoolean()
  isPublic?: boolean;
}


export class UpdateAdminLocaleDto {
  @IsIn(['ar', 'en'])
  locale!: 'ar' | 'en';
}

export class UpsertFeatureFlagDto {
  @IsBoolean()
  enabled!: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
}


export class UpsertTranslationEntryDto {
  @IsIn(['ar', 'en'])
  locale!: 'ar' | 'en';

  @IsString()
  @MaxLength(4000)
  value!: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  namespace?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  platform?: string;

  @IsOptional()
  @IsIn(['DRAFT', 'PUBLISHED'])
  status?: 'DRAFT' | 'PUBLISHED';
}


export class ResolveSystemFindingDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
