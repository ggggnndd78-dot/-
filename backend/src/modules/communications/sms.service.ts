import { Injectable, InternalServerErrorException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface SendSmsInput {
  to: string;
  message: string;
  metadata?: Record<string, unknown>;
}

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);

  constructor(private readonly config: ConfigService) {}

  private normalizeYemeniDigits(input: string): string {
    let value = String(input || '').trim().replace(/[\s\-()]/g, '');
    if (value.startsWith('+')) value = value.substring(1);
    if (value.startsWith('00')) value = value.substring(2);
    value = value.replace(/\D/g, '');

    // Yemen international format without +: 9677XXXXXXXX
    if (/^9677\d{8}$/.test(value)) return value;

    // Yemen local with leading zero: 07XXXXXXXX
    if (/^07\d{8}$/.test(value)) return `967${value.substring(1)}`;

    // Yemen local without leading zero: 7XXXXXXXX
    if (/^7\d{8}$/.test(value)) return `967${value}`;

    // Keep other international numbers if needed later, for example Saudi: 9665XXXXXXXX.
    if (/^\d{10,15}$/.test(value)) return value;

    throw new InternalServerErrorException({
      message: 'Invalid SMS recipient phone format. Use a valid E.164 phone number such as +967781699203.',
      error_code: 'SMS_INVALID_RECIPIENT_PHONE',
    });
  }

  private normalizeRecipientWithPlus(input: string): string {
    return `+${this.normalizeYemeniDigits(input)}`;
  }

  private dataCodingFor(message: string): 'text' | 'unicode' {
    return /^[\x00-\x7F]*$/.test(message) ? 'text' : 'unicode';
  }

  private async parseResponse(response: Response) {
    const bodyText = await response.text().catch(() => '');
    if (!bodyText) return {};
    try {
      return JSON.parse(bodyText);
    } catch (_) {
      return bodyText;
    }
  }

  private extractOtpCode(message: string): string {
    const match = String(message || '').match(/\b\d{4,8}\b/);
    return match?.[0] ?? '000000';
  }

  private responseStatusIsFalse(body: unknown): boolean {
    return typeof body === 'object' && body !== null && 'status' in body && (body as { status?: unknown }).status === false;
  }

  private async sendViaCommPeakEventSend(input: SendSmsInput) {
    // Working integration verified from PowerShell on 2026-06-23:
    // POST https://textpeak-streams.commpeak.com/event_send/
    // event = login_otp
    // template variable = {code}
    const apiUrl = this.config
      .get<string>('COMMPEAK_SMS_EVENT_SEND_URL', 'https://textpeak-streams.commpeak.com/event_send/')
      .trim();
    const token = this.config.get<string>('COMMPEAK_SMS_TOKEN')?.trim();
    const sender = this.config.get<string>('COMMPEAK_SMS_SENDER', 'GLOBAL').trim();
    const eventKey = this.config.get<string>('COMMPEAK_SMS_EVENT_KEY', 'login_otp').trim();
    const recipient = this.normalizeYemeniDigits(input.to);
    const code = this.extractOtpCode(input.message);

    if (!token) {
      throw new InternalServerErrorException({
        message: 'CommPeak SMS token is not configured. Set COMMPEAK_SMS_TOKEN in backend/.env',
        error_code: 'COMMPEAK_SMS_TOKEN_REQUIRED',
      });
    }

    if (!eventKey) {
      throw new InternalServerErrorException({
        message: 'CommPeak event key is not configured. Set COMMPEAK_SMS_EVENT_KEY in backend/.env',
        error_code: 'COMMPEAK_SMS_EVENT_KEY_REQUIRED',
      });
    }

    const payload = {
      event: eventKey,
      recipients: [
        {
          internal_id: String(input.metadata?.internal_id ?? `ghiyarak-${Date.now()}`),
          recipient_phone: recipient,
          sender,
          template_variables: {
            code,
            first_name: String(input.metadata?.first_name ?? 'Ghiyarak'),
            last_name: String(input.metadata?.last_name ?? 'User'),
          },
        },
      ],
    };

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        Authorization: token,
      },
      body: JSON.stringify(payload),
    });

    const body = await this.parseResponse(response);

    if (!response.ok || this.responseStatusIsFalse(body)) {
      this.logger.error(`CommPeak event_send failed: ${response.status} ${JSON.stringify(body)}`);
      throw new InternalServerErrorException({
        message: 'Failed to send SMS through CommPeak event_send',
        error_code: 'COMMPEAK_EVENT_SEND_FAILED',
        provider_response: body,
      });
    }

    const messageUuid = Array.isArray((body as { messages?: unknown }).messages)
      ? ((body as { messages: Array<{ message_uuid?: string }> }).messages[0]?.message_uuid ?? null)
      : null;

    return {
      delivered: true,
      provider: 'commpeak_textpeak_event_send',
      sender,
      event: eventKey,
      recipient,
      message_uuid: messageUuid,
      response: body,
    };
  }

  private async sendViaCommPeakOtpAuth(input: SendSmsInput) {
    // Legacy/alternate CommPeak OTP endpoint. Keep it available for accounts that have a real SMS OTP stream.
    // The tested Ghiyarak stream currently uses event_send, so prefer SMS_PROVIDER=COMMPEAK_EVENT_SEND.
    const apiUrl = this.config
      .get<string>('COMMPEAK_SMS_AUTH_URL', 'https://textpeak-streams.commpeak.com/otp/auth/')
      .trim();
    const token = this.config.get<string>('COMMPEAK_SMS_TOKEN')?.trim();
    const sender = this.config.get<string>('COMMPEAK_SMS_SENDER', 'GLOBAL').trim();
    const recipient = this.normalizeYemeniDigits(input.to);
    const code = this.extractOtpCode(input.message);

    if (!token) {
      throw new InternalServerErrorException({
        message: 'CommPeak SMS token is not configured. Set COMMPEAK_SMS_TOKEN in backend/.env',
        error_code: 'COMMPEAK_SMS_TOKEN_REQUIRED',
      });
    }

    const payload = {
      recipient_phone: recipient,
      template_variables: {
        first_name: String(input.metadata?.first_name ?? 'Ghiyarak'),
        last_name: String(input.metadata?.last_name ?? 'User'),
        code,
      },
      sender,
    };

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        Authorization: token,
      },
      body: JSON.stringify(payload),
    });

    const body = await this.parseResponse(response);

    if (!response.ok || this.responseStatusIsFalse(body)) {
      this.logger.error(`CommPeak OTP auth failed: ${response.status} ${JSON.stringify(body)}`);
      throw new InternalServerErrorException({
        message: 'Failed to send SMS through CommPeak OTP auth',
        error_code: 'COMMPEAK_SMS_SEND_FAILED',
        provider_response: body,
      });
    }

    return {
      delivered: true,
      provider: 'commpeak_textpeak_otp_auth',
      sender,
      recipient,
      response: body,
    };
  }

  private async sendViaD7(input: SendSmsInput) {
    const token = this.config.get<string>('SMS_API_KEY')?.trim();
    const originator = this.config.get<string>('SMS_SENDER_ID', 'GHIYARAK').trim();
    const apiUrl = this.config.get<string>('SMS_API_URL', 'https://api.d7networks.com/messages/v1/send').trim();
    const recipient = this.normalizeRecipientWithPlus(input.to);

    if (!token) {
      throw new InternalServerErrorException({
        message: 'D7 SMS token is not configured. Set SMS_API_KEY in backend/.env',
        error_code: 'D7_SMS_TOKEN_REQUIRED',
      });
    }

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        messages: [
          {
            channel: 'sms',
            recipients: [recipient],
            content: input.message,
            msg_type: 'text',
            data_coding: this.dataCodingFor(input.message),
          },
        ],
        message_globals: {
          originator,
          tag: input.metadata?.purpose ?? 'ghiyarak_otp',
        },
      }),
    });

    const body = await this.parseResponse(response);

    if (!response.ok) {
      this.logger.error(`D7 SMS provider failed: ${response.status} ${JSON.stringify(body)}`);
      throw new InternalServerErrorException({
        message: 'Failed to send SMS through D7',
        error_code: 'D7_SMS_SEND_FAILED',
      });
    }

    return { delivered: true, provider: 'd7', recipient, response: body };
  }

  private async sendViaHttpApi(input: SendSmsInput) {
    const providerUrl = this.config.get<string>('SMS_API_URL')?.trim();
    const providerKey = this.config.get<string>('SMS_API_KEY')?.trim();
    const senderId = this.config.get<string>('SMS_SENDER_ID', 'GHIYARAK').trim();
    const recipient = this.normalizeRecipientWithPlus(input.to);

    if (!providerUrl) {
      throw new InternalServerErrorException({
        message: 'SMS HTTP provider is not configured',
        error_code: 'SMS_HTTP_NOT_CONFIGURED',
      });
    }

    const response = await fetch(providerUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(providerKey ? { Authorization: `Bearer ${providerKey}` } : {}),
      },
      body: JSON.stringify({
        to: recipient,
        message: input.message,
        sender_id: senderId,
        metadata: input.metadata ?? {},
      }),
    });

    const body = await this.parseResponse(response);

    if (!response.ok) {
      this.logger.error(`SMS HTTP provider failed: ${response.status} ${JSON.stringify(body)}`);
      throw new InternalServerErrorException({ message: 'Failed to send SMS', error_code: 'SMS_SEND_FAILED' });
    }

    return { delivered: true, provider: 'http-api', recipient, response: body };
  }

  async send(input: SendSmsInput) {
    const provider = this.config.get<string>('SMS_PROVIDER', 'COMMPEAK_EVENT_SEND').toUpperCase();

    if (provider === 'CONSOLE' || provider === 'DEV_CONSOLE' || provider === 'LOG_ONLY') {
      const recipient = this.normalizeRecipientWithPlus(input.to);
      this.logger.warn(`[Ghiyarak][DEV_OTP_SMS] to=${recipient} message="${input.message}"`);
      return {
        delivered: true,
        provider: 'console',
        recipient,
        dev_only: true,
        message: 'Development mode: OTP printed in backend console/log instead of sending real SMS.',
      };
    }

    // For Ghiyarak, COMMPEAK now means the verified TextPeak Streams event_send integration.
    // Legacy OTP auth is kept only behind COMMPEAK_OTP_AUTH to avoid accidentally using the old endpoint.
    if (
      provider === 'COMMPEAK'
      || provider === 'TEXTPEAK'
      || provider === 'COMMPEAK_EVENT_SEND'
      || provider === 'TEXTPEAK_EVENT_SEND'
      || provider === 'TEXTPEAK_STREAMS'
    ) {
      return this.sendViaCommPeakEventSend(input);
    }

    if (provider === 'COMMPEAK_OTP_AUTH' || provider === 'TEXTPEAK_OTP_AUTH') {
      return this.sendViaCommPeakOtpAuth(input);
    }

    if (provider === 'D7' || provider === 'D7_NETWORKS') {
      return this.sendViaD7(input);
    }

    if (provider === 'HTTP_API') {
      return this.sendViaHttpApi(input);
    }

    throw new InternalServerErrorException({
      message: `SMS provider ${provider} is not configured`,
      error_code: 'SMS_PROVIDER_NOT_CONFIGURED',
    });
  }
}
