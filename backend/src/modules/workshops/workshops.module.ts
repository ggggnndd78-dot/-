import { Module } from '@nestjs/common';
import { SecurityModule } from '../../common/security/security.module';
import { AuditModule } from '../audit/audit.module';
import { WorkshopsController } from './workshops.controller';
import { WorkshopsService } from './workshops.service';

@Module({
  imports: [SecurityModule, AuditModule],
  controllers: [WorkshopsController],
  providers: [WorkshopsService],
})
export class WorkshopsModule {}
