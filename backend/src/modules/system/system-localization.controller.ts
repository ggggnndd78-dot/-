import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { I18nService } from '../../common/i18n/i18n.service';

@ApiTags('System Localization')
@Controller('system')
export class SystemLocalizationController {
  constructor(private readonly i18n: I18nService) {}

  @Public()
  @Get('localization')
  localization() {
    return {
      success: true,
      data: {
        default_locale: 'ar',
        supported_locales: ['ar', 'en'],
        rtl_locales: ['ar'],
        runtime_switching: true,
        database_driven: true,
      },
    };
  }

  @Public()
  @Get('translations/catalog')
  async catalog(
    @Query('locale') locale?: string,
    @Query('namespace') namespace?: string,
    @Query('platform') platform?: string,
  ) {
    const normalizedLocale = this.i18n.normalize(locale);
    const data = await this.i18n.catalog(normalizedLocale, {
      namespace,
      platform: platform || 'GLOBAL',
    });
    return {
      success: true,
      data: {
        locale: normalizedLocale,
        direction: normalizedLocale === 'ar' ? 'rtl' : 'ltr',
        translations: data,
      },
    };
  }
}
