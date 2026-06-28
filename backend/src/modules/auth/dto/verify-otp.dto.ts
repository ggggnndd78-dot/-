import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsIn, IsOptional, IsString, Length, ValidateIf } from 'class-validator';

export class VerifyOtpDto {
  @ApiPropertyOptional({ example: '770000000' })
  @ValidateIf((dto) => !dto.email)
  @IsString()
  @Length(9, 20)
  phone?: string;

  @ApiPropertyOptional({ example: 'customer@ghiyarak.com' })
  @ValidateIf((dto) => !dto.phone)
  @IsEmail()
  email?: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @Length(4, 8)
  otpCode!: string;

  @ApiPropertyOptional({ enum: ['LOGIN', 'REGISTER', 'EMPLOYEE_INVITE', 'PASSWORD_RESET'], example: 'LOGIN' })
  @IsOptional()
  @IsIn(['LOGIN', 'REGISTER', 'EMPLOYEE_INVITE', 'PASSWORD_RESET'])
  purpose?: 'LOGIN' | 'REGISTER' | 'EMPLOYEE_INVITE' | 'PASSWORD_RESET';

  @ApiPropertyOptional({ example: 'أحمد محمد' })
  @IsOptional()
  @IsString()
  @Length(2, 120)
  displayName?: string;
}
