import { Module } from "@nestjs/common";
import { JwtModule } from "@nestjs/jwt";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { Reflector } from "@nestjs/core";
import { PrismaModule } from "../../prisma/prisma.module";
import { AuditModule } from "../audit/audit.module";
import { AccountingModule } from "../accounting/accounting.module";
import { ReviewsModule } from "../reviews/reviews.module";
import { MerchantController } from "./merchant.controller";
import { MerchantService } from "./merchant.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { PermissionsGuard } from "../../common/guards/permissions.guard";

@Module({
  imports: [
    PrismaModule,
    AuditModule,
    AccountingModule,
    ReviewsModule,
    ConfigModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>("JWT_ACCESS_SECRET"),
      }),
    }),
  ],
  controllers: [MerchantController],
  providers: [PermissionsGuard, MerchantService, JwtAuthGuard, Reflector],
})
export class MerchantModule {}
