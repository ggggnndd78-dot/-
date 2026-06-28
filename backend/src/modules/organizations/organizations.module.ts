import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { EventBusModule } from '../../common/events/event-bus.module';
import { AuditModule } from '../audit/audit.module';
import { CommunicationsModule } from '../communications/communications.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { OrganizationsController } from './organizations.controller';
import { OrganizationsService } from './organizations.service';

@Module({
  imports: [
    ConfigModule,
    AuditModule,
    NotificationsModule,
    CommunicationsModule,
    EventBusModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_ACCESS_SECRET'),
      }),
    }),
  ],
  controllers: [OrganizationsController],
  providers: [OrganizationsService, JwtAuthGuard, Reflector],
})
export class OrganizationsModule {}
