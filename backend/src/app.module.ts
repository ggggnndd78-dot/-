import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { HealthModule } from './modules/health/health.module';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { LocationsModule } from './modules/locations/locations.module';
import { VehiclesModule } from './modules/vehicles/vehicles.module';
import { OrganizationsModule } from './modules/organizations/organizations.module';
import { CatalogModule } from './modules/catalog/catalog.module';
import { ListingsModule } from './modules/listings/listings.module';
import { CartModule } from './modules/cart/cart.module';
import { OrdersModule } from './modules/orders/orders.module';
import { MerchantModule } from './modules/merchant/merchant.module';
import { WorkshopsModule } from './modules/workshops/workshops.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { DeliveryModule } from './modules/delivery/delivery.module';
import { SupportModule } from './modules/support/support.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { WalletLoyaltyModule } from './modules/wallet_loyalty/wallet-loyalty.module';
import { I18nModule } from './common/i18n/i18n.module';
import { SecurityModule } from './common/security/security.module';
import { AuditModule } from './modules/audit/audit.module';
import { AdminModule } from './modules/admin/admin.module';
import { EmployeesModule } from './modules/employees/employees.module';
import { EventsModule } from './modules/events/events.module';
import { ProductImportsModule } from './modules/product-imports/product-imports.module';
import { AccountingModule } from './modules/accounting/accounting.module';
import { QualityModule } from './modules/quality/quality.module';
import { SystemModule } from './modules/system/system.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    I18nModule,
    SecurityModule,
    AuditModule,
    PrismaModule,
    HealthModule,
    AuthModule,
    UsersModule,
    LocationsModule,
    VehiclesModule,
    OrganizationsModule,
    CatalogModule,
    ListingsModule,
    CartModule,
    OrdersModule,
    MerchantModule,
    WorkshopsModule,
    NotificationsModule,
    PaymentsModule,
    DeliveryModule,
    SupportModule,
    ReviewsModule,
    WalletLoyaltyModule,
    AdminModule,
    EmployeesModule,
    EventsModule,
    ProductImportsModule,
    AccountingModule,
    QualityModule,
    SystemModule,
  ],
})
export class AppModule {}
