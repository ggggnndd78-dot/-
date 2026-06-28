import { Module } from '@nestjs/common';
import { EventBusModule } from '../../common/events/event-bus.module';
import { AuditModule } from '../audit/audit.module';
import { SecurityModule } from '../../common/security/security.module';
import { PrismaModule } from '../../prisma/prisma.module';
import { EmployeesController } from './employees.controller';
import { EmployeesService } from './employees.service';

@Module({
  imports: [PrismaModule, SecurityModule, EventBusModule, AuditModule],
  controllers: [EmployeesController],
  providers: [EmployeesService],
  exports: [EmployeesService],
})
export class EmployeesModule {}
