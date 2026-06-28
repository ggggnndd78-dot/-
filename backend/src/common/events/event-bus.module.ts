import { Module } from '@nestjs/common';
import { AuditModule } from '../../modules/audit/audit.module';
import { PrismaModule } from '../../prisma/prisma.module';
import { EventBusService } from './event-bus.service';

@Module({
  imports: [PrismaModule, AuditModule],
  providers: [EventBusService],
  exports: [EventBusService],
})
export class EventBusModule {}
