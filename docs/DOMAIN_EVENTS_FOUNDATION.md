# Ghiyarak Phase 6 — Domain Events Ready

هذه النسخة تضبط المرحلة السادسة حسب الخطة وبحدودها فقط.

## Phase 6 الهدف

تأسيس نظام أحداث بسيط وآمن يسجل العمليات المهمة في قاعدة البيانات ويجهزها للمعالجة لاحقًا.

## بدون توسع زائد

لم يتم بناء:

```text
Accounting
Payments flow
Delivery flow
External queue worker
Advanced event processor
```

## الذي تم تنفيذه

```text
domain_events
event_outbox
event_logs
EventBus persistence
Admin read-only event inspection APIs
```

## الأحداث المتصلة الآن

```text
OTP requested / verified
Guest session created
Provider onboarding submitted
Verification document uploaded
Admin approval / rejection / documents required / suspension
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

## فحص الأحداث من Swagger

```text
GET /api/v1/admin/events/domain
GET /api/v1/admin/events/outbox
GET /api/v1/admin/events/logs
```

تحتاج حساب Admin لديه صلاحية:

```text
view_audit_logs
```
