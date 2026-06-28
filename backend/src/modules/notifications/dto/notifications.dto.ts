import { IsBoolean, IsEnum, IsOptional, IsString, Length } from 'class-validator';

export enum DtoDevicePlatform {
  ANDROID = 'ANDROID',
  IOS = 'IOS',
  WEB = 'WEB',
  WINDOWS = 'WINDOWS',
  MACOS = 'MACOS',
  LINUX = 'LINUX',
  UNKNOWN = 'UNKNOWN',
}

export class RegisterDeviceDto {
  @IsEnum(DtoDevicePlatform)
  platform!: DtoDevicePlatform;

  @IsString()
  @Length(20, 512)
  fcmToken!: string;

  @IsOptional()
  @IsString()
  @Length(0, 120)
  deviceName?: string;

  @IsOptional()
  @IsString()
  @Length(0, 40)
  appVersion?: string;
}

export class CreateNotificationDto {
  @IsString()
  @Length(2, 160)
  title!: string;

  @IsString()
  @Length(2, 500)
  body!: string;

  @IsOptional()
  @IsBoolean()
  sendEmail?: boolean;

  @IsOptional()
  @IsBoolean()
  sendPush?: boolean;
}
