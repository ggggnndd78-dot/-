import { Injectable } from '@nestjs/common';
import { Request } from 'express';
import { PrismaService } from '../../prisma/prisma.service';

export type SupportedLocale = 'ar' | 'en';

type TranslationParams = Record<string, string | number | boolean | null | undefined>;

type CatalogCache = {
  expiresAt: number;
  values: Record<string, string>;
};

const fallbackDictionary: Record<SupportedLocale, Record<string, string>> = {
  ar: {
    'app.name': 'غيارك',
    'common.success': 'تمت العملية بنجاح',
    'common.not_found': 'العنصر المطلوب غير موجود',
    'common.notFound': 'العنصر المطلوب غير موجود',
    'common.forbidden': 'لا تملك صلاحية تنفيذ هذه العملية',
    'common.unauthorized': 'يرجى تسجيل الدخول أولاً',
    'common.validation': 'البيانات المدخلة غير صحيحة',
    'common.error.unexpected': 'حدث خطأ غير متوقع',
    'common.payload_too_large': 'حجم الملفات المرفوعة كبير جدًا. قلل حجم الصور أو ارفع ملفات أصغر ثم حاول مرة أخرى.',
    'auth.invalid_token': 'رمز الدخول غير صالح أو منتهي',
    'auth.invalidToken': 'رمز الدخول غير صالح أو منتهي',
    'auth.otp_rate_limited': 'تم تجاوز عدد محاولات طلب الرمز. حاول لاحقاً',
    'auth.otp_not_found': 'لم يتم العثور على طلب رمز صالح',
    'auth.otp_expired': 'انتهت صلاحية رمز التحقق',
    'auth.otp_max_attempts': 'تم تجاوز عدد محاولات التحقق',
    'auth.invalid_otp': 'رمز التحقق غير صحيح',
    'auth.refresh_required': 'رمز التحديث مطلوب',
    'validation.phone': 'رقم الجوال غير صحيح',
    'auth.validation.yemeni_phone': 'أدخل رقم جوال يمني صحيح يبدأ بـ 7 ويتكون من 9 أرقام',
    'auth.validation.yemeni_phone_companies': 'أدخل رقم جوال يمني صحيح تابع لإحدى الشركات: سبأفون 71، يمن موبايل 77 أو 78، يو 73، واي 70',
    'validation.required': 'هذا الحقل مطلوب',
    'orders.invalid_transition': 'لا يمكن تغيير حالة الطلب إلى الحالة المطلوبة',
    'orders.invalidTransition': 'لا يمكن تغيير حالة الطلب إلى الحالة المطلوبة',
    'wallet.insufficient_balance': 'رصيد المحفظة غير كافٍ',
    'wallet.insufficientBalance': 'رصيد المحفظة غير كافٍ',
  },
  en: {
    'app.name': 'Ghiyarak',
    'common.success': 'Operation completed successfully',
    'common.not_found': 'The requested resource was not found',
    'common.notFound': 'The requested resource was not found',
    'common.forbidden': 'You are not allowed to perform this action',
    'common.unauthorized': 'Please sign in first',
    'common.validation': 'The submitted data is invalid',
    'common.error.unexpected': 'Something went wrong',
    'common.payload_too_large': 'The uploaded files are too large. Please reduce the file sizes and try again.',
    'auth.invalid_token': 'The access token is invalid or expired',
    'auth.invalidToken': 'The access token is invalid or expired',
    'auth.otp_rate_limited': 'Too many verification code requests. Please try again later',
    'auth.otp_not_found': 'No valid verification code request was found',
    'auth.otp_expired': 'The verification code has expired',
    'auth.otp_max_attempts': 'Maximum verification attempts reached',
    'auth.invalid_otp': 'The verification code is invalid',
    'auth.refresh_required': 'Refresh token is required',
    'validation.phone': 'Invalid phone number',
    'auth.validation.yemeni_phone': 'Enter a valid Yemeni mobile number starting with 7 and containing 9 digits',
    'auth.validation.yemeni_phone_companies': 'Enter a valid Yemeni mobile number for Sabafon 71, Yemen Mobile 77/78, YOU 73, or Y 70',
    'validation.required': 'This field is required',
    'orders.invalid_transition': 'The order cannot move to the requested status',
    'orders.invalidTransition': 'The order cannot move to the requested status',
    'wallet.insufficient_balance': 'Wallet balance is insufficient',
    'wallet.insufficientBalance': 'Wallet balance is insufficient',
  },
};

@Injectable()
export class I18nService {
  private readonly cache = new Map<string, CatalogCache>();
  private readonly ttlMs = 60_000;

  constructor(private readonly prisma: PrismaService) {}

  normalize(locale?: string | null): SupportedLocale {
    if (!locale) return 'ar';
    return locale.toLowerCase().startsWith('en') ? 'en' : 'ar';
  }

  fromRequest(request?: Request | null): SupportedLocale {
    if (!request) return 'ar';
    const headers = request.headers;
    const candidate =
      headers['accept-language']?.toString() ||
      headers['x-locale']?.toString() ||
      headers['x-language']?.toString();
    return this.normalize(candidate);
  }

  clearCache() {
    this.cache.clear();
  }

  async catalog(locale?: string | null, options: { namespace?: string; platform?: string; includeDraft?: boolean } = {}) {
    const lang = this.normalize(locale);
    const namespace = options.namespace?.trim();
    const platform = options.platform?.trim() || 'GLOBAL';
    const cacheKey = `${lang}:${namespace ?? '*'}:${platform}:${options.includeDraft ? 'draft' : 'published'}`;
    const cached = this.cache.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) return cached.values;

    const values: Record<string, string> = { ...(fallbackDictionary[lang] ?? {}) };
    try {
      const rows = await (this.prisma as any).translationValue.findMany({
        where: {
          locale: lang,
          ...(options.includeDraft ? {} : { status: 'PUBLISHED' }),
          OR: [{ platform }, { platform: 'GLOBAL' }],
          translationKey: {
            ...(namespace ? { namespace } : {}),
            status: 'PUBLISHED',
          },
        },
        include: { translationKey: true },
        orderBy: [{ platform: 'asc' }, { id: 'asc' }],
      });
      for (const row of rows) {
        if (row?.translationKey?.key && row.value !== null && row.value !== undefined) {
          values[row.translationKey.key] = String(row.value);
        }
      }
    } catch (_) {
      try {
        const legacyRows = await (this.prisma as any).translationEntry.findMany({
          where: {
            locale: lang,
            ...(namespace ? { namespace } : {}),
            OR: [{ platform }, { platform: 'GLOBAL' }],
          },
        });
        for (const row of legacyRows) values[row.translationKey] = String(row.value);
      } catch (_) {}
    }

    this.cache.set(cacheKey, { expiresAt: Date.now() + this.ttlMs, values });
    return values;
  }

  async tAsync(key: string, locale?: string | null, params: TranslationParams = {}): Promise<string> {
    const lang = this.normalize(locale);
    const values = await this.catalog(lang);
    return this.interpolate(values[key] ?? fallbackDictionary[lang]?.[key] ?? fallbackDictionary.ar[key] ?? key, params);
  }

  t(key: string, locale?: string | null, params: TranslationParams = {}): string {
    const lang = this.normalize(locale);
    return this.interpolate(fallbackDictionary[lang]?.[key] ?? fallbackDictionary.ar[key] ?? key, params);
  }

  private interpolate(value: string, params: TranslationParams) {
    let output = value;
    for (const [paramKey, paramValue] of Object.entries(params)) {
      output = output.replace(new RegExp(`\\{${paramKey}\\}`, 'g'), String(paramValue ?? ''));
    }
    return output;
  }
}
