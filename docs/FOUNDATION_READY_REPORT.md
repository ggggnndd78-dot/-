# Ghiyarak Enterprise v2.0 — Phases 0 to 4 Ready Report

هذه النسخة تضبط المراحل 0 إلى 4، مع التركيز على أن المرحلة الرابعة ليست SMS فقط، بل تسجيل الحسابات حسب الدور.

## Phase 0

- تثبيت سيناريوهات الزائر والعميل والتاجر والورشة والمستودع والإدارة.
- توثيق قواعد الوصول حسب الدور وحالة الاعتماد.

## Phase 1

- Backend مركزي NestJS.
- Database مركزية Prisma/MySQL.
- Flutter Android/Web/Windows.
- Routing و Theme و API Client و Secure Storage.

## Phase 2

- OTP حقيقي عبر TextPeak event_send.
- OTP hash في قاعدة البيانات.
- Refresh tokens.
- Guest session.
- تسجيل الدخول والتحقق.

## Phase 3

- RBAC roles and permissions.
- أدوار customer / merchant_owner / workshop_owner / warehouse_owner / admin.
- منع صفحات الإدارة والتاجر والورشة والمستودع حسب الصلاحية وحالة الاعتماد.

## Phase 4 — الصحيح حسب الخطة

- Customer Register: OTP ثم ACTIVE مباشرة.
- Merchant Register: OTP ثم Onboarding ثم PENDING_REVIEW.
- Workshop Register: OTP ثم Onboarding ثم PENDING_REVIEW.
- Warehouse Register: OTP ثم Onboarding ثم PENDING_REVIEW.
- Provider Status Page للتاجر/الورشة/المستودع قبل الاعتماد.
- Warehouse Hub أولي بعد الاعتماد.
- لا يتم فتح لوحات التشغيل قبل موافقة الإدارة.

## SMS integration

المسار المعتمد حاليًا:

```text
POST https://textpeak-streams.commpeak.com/event_send/
event = login_otp
sender = GLOBAL
template = {code}
```

## ملفات تم ضبطها في هذه النسخة

```text
frontend/lib/features/auth/data/auth_repository.dart
frontend/lib/features/auth/logic/auth_controller.dart
frontend/lib/features/auth/data/models/user_model.dart
frontend/lib/features/auth/presentation/pages/register_page.dart
frontend/lib/features/auth/presentation/pages/otp_page.dart
frontend/lib/features/provider_onboarding/logic/provider_onboarding_controller.dart
frontend/lib/features/provider_onboarding/presentation/provider_status_page.dart
frontend/lib/features/warehouse/presentation/pages/warehouse_hub_page.dart
frontend/lib/app/router/app_router.dart
frontend/lib/app/router/route_names.dart
backend/.env.example
backend/src/modules/communications/sms.service.ts
```

## اختبار المرحلة الرابعة

1. دخول كزائر: يسمح بالتصفح فقط.
2. إنشاء عميل: OTP ثم دخول مباشر.
3. إنشاء تاجر: OTP ثم بيانات المنشأة ثم PENDING_REVIEW.
4. إنشاء ورشة: OTP ثم بيانات الورشة ثم PENDING_REVIEW.
5. إنشاء مستودع: OTP ثم بيانات المستودع ثم PENDING_REVIEW.
6. محاولة فتح merchant/workshop/warehouse قبل الاعتماد: يتم التوجيه إلى حالة الاعتماد أو منع الوصول.
7. بعد موافقة الإدارة: يفتح المسار المناسب حسب نوع المؤسسة.
