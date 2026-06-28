import { Module } from '@nestjs/common';
import { SecurityModule } from '../../common/security/security.module';
import { PrismaModule } from '../../prisma/prisma.module';
import { AuditModule } from '../audit/audit.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { LoyaltyController, ReferralController, RetentionController, WalletController } from './wallet-loyalty.controller';
import { WalletLoyaltyService } from './wallet-loyalty.service';

@Module({
  imports: [SecurityModule, PrismaModule, NotificationsModule, AuditModule],
  controllers: [WalletController, LoyaltyController, ReferralController, RetentionController],
  providers: [WalletLoyaltyService],
})
export class WalletLoyaltyModule {}
