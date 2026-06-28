import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Response, Request } from 'express';
import { I18nService } from '../i18n/i18n.service';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  constructor(
    private readonly configService?: ConfigService,
    private readonly i18n?: I18nService,
  ) {}

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const locale = this.i18n?.fromRequest(request) ?? 'ar';

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = this.localize('common.error.unexpected', locale);
    let errorCode = 'INTERNAL_SERVER_ERROR';
    let errors: unknown;

    const genericError = exception as Record<string, unknown> | undefined;
    const exceptionName = exception instanceof Error ? exception.name : String(genericError?.name ?? '');
    const exceptionType = String(genericError?.type ?? '');

    if (exceptionName === 'PayloadTooLargeError' || exceptionType === 'entity.too.large') {
      status = HttpStatus.PAYLOAD_TOO_LARGE;
      errorCode = 'PAYLOAD_TOO_LARGE';
      message = this.localize('common.payload_too_large', locale);
    } else if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();
      if (typeof res === 'string') {
        message = this.localize(res, locale);
      } else if (typeof res === 'object' && res) {
        const payload = res as Record<string, unknown>;
        errorCode = String(payload.error_code ?? payload.error ?? errorCode);
        const rawMessage = payload.message;
        message = this.messageFromPayload(rawMessage, errorCode, status, locale);
        errors = this.localizeErrors(payload.errors, locale);
      }
    }

    const isProduction = this.configService?.get<string>('NODE_ENV') === 'production';

    if (status >= 500) {
      const stack = exception instanceof Error ? exception.stack : String(exception);
      this.logger.error(
        `${request.method} ${request.url} failed with ${status} ${errorCode}`,
        stack,
      );
    }

    const debugError =
      !isProduction && status >= 500 && exception instanceof Error
        ? { name: exception.name, message: exception.message }
        : undefined;

    response.status(status).json({
      success: false,
      message,
      error_code: errorCode,
      locale,
      errors,
      debug: debugError,
    });
  }

  private messageFromPayload(rawMessage: unknown, errorCode: string, status: number, locale: string) {
    if (Array.isArray(rawMessage)) return this.localize('common.validation', locale);
    if (typeof rawMessage === 'string') return this.localize(rawMessage, locale);
    if (status === HttpStatus.UNAUTHORIZED) return this.localize('common.unauthorized', locale);
    if (status === HttpStatus.FORBIDDEN) return this.localize('common.forbidden', locale);
    if (status === HttpStatus.NOT_FOUND) return this.localize('common.not_found', locale);
    if (status === HttpStatus.BAD_REQUEST) return this.localize('common.validation', locale);
    return this.localize(errorCode.toLowerCase(), locale);
  }

  private localize(keyOrMessage: string, locale: string) {
    if (!this.i18n) return keyOrMessage;
    const key = this.normalizeKnownKey(keyOrMessage);
    const translated = this.i18n.t(key, locale);
    return translated === key && key !== keyOrMessage ? this.i18n.t(keyOrMessage, locale) : translated;
  }

  private normalizeKnownKey(value: string) {
    const map: Record<string, string> = {
      'Forbidden resource': 'common.forbidden',
      'User not found': 'common.not_found',
      'Order not found': 'common.not_found',
      'Device not found': 'common.not_found',
      'Validation failed': 'common.validation',
      'Unauthorized': 'common.unauthorized',
    };
    return map[value] ?? value;
  }

  private localizeErrors(errors: unknown, locale: string): unknown {
    if (!this.i18n || !Array.isArray(errors)) return errors;
    return errors.map((item) => {
      if (!item || typeof item !== 'object') return item;
      const row = item as Record<string, unknown>;
      const constraints = row.constraints && typeof row.constraints === 'object'
        ? Object.fromEntries(Object.entries(row.constraints as Record<string, unknown>).map(([key, value]) => [key, this.localize(String(value), locale)]))
        : row.constraints;
      return { ...row, constraints };
    });
  }
}
