# تقرير إصلاح Drawer/Auth/Theme

## ملخص التنفيذ

تم تنفيذ إصلاح بنيوي لطبقة التنقل والمصادقة والثيم مع الحفاظ على العمليات الحالية وعدم حذف أي Feature.  
العمل شمل إصلاح مشاكل `Drawer` واتجاه الواجهة، منع الاعتماد غير الآمن على `GoRouterState.of(context)`, فصل تنقل الزائر عن العميل، منع استدعاء `/api/v1/me` بدون `access token` حقيقي، وتوحيد الثيم الداكن الاحترافي.

## أهم ما تم إصلاحه

### 1) إصلاح مشكلة `ListTile background color or ink splashes may be invisible`

- تم إنشاء مكوّن مشترك: `lib/shared/widgets/app_tile_material.dart`
- تم حقن `Material` شفافة في الحاويات المشتركة التالية:
  - `lib/shared/widgets/app_scaffold.dart`
  - `lib/shared/layout/dashboard_shell.dart`
- تم إصلاح المصدر المؤكد من سجل التشغيل في:
  - `lib/features/marketplace/presentation/pages/categories_page.dart`
- تم إصلاح بطاقات مزخرفة أخرى تحتوي `ListTile`/`SwitchListTile` في:
  - `lib/features/merchant_market/presentation/pages/edit_listing_page.dart`
  - `lib/features/merchant_market/presentation/pages/merchant_reports_page.dart`
  - `lib/features/merchant_market/presentation/pages/create_listing_page.dart`

### 2) إصلاح Drawer واتجاه RTL/LTR

- تم منع الازدواج في زر القائمة عبر:
  - `lib/shared/widgets/app_scaffold.dart`
  - `lib/shared/layout/dashboard_shell.dart`
- تم ضبط:
  - العربية `RTL` مع `endDrawer`
  - الإنجليزية `LTR` مع `drawer`
- تم إيقاف `automaticallyImplyLeading` واستخدام زر Menu واحد فقط.
- تم تحسين سلوك الإغلاق ثم الانتقال من القائمة، مع منع التنقل لنفس الصفحة.

### 3) إصلاح `There is no GoRouterState above the current context`

- تم إيقاف الاعتماد المباشر على `GoRouterState.of(context)` داخل الـ widgets العامة.
- تم استخدام مسارات آمنة عبر:
  - `lib/shared/navigation/navigation_context.dart`
  - `lib/shared/widgets/app_scaffold.dart`
  - `lib/shared/layout/dashboard_shell.dart`
  - `lib/features/customer/presentation/customer_parts_page.dart`

### 4) إصلاح وضع الزائر ومنع طلب `/me` بدون Token

- تم منع استدعاء `/api/v1/me` في حالة عدم وجود `access token`.
- تم دعم فصل واضح بين الزائر والمستخدم المسجل عبر:
  - `lib/features/auth/data/auth_repository.dart`
  - `lib/features/profile/data/profile_repository.dart`
  - `lib/app/router/app_router.dart`
  - `lib/shared/navigation/app_route_resolver.dart`

### 5) فصل Navigation حسب الدور

- تم تنظيم القوائم في:
  - `lib/shared/navigation/app_navigation_config.dart`
- القوائم أصبحت مفصولة إلى:
  - `guestNavigationItems`
  - `customerNavigationItems`
  - `merchantNavigationItems`
  - `workshopNavigationItems`
  - `warehouseNavigationItems`
  - `supportNavigationItems`
  - `adminNavigationItems`

### 6) توحيد الثيم

- تم تحسين الثيم الداكن الاحترافي وتوحيد الألوان والخطوط عبر:
  - `lib/core/theme/app_colors.dart`
  - `lib/core/theme/app_text_styles.dart`
  - `lib/core/theme/app_theme.dart`
  - `lib/app/app.dart`

## ملفات رئيسية تم تعديلها

- `lib/shared/widgets/app_scaffold.dart`
- `lib/shared/layout/dashboard_shell.dart`
- `lib/shared/navigation/app_navigation_config.dart`
- `lib/shared/navigation/navigation_context.dart`
- `lib/shared/navigation/app_route_resolver.dart`
- `lib/shared/widgets/app_card.dart`
- `lib/shared/widgets/app_tile_material.dart`
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/i18n/app_localizations.dart`
- `lib/app/router/app_router.dart`
- `lib/app/app.dart`
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/presentation/pages/login_page.dart`
- `lib/features/splash/presentation/splash_page.dart`
- `lib/features/profile/data/profile_repository.dart`
- `lib/features/customer/presentation/customer_center_page.dart`
- `lib/features/customer/presentation/customer_parts_page.dart`
- `lib/features/marketplace/presentation/pages/categories_page.dart`
- `lib/features/merchant_market/presentation/pages/create_listing_page.dart`
- `lib/features/merchant_market/presentation/pages/edit_listing_page.dart`
- `lib/features/merchant_market/presentation/pages/merchant_reports_page.dart`

## التحقق النهائي

تم تشغيل الأوامر التالية بعد آخر تعديل:

- `flutter clean`
- `flutter pub get`
- `dart format lib`
- `flutter analyze`
- `flutter test`

## النتيجة

- `flutter analyze`: بدون مشاكل
- `flutter test`: جميع الاختبارات نجحت
- تم إزالة المصدر المؤكد لتحذير `ListTile background color`
- تم تأمين طبقة التنقل العامة ضد `GoRouterState` غير المتاح
- تم منع طلب `/me` للزائر بدون token
- تم تثبيت سلوك Drawer واتجاه الواجهة حسب اللغة
