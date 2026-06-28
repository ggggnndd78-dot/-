import 'reflect-metadata';
import { BadRequestException, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { json, urlencoded } from 'express';
import helmet from 'helmet';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { ResponseSerializationInterceptor } from './common/interceptors/response-serialization.interceptor';
import { I18nService } from './common/i18n/i18n.service';
import { setupSwagger } from './config/swagger.config';

async function bootstrap() {
  // Disable Nest's default body parser so we can set an explicit limit for Base64 document uploads.
  const app = await NestFactory.create(AppModule, { bodyParser: false });
  const config = app.get(ConfigService);

  const requestBodyLimit =
    config.get<string>('REQUEST_BODY_LIMIT') ||
    config.get<string>('JSON_BODY_LIMIT') ||
    '30mb';

  app.use(json({ limit: requestBodyLimit }));
  app.use(urlencoded({ extended: true, limit: requestBodyLimit }));

  const corsOrigins = config
    .get<string>('CORS_ORIGINS', '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  const isProduction = config.get<string>('NODE_ENV') === 'production';

  app.enableCors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      if (corsOrigins.includes(origin)) return callback(null, true);
      if (!isProduction && /^http:\/\/(localhost|127\.0\.0\.1):\d+$/.test(origin)) {
        return callback(null, true);
      }
      return callback(null, false);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept-Language', 'X-Locale', 'X-Language', 'X-Request-Id'],
  });

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: isProduction,
      exceptionFactory: (validationErrors = []) => new BadRequestException({
        message: 'common.validation',
        error_code: 'VALIDATION_FAILED',
        errors: validationErrors.map((error) => ({
          property: error.property,
          constraints: error.constraints,
        })),
      }),
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter(config, app.get(I18nService))); 
  app.useGlobalInterceptors(new ResponseSerializationInterceptor());
  app.use(
    helmet({
      crossOriginResourcePolicy: false,
    }),
  );

  setupSwagger(app);

  const port = Number(config.get('PORT', 3000));
  await app.listen(port, '0.0.0.0');
  console.log(`Ghiyarak backend running on port ${port} with /api/v1 prefix`);
}

bootstrap();
