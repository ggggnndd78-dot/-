# Ghiyarak Phase 3.2 — Software Engineering Handoff

## هدف النسخة
هذه النسخة مبنية للمرحلة الحالية من مشروع Ghiyarak بعد إلغاء Firebase واعتماد Backend OTP مع CommPeak/TextPeak SMS الحقيقي.

## قرار معماري مهم
لا يتم إرسال SMS من Flutter مباشرة. Flutter يتعامل مع Backend فقط، والـ Backend هو الذي يتصل بـ CommPeak.

```text
Flutter Web/Desktop/Android
→ NestJS Backend Auth API
→ CommPeak/TextPeak Streams API
→ User receives OTP SMS
→ Backend verifies OTP from database
→ Backend returns JWT access/refresh tokens
```

## ما تم إلغاءه
- Firebase runtime initialization من Flutter.
- firebase_core و firebase_auth من pubspec.yaml.
- firebase-admin من backend/package.json.
- google-services.json و firebase_options.dart من المشروع.
- أي اعتماد على reCAPTCHA أو Firebase too-many-requests.

## ما تم اعتماده
- SMS Provider: COMMPEAK / TEXTPEAK
- API URL: https://textpeak-streams.commpeak.com/otp/auth
- Sender الحالي للتجربة: GLOBAL
- Sender النهائي بعد الاعتماد: GHIYARAK
- OTP message verified in Yemen using English ASCII to reduce SMS segmentation cost.

## أين تضع CommPeak Token؟
ضعه فقط في `backend/.env`:

```env
SMS_PROVIDER="COMMPEAK"
COMMPEAK_SMS_AUTH_URL="https://textpeak-streams.commpeak.com/otp/auth"
COMMPEAK_SMS_TOKEN="PASTE_COMMPEAK_TRANSACTIONAL_STREAM_TOKEN_HERE"
COMMPEAK_SMS_SENDER="GLOBAL"
```

بعد اعتماد Sender ID غيّر:

```env
COMMPEAK_SMS_SENDER="GHIYARAK"
```

## ملفات Backend المهمة
- `backend/src/modules/communications/sms.service.ts`
- `backend/src/modules/communications/otp-delivery.service.ts`
- `backend/src/modules/auth/auth.service.ts`
- `backend/src/modules/auth/auth.controller.ts`
- `backend/src/modules/auth/dto/request-otp.dto.ts`
- `backend/src/modules/auth/dto/verify-otp.dto.ts`
- `backend/.env.example`

## ملفات Flutter المهمة
- `frontend/lib/features/auth/data/auth_repository.dart`
- `frontend/lib/features/auth/logic/auth_controller.dart`
- `frontend/lib/features/auth/presentation/pages/login_page.dart`
- `frontend/lib/features/auth/presentation/pages/register_page.dart`
- `frontend/lib/features/auth/presentation/pages/otp_page.dart`
- `frontend/lib/main.dart`
- `frontend/pubspec.yaml`

## اختبار Backend يدويًا
```powershell
Invoke-RestMethod http://localhost:3000/api/v1/health
```

طلب OTP:

```powershell
Invoke-RestMethod `
  -Uri "http://localhost:3000/api/v1/auth/request-otp" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"phone":"+967781699203","purpose":"LOGIN"}'
```

تحقق OTP:

```powershell
Invoke-RestMethod `
  -Uri "http://localhost:3000/api/v1/auth/verify-otp" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"phone":"+967781699203","otpCode":"123456","purpose":"LOGIN"}'
```

بدل 123456 بالرمز الذي وصلك فعليًا.

## تنبيهات إنتاجية
- لا تضع CommPeak token داخل Flutter.
- لا ترفع `backend/.env` إلى GitHub.
- إذا رفعت Backend على Render/VPS، أضف IP السيرفر في CommPeak IP ACL.
- التوكن الذي ظهر سابقًا في الشات يجب عمل Regenerate/Rotate له بعد التأكد من الربط.
- `node_modules`, `.dart_tool`, `build` غير مرفقة لأنها تتولد بالأوامر.
