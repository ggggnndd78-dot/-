import { BadRequestException, Injectable } from '@nestjs/common';
import { I18nService } from '../../common/i18n/i18n.service';
import { EmailService } from './email.service';
import { SmsService } from './sms.service';

export type OtpDeliveryChannel = 'EMAIL' | 'SMS';

export interface OtpDeliveryInput {
  channel: OtpDeliveryChannel;
  target: string;
  code: string;
  purpose: string;
  locale?: string;
}

@Injectable()
export class OtpDeliveryService {
  constructor(
    private readonly email: EmailService,
    private readonly sms: SmsService,
    private readonly i18n: I18nService,
  ) {}

  async sendOtp(input: OtpDeliveryInput) {
    const locale = this.i18n.normalize(input.locale);
    const smsMessage = await this.i18n.tAsync('sms.otp.body', locale, { code: input.code });
    const emailSubject = await this.i18n.tAsync('email.otp.subject', locale);
    const emailMessage = await this.i18n.tAsync('email.otp.body', locale, { code: input.code });

    if (input.channel === 'EMAIL') {
      return this.email.send({
        to: input.target,
        subject: emailSubject,
        text: emailMessage,
        metadata: { purpose: input.purpose, locale },
      });
    }

    if (input.channel === 'SMS') {
      return this.sms.send({ to: input.target, message: smsMessage, metadata: { purpose: input.purpose, locale } });
    }

    throw new BadRequestException({ message: 'common.validation', error_code: 'UNSUPPORTED_OTP_CHANNEL' });
  }
}
