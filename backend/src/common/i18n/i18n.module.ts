import { Global, Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { I18nService } from './i18n.service';

@Global()
@Module({
  imports: [PrismaModule],
  providers: [I18nService],
  exports: [I18nService],
})
export class I18nModule {}
