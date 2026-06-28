import { Module } from '@nestjs/common';
import { EventBusModule } from '../../common/events/event-bus.module';
import { PrismaModule } from '../../prisma/prisma.module';
import { ProductImportsController } from './product-imports.controller';
import { ProductImportsService } from './product-imports.service';

@Module({
  imports: [PrismaModule, EventBusModule],
  controllers: [ProductImportsController],
  providers: [ProductImportsService],
  exports: [ProductImportsService],
})
export class ProductImportsModule {}
