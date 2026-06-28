import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { EventBusService } from '../../common/events/event-bus.service';
import { I18nService } from '../../common/i18n/i18n.service';
import { PrismaService } from '../../prisma/prisma.service';
import { EmailService } from '../communications/email.service';
import { SmsService } from '../communications/sms.service';
import { CreateNotificationDto, RegisterDeviceDto } from './dto/notifications.dto';
import { FirebasePushService } from './firebase-push.service';

export interface DispatchNotificationInput {
  title: string;
  body: string;
  data?: Record<string, unknown>;
  sendInApp?: boolean;
  sendEmail?: boolean;
  sendSms?: boolean;
  sendPush?: boolean;
  eventKey?: string;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly email: EmailService,
    private readonly sms: SmsService,
    private readonly push: FirebasePushService,
    private readonly eventBus: EventBusService,
    private readonly i18n: I18nService,
  ) {}
  private get db() { return this.prisma as any; }

  async registerDevice(userId: number, dto: RegisterDeviceDto) {
    const device = await this.db.userDevice.upsert({
      where: { fcmToken: dto.fcmToken },
      update: {
        userId,
        platform: dto.platform,
        deviceName: dto.deviceName ?? null,
        appVersion: dto.appVersion ?? null,
        isActive: true,
        lastSeenAt: new Date(),
      },
      create: {
        userId,
        platform: dto.platform,
        fcmToken: dto.fcmToken,
        deviceName: dto.deviceName ?? null,
        appVersion: dto.appVersion ?? null,
        isActive: true,
      },
    });
    return { success: true, message: 'common.success', data: device };
  }

  async deactivateDevice(userId: number, id: number) {
    const device = await this.db.userDevice.findFirst({ where: { id, userId } });
    if (!device) throw new NotFoundException({ message: 'Device not found', error_code: 'DEVICE_NOT_FOUND' });
    const data = await this.db.userDevice.update({ where: { id }, data: { isActive: false } });
    return { success: true, message: 'common.success', data };
  }

  async listMyNotifications(userId: number) {
    const data = await this.db.notification.findMany({
      where: { userId, status: { not: 'ARCHIVED' } },
      orderBy: { createdAt: 'desc' },
      take: 80,
    });
    return { success: true, data };
  }

  async unreadCount(userId: number) {
    const data = await this.db.notification.count({ where: { userId, status: 'UNREAD' } });
    return { success: true, data: { unread_count: data } };
  }

  async markRead(userId: number, id: number) {
    const notification = await this.db.notification.findFirst({ where: { id, userId } });
    if (!notification) throw new NotFoundException({ message: 'Notification not found', error_code: 'NOTIFICATION_NOT_FOUND' });
    const data = await this.db.notification.update({
      where: { id },
      data: { status: 'READ', readAt: new Date() },
    });
    return { success: true, data };
  }

  async markAllRead(userId: number) {
    const result = await this.db.notification.updateMany({
      where: { userId, status: 'UNREAD' },
      data: { status: 'READ', readAt: new Date() },
    });
    return { success: true, data: result };
  }

  async createForUser(userId: number, title: string, body: string, data?: Record<string, unknown>, channel: 'IN_APP' | 'FCM' = 'IN_APP') {
    if (channel === 'FCM') {
      const dispatched = await this.dispatchToUser(userId, { title, body, data, sendInApp: true, sendPush: true });
      return dispatched.data.notification;
    }

    const notification = await this.db.notification.create({
      data: { userId, title, body, data: data ?? undefined, channel: 'IN_APP' },
    });

    return notification;
  }

  async dispatchToUser(userId: number, input: DispatchNotificationInput) {
    const user = await this.db.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException({ message: 'common.not_found', error_code: 'USER_NOT_FOUND' });

    const locale = user.locale ?? 'ar';
    const localizedTitle = await this.i18n.tAsync(input.title, locale, input.data as any);
    const localizedBody = await this.i18n.tAsync(input.body, locale, input.data as any);

    const channels: string[] = [];
    let notification: any = null;

    if (input.sendInApp !== false) {
      notification = await this.createForUser(userId, localizedTitle, localizedBody, input.data, 'IN_APP');
      channels.push('IN_APP');
    }

    if (input.sendEmail && user.email) {
      await this.email.send({
        to: user.email,
        subject: localizedTitle,
        text: localizedBody,
        html: `<div dir="rtl" style="font-family:Arial,Tahoma,sans-serif;line-height:1.8"><h2>${localizedTitle}</h2><p>${localizedBody}</p><hr/><p style="color:#667085">Ghiyarak | غيارك</p></div>`,
        metadata: { user_id: userId, event_key: input.eventKey ?? null, ...(input.data ?? {}) },
      }).catch((error) => this.logger.warn(`Email notification failed: ${error instanceof Error ? error.message : String(error)}`));
      channels.push('EMAIL');
    }

    if (input.sendSms) {
      const smsNotificationsEnabled = String(process.env.NOTIFICATION_SMS_ENABLED ?? 'false').toLowerCase() === 'true';
      const phone = user.phoneE164 ?? user.phoneNormalized;
      if (smsNotificationsEnabled && phone) {
        await this.sms.send({
          to: phone,
          message: `${localizedTitle}
${localizedBody}`,
          metadata: { purpose: 'notification', user_id: userId, event_key: input.eventKey ?? null, ...(input.data ?? {}) },
        }).catch((error) => this.logger.warn(`SMS notification failed: ${error instanceof Error ? error.message : String(error)}`));
        channels.push('SMS');
      } else if (input.sendSms) {
        this.logger.warn('SMS notification channel requested but NOTIFICATION_SMS_ENABLED is not true; skipping SMS to avoid using OTP stream for plain messages.');
      }
    }

    if (input.sendPush) {
      await this.push.sendToUser(userId, { title: localizedTitle, body: localizedBody, data: { event_key: input.eventKey ?? '', ...(input.data ?? {}) } });
      channels.push('FIREBASE_PUSH');
    }

    await this.eventBus.publish({
      name: 'NotificationDispatched',
      aggregateType: 'notification',
      aggregateId: notification?.publicId ?? String(userId),
      actorUserId: userId,
      payload: {
        user_id: userId,
        title: localizedTitle,
        channels,
        event_key: input.eventKey ?? null,
        data: input.data ?? {},
      },
    }).catch(() => null);

    return { success: true, message: 'common.success', data: { channels, notification } };
  }

  async createTestNotification(userId: number, dto: CreateNotificationDto) {
    return this.dispatchToUser(userId, {
      title: dto.title,
      body: dto.body,
      data: { source: 'manual_test' },
      sendInApp: true,
      sendEmail: dto.sendEmail ?? false,
      sendPush: dto.sendPush ?? false,
      eventKey: 'manual_test',
    });
  }
}
