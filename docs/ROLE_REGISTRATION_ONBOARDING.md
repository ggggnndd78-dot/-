# Ghiyarak Enterprise v2.0 — Phase 4 Role Registration + Onboarding

هذه النسخة تضبط المرحلة الرابعة حسب الخطة الرسمية: تسجيل الحسابات حسب الدور.

## ما تم اعتماده

- Customer يسجل عبر OTP ثم يصبح الحساب ACTIVE مباشرة.
- Merchant يسجل عبر OTP ثم يكمل بيانات المتجر والفروع والحساب البنكي وساعات العمل والمستندات.
- Workshop يسجل عبر OTP ثم يكمل بيانات الورشة والخدمات والفروع والحساب البنكي وساعات العمل والمستندات.
- Warehouse يسجل عبر OTP ثم يكمل بيانات المستودع والفروع والحساب البنكي وساعات العمل والمستندات.
- Merchant / Workshop / Warehouse قبل الموافقة لا يفتحون لوحات التشغيل، بل تظهر لهم شاشة حالة الاعتماد.
- بعد موافقة الإدارة يتم إعطاء owner role المناسب:
  - merchant_owner
  - workshop_owner
  - warehouse_owner
- تم إضافة بوابة مستودع أولية حتى لا يعود حساب المستودع المعتمد إلى واجهة العميل.

## ملفات Backend المهمة

```text
backend/src/modules/auth/auth.service.ts
backend/src/modules/auth/dto/request-otp.dto.ts
backend/src/modules/auth/dto/verify-otp.dto.ts
backend/src/modules/organizations/organizations.controller.ts
backend/src/modules/organizations/organizations.service.ts
backend/src/modules/organizations/dto/*
backend/prisma/schema.prisma
backend/prisma/seed.ts
```

## ملفات Flutter المهمة

```text
frontend/lib/features/entry/presentation/entry_page.dart
frontend/lib/features/auth/presentation/pages/register_page.dart
frontend/lib/features/auth/presentation/pages/otp_page.dart
frontend/lib/features/provider_onboarding/presentation/*
frontend/lib/features/provider_onboarding/logic/*
frontend/lib/features/warehouse/presentation/pages/warehouse_hub_page.dart
frontend/lib/app/router/app_router.dart
frontend/lib/app/router/route_names.dart
```

## مسار العميل

```text
Entry -> Register customer -> SMS OTP -> Verify -> ACTIVE -> profile basics / marketplace
```

## مسار التاجر/الورشة/المستودع

```text
Entry -> Register provider -> SMS OTP -> Verify -> Organization data -> Branch -> Profile -> Bank -> Hours -> Documents -> PENDING_REVIEW -> Provider Status
```

## منع الوصول قبل الاعتماد

```text
Merchant console requires approved MERCHANT organization + merchant_owner role.
Workshop console requires approved WORKSHOP organization + workshop_owner role.
Warehouse console requires approved WAREHOUSE organization + warehouse_owner role.
```

## ملاحظة SMS

الـ SMS يعمل عبر TextPeak event_send لأن هذا هو المسار الذي نجح فعليًا في الاختبار.
التوكن الحقيقي لا يوجد داخل النسخة، ضعه فقط داخل backend/.env.
