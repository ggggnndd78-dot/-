import { Injectable, InternalServerErrorException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer from 'nodemailer';
import { PrismaService } from '../../prisma/prisma.service';

export interface SendEmailInput {
  to: string;
  subject: string;
  text: string;
  html?: string;
  metadata?: Record<string, unknown>;
}

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  private async logEmail(input: SendEmailInput, status: 'SENT' | 'FAILED', provider: string, error?: unknown) {
    const userId = Number(input.metadata?.user_id ?? input.metadata?.userId ?? 0) || null;
    const errorText = error instanceof Error ? error.message : error ? String(error) : null;

    await (this.prisma as any).emailNotificationLog?.create({
      data: {
        userId,
        toEmail: input.to,
        subject: input.subject,
        body: input.text,
        status,
        provider,
        error: errorText,
        metadata: input.metadata ?? undefined,
        sentAt: status === 'SENT' ? new Date() : null,
      },
    }).catch(() => null);
  }

  private firstConfig(...keys: string[]) {
    for (const key of keys) {
      const value = this.config.get<string>(key);
      if (value != null && String(value).trim().length > 0) return String(value).trim();
    }
    return undefined;
  }

  private async sendViaSmtp(input: SendEmailInput) {
    // Supports both the project EMAIL_* names and the user's SMTP_* names.
    const host = this.firstConfig('EMAIL_SMTP_HOST', 'SMTP_HOST');
    const port = Number(this.firstConfig('EMAIL_SMTP_PORT', 'SMTP_PORT') ?? '587');
    const user = this.firstConfig('EMAIL_SMTP_USER', 'SMTP_USERNAME', 'SMTP_USER');
    const pass = this.firstConfig('EMAIL_SMTP_PASS', 'SMTP_PASSWORD', 'SMTP_PASS');
    const secure = (this.firstConfig('EMAIL_SMTP_SECURE', 'SMTP_SECURE') ?? 'false') === 'true';
    const from = this.firstConfig('EMAIL_FROM', 'SMTP_FROM') ?? 'no-reply@ghiyarak.com';

    if (!host || !user || !pass) {
      throw new InternalServerErrorException({
        message: 'SMTP email provider is not configured',
        error_code: 'EMAIL_SMTP_NOT_CONFIGURED',
      });
    }

    const transporter = nodemailer.createTransport({ host, port, secure, auth: { user, pass } });
    await transporter.sendMail({ from, to: input.to, subject: input.subject, text: input.text, html: input.html });
    return { delivered: true, provider: 'smtp' };
  }

  private async sendViaHttpApi(input: SendEmailInput) {
    const providerUrl = this.config.get<string>('EMAIL_API_URL')?.trim();
    const providerKey = this.config.get<string>('EMAIL_API_KEY')?.trim();
    const from = this.config.get<string>('EMAIL_FROM', 'no-reply@ghiyarak.com');

    if (!providerUrl) {
      throw new InternalServerErrorException({
        message: 'HTTP email provider is not configured',
        error_code: 'EMAIL_HTTP_NOT_CONFIGURED',
      });
    }

    const response = await fetch(providerUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...(providerKey ? { Authorization: `Bearer ${providerKey}` } : {}) },
      body: JSON.stringify({ from, to: input.to, subject: input.subject, text: input.text, html: input.html, metadata: input.metadata ?? {} }),
    });

    if (!response.ok) {
      const body = await response.text().catch(() => '');
      this.logger.error(`Email HTTP provider failed: ${response.status} ${body}`);
      throw new InternalServerErrorException({ message: 'Failed to send email', error_code: 'EMAIL_SEND_FAILED' });
    }

    return { delivered: true, provider: 'http-api' };
  }

  async send(input: SendEmailInput) {
    const configuredProvider = this.config.get<string>('EMAIL_PROVIDER')?.trim();
    const hasSmtpConfig = !!this.firstConfig('EMAIL_SMTP_HOST', 'SMTP_HOST');
    const provider = (configuredProvider || (hasSmtpConfig ? 'SMTP' : 'CONSOLE')).toUpperCase();

    try {
      let result: { delivered: boolean; provider: string; dev_only?: boolean };

      if (provider === 'CONSOLE' || provider === 'DEV_CONSOLE' || provider === 'LOG_ONLY') {
        this.logger.warn(`[Ghiyarak][DEV_EMAIL] to=${input.to} subject="${input.subject}" text="${input.text}"`);
        result = { delivered: true, provider: 'console', dev_only: true };
      } else if (provider === 'SMTP') {
        result = await this.sendViaSmtp(input);
      } else if (provider === 'HTTP_API') {
        result = await this.sendViaHttpApi(input);
      } else {
        throw new InternalServerErrorException({
          message: 'Email provider is not configured for delivery',
          error_code: 'EMAIL_PROVIDER_NOT_CONFIGURED',
        });
      }

      await this.logEmail(input, 'SENT', result.provider);
      return result;
    } catch (error) {
      await this.logEmail(input, 'FAILED', provider.toLowerCase(), error);
      throw error;
    }
  }
}
