# تقرير إصلاح سياسة الإدارة والتنقل والأمان

## ملخص التنفيذ

تم تنفيذ ضبط مركزي للصلاحيات والتنقل بين الواجهة الأمامية والواجهة الخلفية مع الحفاظ على Features المشروع الحالية وعدم حذف مسارات التاجر أو العميل أو الدعم.

## أهم ما تم إصلاحه

### 1. نموذج الصلاحيات في Flutter

- توسيع `AuthState` ليحتوي على:
  - `can`
  - `canAny`
  - `canAll`
  - `isSuperAdmin`
  - `isAdminOperations`
  - `isSupportAgent`
  - `canAccessAdminConsole`
  - `canOpenSupportConsole`
- منع اعتبار `support_agent` كعميل.
- منع bypass السابق الذي كان يسمح لأي admin برؤية كل العناصر أو فتح كل الصفحات دون تحقق فعلي من الصلاحيات.

### 2. Route Guards و Navigation

- إنشاء `AccessPolicy` كمنطق مركزي لاستخدامه في:
  - `AppNavigationConfig`
  - `PermissionGuard`
  - `_RequireAccess` داخل `app_router.dart`
- إضافة حماية واضحة للمسارات:
  - `/admin`
  - `/support`
  - `/support/operations`
  - alias آمن للمسار القديم `/support/center`
- تحسين landing route بعد تسجيل الدخول:
  - `admin_super` -> `/admin/control-center`
  - `admin_operations` -> `/admin/control-center`
  - `support_agent` -> `/support/operations`
- فصل عناصر التنقل حسب الدور:
  - `guestNavigationItems`
  - `customerNavigationItems`
  - `merchantNavigationItems`
  - `workshopNavigationItems`
  - `warehouseNavigationItems`
  - `supportNavigationItems`
  - `adminNavigationItems`

### 3. سياسة التوكن والـ API Client

- منع إرسال guest headers افتراضيًا على الطلبات المحمية.
- تفعيل refresh token retry مرة واحدة فقط عند `401`.
- إذا فشل refresh:
  - تنظيف الجلسة
  - إطلاق invalidation
- إذا رجع `403`:
  - لا يتم logout تلقائيًا
  - تظل الصفحة في سياق Forbidden

### 4. تشديد Backend Support Authorization

- إضافة `RequireAnyPermissions` في NestJS.
- تطوير `PermissionsGuard` ليدعم:
  - `RequirePermissions`
  - `RequireAnyPermissions`
- حماية endpoints الإدارية في `support.controller.ts` بصلاحيات فعلية بدل الاعتماد على check داخلي فقط.

### 5. Responsive / Shell

- تثبيت shell مكتبي واضح داخل `AppScaffold` عبر `_DesktopSideNavigation`.
- إصلاح overflow في `MerchantManagementScaffold` عبر `SingleChildScrollView` و`ConstrainedBox`.

### 6. Localization

- إضافة مفاتيح ترجمة جديدة لعناصر الدعم وصفحة Forbidden بالعربي والإنجليزي.
- تحويل صفحة `UnauthorizedPage` إلى localization بدل النصوص الصلبة.

## الملفات المعدلة

- `lib/features/auth/logic/auth_state.dart`
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/presentation/pages/otp_page.dart`
- `lib/features/authorization/logic/access_policy.dart`
- `lib/features/authorization/presentation/permission_guard.dart`
- `lib/features/authorization/presentation/unauthorized_page.dart`
- `lib/shared/navigation/app_navigation_config.dart`
- `lib/shared/navigation/app_route_resolver.dart`
- `lib/shared/widgets/app_scaffold.dart`
- `lib/shared/layout/dashboard_shell.dart`
- `lib/app/router/route_names.dart`
- `lib/app/router/app_router.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/i18n/app_localizations.dart`
- `lib/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart`
- `../backend/src/common/decorators/permissions.decorator.ts`
- `../backend/src/common/guards/permissions.guard.ts`
- `../backend/src/modules/support/support.controller.ts`
- `../backend/src/modules/admin/admin.service.ts`
- `../docs/PRODUCTION_ACCEPTANCE_CHECKLIST_AR.md`

## نتائج التحقق

- `flutter clean` تم بنجاح
- `flutter pub get` تم بنجاح
- `dart format lib` تم بنجاح
- `flutter analyze` نجح بدون أخطاء
- `flutter test` نجح
- `npm install` تم بنجاح
- `npx prisma generate --no-engine` نجح
- `npm run build` نجح مع `PRISMA_GENERATE_NO_ENGINE=1` بسبب قفل ملف Prisma engine على Windows
- `npm run test` نجح

## ملاحظة تشغيل

على بيئة Windows الحالية كان ملف Prisma engine مقفولًا أثناء `prisma generate` التقليدي. تم تجاوز ذلك أثناء التحقق باستخدام توليد client بدون engine، بينما بقيت طبقة الحراسة والصلاحيات والتوجيه معدلة داخل الكود نفسه.
