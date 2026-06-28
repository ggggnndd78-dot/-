import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../../prisma/prisma.module';
import { EmailService } from './email.service';
import { SmsService } from './sms.service';
import { OtpDeliveryService } from './otp-delivery.service';

@Module({
  imports: [ConfigModule, PrismaModule],
  providers: [EmailService, SmsService, OtpDeliveryService],
  exports: [EmailService, SmsService, OtpDeliveryService],
})
export class CommunicationsModule {}
