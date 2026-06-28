# Ghiyarak Phase 3.2 — CommPeak SMS OTP Edition

هذه النسخة ألغت Firebase بالكامل من مسار التحقق، وأصبحت تعتمد على:

```text
Flutter Web/Desktop/Android
→ NestJS Backend
→ CommPeak/TextPeak Streams API
→ SMS OTP حقيقي
→ Backend OTP verify
→ JWT login/register
```

## الملفات المهمة التي تم تعديلها

### Backend

- `backend/src/modules/communications/sms.service.ts`
  - أضيف Provider جديد: `COMMPEAK`
  - يستخدم Endpoint:
    `https://textpeak-streams.commpeak.com/otp/auth`
  - يرسل JSON بنفس صيغة CommPeak Tester:
    `messages[].sender`, `messages[].recipient_phone`, `messages[].message_content`

- `backend/src/modules/communications/otp-delivery.service.ts`
  - رسائل SMS أصبحت ASCII English لتقليل تكلفة التقسيم وزيادة توافق OTP:
    `123456 is your Ghiyarak verification code. Do not share this code with anyone.`

- `backend/src/modules/auth/auth.service.ts`
  - أزيل Firebase Phone/Auth ID Token flow.
  - `/auth/request-otp` يولد OTP ويحفظه في قاعدة البيانات.
  - `/auth/verify-otp` يتحقق من الكود وينشئ/يفعل المستخدم ويصدر JWT.

- `backend/src/modules/firebase` تم حذفه.
- `firebase-admin` تم حذفه من `backend/package.json`.

### Flutter

- حذف `firebase_core` و `firebase_auth` من `frontend/pubspec.yaml`.
- حذف `frontend/lib/core/firebase`.
- حذف `frontend/lib/features/auth/data/firebase_auth_service.dart`.
- شاشة Login/Register تستخدم الآن Backend OTP مباشرة.
- شاشة OTP تتحقق من الكود عبر Backend فقط.

## إعداد backend/.env

انسخ:

```powershell
copy backend\.env.example backend\.env
```

ثم ضع التوكن الحقيقي في:

```env
SMS_PROVIDER="COMMPEAK"
COMMPEAK_SMS_AUTH_URL="https://textpeak-streams.commpeak.com/otp/auth"
COMMPEAK_SMS_TOKEN="PASTE_COMMPEAK_TRANSACTIONAL_STREAM_TOKEN_HERE"
COMMPEAK_SMS_SENDER="GLOBAL"
```

حاليًا استخدم `GLOBAL` لأنه Approved في TextPeak. بعد اعتماد Sender ID باسم `GHIYARAK` غيّر:

```env
COMMPEAK_SMS_SENDER="GHIYARAK"
```

> لا ترفع `backend/.env` إلى GitHub.

## تشغيل Backend

```powershell
cd backend
npm install
npx prisma generate
npm run start:dev
```

اختبار الصحة:

```powershell
Invoke-RestMethod http://localhost:3000/api/v1/health
```

## تشغيل Flutter Web

```powershell
cd frontend
flutter clean
flutter pub get
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 4759 --dart-define=GHIYARAK_API_BASE_URL=http://localhost:3000/api/v1 --dart-define=GHIYARAK_LOCALE=ar
```

## تجربة OTP

من التطبيق:

```text
رقم الجوال: +967781699203
```

سيرسل Backend رسالة عبر CommPeak ثم تفتح صفحة OTP.

## اختبار مباشر من PowerShell

```powershell
$TOKEN = "PASTE_COMMPEAK_TRANSACTIONAL_STREAM_TOKEN_HERE"

$headers = @{
  "Content-Type" = "application/json"
  "Authorization" = $TOKEN
}

$body = @{
  messages = @(
    @{
      sender = "GLOBAL"
      recipient_phone = "967781699203"
      message_content = "123456 is your Ghiyarak verification code. Do not share this code with anyone."
    }
  )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod `
  -Uri "https://textpeak-streams.commpeak.com/otp/auth" `
  -Method POST `
  -Headers $headers `
  -Body $body
```

## ملاحظة أمان مهمة

CommPeak API Token سرّي. إذا ظهر في دردشة أو GitHub، اعمل له Regenerate/Rotate من TextPeak ثم ضع التوكن الجديد في `backend/.env`.
