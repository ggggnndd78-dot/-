import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EventBusModule } from '../../common/events/event-bus.module';
import { SecurityModule } from '../../common/security/security.module';
import { PrismaModule } from '../../prisma/prisma.module';
import { CommunicationsModule } from '../communications/communications.module';
import { FirebasePushService } from './firebase-push.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

@Module({
  imports: [ConfigModule, SecurityModule, PrismaModule, CommunicationsModule, EventBusModule],
  controllers: [NotificationsController],
  providers: [NotificationsService, FirebasePushService],
  exports: [NotificationsService, FirebasePushService],
})
export class NotificationsModule {}
