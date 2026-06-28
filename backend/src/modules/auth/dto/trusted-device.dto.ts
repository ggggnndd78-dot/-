import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, Length } from 'class-validator';

export class DeviceContextDto {
  @ApiProperty({ example: 'android-unique-fingerprint-or-installation-id' })
  @IsString()
  @Length(12, 191)
  deviceFingerprint!: string;

  @ApiPropertyOptional({ example: 'Samsung Galaxy Note 10+' })
  @IsOptional()
  @IsString()
  @Length(2, 160)
  deviceName?: string;

  @ApiPropertyOptional({ enum: ['ANDROID', 'IOS', 'WEB', 'WINDOWS', 'MACOS', 'LINUX', 'UNKNOWN'], example: 'ANDROID' })
  @IsOptional()
  @IsIn(['ANDROID', 'IOS', 'WEB', 'WINDOWS', 'MACOS', 'LINUX', 'UNKNOWN'])
  platform?: string;

  @ApiPropertyOptional({ example: 'trusted-device-token-from-secure-storage' })
  @IsOptional()
  @IsString()
  @Length(20, 255)
  deviceToken?: string;
}

export class StartPhoneLoginDto extends DeviceContextDto {
  @ApiProperty({ example: '967770000000' })
  @IsString()
  @Length(9, 20)
  phone!: string;
}

export class VerifyTrustedDeviceOtpDto extends StartPhoneLoginDto {
  @ApiPropertyOptional({ enum: ['LOGIN', 'REGISTER', 'EMPLOYEE_INVITE'], example: 'LOGIN' })
  @IsOptional()
  @IsIn(['LOGIN', 'REGISTER', 'EMPLOYEE_INVITE'])
  purpose?: 'LOGIN' | 'REGISTER' | 'EMPLOYEE_INVITE';

  @ApiProperty({ example: '123456' })
  @IsString()
  @Length(4, 8)
  otpCode!: string;
}

export class ValidateSessionDto extends DeviceContextDto {
  @ApiPropertyOptional({ example: 'refresh-token' })
  @IsOptional()
  @IsString()
  refreshToken?: string;
}
