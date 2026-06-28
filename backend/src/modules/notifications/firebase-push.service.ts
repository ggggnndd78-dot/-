import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { PrismaService } from '../../prisma/prisma.service';

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

@Injectable()
export class FirebasePushService {
  private readonly logger = new Logger(FirebasePushService.name);
  private initialized = false;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  private enabled() {
    return this.config.get<string>('FIREBASE_PUSH_ENABLED', 'false').toLowerCase() === 'true';
  }

  private initializeIfNeeded() {
    if (!this.enabled()) return false;
    if (this.initialized || admin.apps.length > 0) {
      this.initialized = true;
      return true;
    }

    const rawJson = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON')?.trim();
    const path = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH')?.trim();

    if (!rawJson && !path) {
      this.logger.warn('Firebase push is enabled but service account is not configured.');
      return false;
    }

    const serviceAccount = JSON.parse(rawJson || readFileSync(path!, 'utf8')) as admin.ServiceAccount;
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    this.initialized = true;
    return true;
  }

  private normalizeData(data?: Record<string, unknown>) {
    const normalized: Record<string, string> = {};
    for (const [key, value] of Object.entries(data ?? {})) {
      if (value === null || value === undefined) continue;
      normalized[key] = typeof value === 'string' ? value : JSON.stringify(value);
    }
    return normalized;
  }

  private async log(input: {
    userId?: number | null;
    fcmToken?: string | null;
    title: string;
    body: string;
    status: 'SENT' | 'FAILED' | 'SKIPPED';
    provider: string;
    error?: unknown;
    metadata?: Record<string, unknown>;
  }) {
    const errorText = input.error instanceof Error ? input.error.message : input.error ? String(input.error) : null;
    await (this.prisma as any).pushNotificationLog?.create({
      data: {
        userId: input.userId ?? null,
        fcmToken: input.fcmToken ?? null,
        title: input.title,
        body: input.body,
        status: input.status,
        provider: input.provider,
        error: errorText,
        metadata: input.metadata ?? undefined,
        sentAt: input.status === 'SENT' ? new Date() : null,
      },
    }).catch(() => null);
  }

  async sendToUser(userId: number, payload: PushPayload) {
    const devices = await (this.prisma as any).userDevice.findMany({
      where: { userId, isActive: true },
      select: { id: true, fcmToken: true },
    });

    if (devices.length === 0) {
      await this.log({ userId, title: payload.title, body: payload.body, status: 'SKIPPED', provider: 'firebase', metadata: { reason: 'NO_ACTIVE_DEVICES', ...payload.data } });
      return { sent: 0, failed: 0, skipped: true, reason: 'NO_ACTIVE_DEVICES' };
    }

    if (!this.initializeIfNeeded()) {
      await this.log({ userId, title: payload.title, body: payload.body, status: 'SKIPPED', provider: 'firebase', metadata: { reason: 'FIREBASE_NOT_CONFIGURED', ...payload.data } });
      return { sent: 0, failed: 0, skipped: true, reason: 'FIREBASE_NOT_CONFIGURED' };
    }

    let sent = 0;
    let failed = 0;
    for (const device of devices) {
      try {
        await admin.messaging().send({
          token: device.fcmToken,
          notification: { title: payload.title, body: payload.body },
          data: this.normalizeData(payload.data),
        });
        sent += 1;
        await this.log({ userId, fcmToken: device.fcmToken, title: payload.title, body: payload.body, status: 'SENT', provider: 'firebase', metadata: payload.data });
      } catch (error) {
        failed += 1;
        await this.log({ userId, fcmToken: device.fcmToken, title: payload.title, body: payload.body, status: 'FAILED', provider: 'firebase', error, metadata: payload.data });
      }
    }

    return { sent, failed, skipped: false };
  }
}
