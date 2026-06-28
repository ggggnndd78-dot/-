import { Module } from '@nestjs/common';
import { I18nModule } from '../../common/i18n/i18n.module';
import { SystemLocalizationController } from './system-localization.controller';

@Module({
  imports: [I18nModule],
  controllers: [SystemLocalizationController],
})
export class SystemModule {}
