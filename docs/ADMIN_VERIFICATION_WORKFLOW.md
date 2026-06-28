# Ghiyarak Enterprise v2.0 — Phase 5 Admin Verification Ready

هذه النسخة تضبط المرحلة 5 حسب الخطة الرسمية: الموافقات والتوثيق الإداري.

## ما تم تنفيذه

- إضافة جداول تتبع المراجعة:
  - `verification_review_notes`
  - `verification_status_history`
- توسيع حالات طلب التوثيق لدعم:
  - `PENDING_REVIEW`
  - `SUSPENDED`
- ضبط API الإدارة:
  - عرض طلبات التوثيق
  - فتح تفاصيل الطلب والمستندات
  - الموافقة
  - الرفض مع سبب
  - طلب مستندات إضافية
  - تعليق الحساب
- عند الموافقة:
  - تحديث حالة المنشأة إلى `APPROVED`
  - تفعيل `isVerified`
  - إضافة دور المالك المناسب تلقائيًا
  - نشر حدث `VerificationApproved`
  - إنشاء إشعار داخل التطبيق للمالك
  - إرسال إيميل حسب مزود البريد
  - تسجيل Audit Log
- عند الرفض:
  - تحديث الحالة إلى `REJECTED`
  - حفظ سبب الرفض
  - نشر حدث `VerificationRejected`
  - إشعار داخل التطبيق
  - إيميل
  - Audit Log
- عند طلب مستندات:
  - تحديث الحالة إلى `DOCUMENTS_REQUIRED`
  - حفظ ملاحظة الإدارة
  - إشعار داخل التطبيق
  - Audit Log
- عند التعليق:
  - تحديث الحالة إلى `SUSPENDED`
  - حفظ السبب
  - إشعار داخل التطبيق
  - Audit Log

## الملفات المهمة

```text
backend/prisma/schema.prisma
backend/prisma/migrations/20260623233000_phase5_admin_verifications/migration.sql
backend/src/modules/organizations/organizations.controller.ts
backend/src/modules/organizations/organizations.service.ts
backend/src/modules/organizations/organizations.module.ts
frontend/lib/features/admin/data/admin_repository.dart
frontend/lib/features/admin/presentation/pages/admin_verifications_page.dart
frontend/lib/core/config/api_endpoints.dart
```

## التشغيل

```powershell
cd C:\Users\hassa\StudioProjects\ghiyarak\backend
npm install
npm run prisma:generate
npm run prisma:deploy
npm run prisma:seed
npm run start:dev
```

ثم شغل Flutter:

```powershell
cd C:\Users\hassa\StudioProjects\ghiyarak\frontend
flutter pub get
flutter run
```

## اختبار المرحلة 5

1. سجل كتاجر أو ورشة أو مستودع.
2. أكمل بيانات النشاط والوثائق.
3. أرسل طلب الاعتماد.
4. ادخل بحساب الإدارة.
5. افتح: لوحة الإدارة → الموافقات والتوثيق الإداري.
6. افتح التفاصيل وتأكد من ظهور المستندات.
7. جرّب:
   - موافقة
   - رفض
   - طلب مستندات
   - تعليق حساب معتمد

## ملاحظة

هذه المرحلة لا تبني السوق أو الطلبات. هي تثبت الاعتماد الإداري قبل فتح لوحات التجار والورش والمستودعات.
