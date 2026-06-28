import { Module } from '@nestjs/common';
import { SecurityModule } from '../../common/security/security.module';
import { EventBusModule } from '../../common/events/event-bus.module';
import { PrismaModule } from '../../prisma/prisma.module';
import { AuditModule } from '../audit/audit.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AccountingModule } from '../accounting/accounting.module';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';

@Module({
  imports: [SecurityModule, PrismaModule, AuditModule, EventBusModule, NotificationsModule, AccountingModule],
  controllers: [PaymentsController],
  providers: [PaymentsService],
})
export class PaymentsModule {}
