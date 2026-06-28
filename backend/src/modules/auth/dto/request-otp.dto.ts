import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsIn, IsOptional, IsString, Length, ValidateIf } from 'class-validator';

export class RequestOtpDto {
  @ApiPropertyOptional({ example: '770000000', description: 'Yemeni phone number. Required when email is not provided.' })
  @ValidateIf((dto) => !dto.email)
  @IsString()
  @Length(9, 20)
  phone?: string;

  @ApiPropertyOptional({ example: 'customer@ghiyarak.com', description: 'Email address. Required when phone is not provided.' })
  @ValidateIf((dto) => !dto.phone)
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ enum: ['SMS', 'EMAIL'], example: 'SMS' })
  @IsOptional()
  @IsIn(['SMS', 'EMAIL'])
  channel?: 'SMS' | 'EMAIL';

  @ApiPropertyOptional({ enum: ['LOGIN', 'REGISTER', 'EMPLOYEE_INVITE', 'PASSWORD_RESET'], example: 'LOGIN' })
  @IsOptional()
  @IsIn(['LOGIN', 'REGISTER', 'EMPLOYEE_INVITE', 'PASSWORD_RESET'])
  purpose?: 'LOGIN' | 'REGISTER' | 'EMPLOYEE_INVITE' | 'PASSWORD_RESET';
}
