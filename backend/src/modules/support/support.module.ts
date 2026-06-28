
import { Module } from '@nestjs/common';
import { SecurityModule } from '../../common/security/security.module';
import { PrismaModule } from '../../prisma/prisma.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AuditModule } from '../audit/audit.module';
import { ReviewsModule } from '../reviews/reviews.module';
import { SupportController } from './support.controller';
import { SupportService } from './support.service';

@Module({
  imports: [SecurityModule, PrismaModule, NotificationsModule, AuditModule, ReviewsModule],
  controllers: [SupportController],
  providers: [SupportService],
})
export class SupportModule {}
