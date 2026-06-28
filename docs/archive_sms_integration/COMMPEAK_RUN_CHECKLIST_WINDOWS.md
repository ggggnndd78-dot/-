# Ghiyarak CommPeak SMS OTP — Windows Run Checklist

## 1) Backend env

```powershell
cd C:\Users\hassa\StudioProjects\ghiyarak\backend
copy .env.example .env
notepad .env
```

ضع التوكن الحقيقي في:

```env
SMS_PROVIDER="COMMPEAK"
COMMPEAK_SMS_AUTH_URL="https://textpeak-streams.commpeak.com/otp/auth"
COMMPEAK_SMS_TOKEN="PASTE_COMMPEAK_TRANSACTIONAL_STREAM_TOKEN_HERE"
COMMPEAK_SMS_SENDER="GLOBAL"
```

بعد اعتماد Sender ID باسم `GHIYARAK` غيّر:

```env
COMMPEAK_SMS_SENDER="GHIYARAK"
```

## 2) تشغيل Backend

```powershell
cd C:\Users\hassa\StudioProjects\ghiyarak\backend
npm install
npx prisma generate
npm run start:dev
```

اختبار الصحة:

```powershell
Invoke-RestMethod http://localhost:3000/api/v1/health
```

## 3) تشغيل Flutter Web

```powershell
cd C:\Users\hassa\StudioProjects\ghiyarak\frontend
flutter clean
flutter pub get
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 4759 --dart-define=GHIYARAK_API_BASE_URL=http://localhost:3000/api/v1 --dart-define=GHIYARAK_LOCALE=ar
```

## 4) تجربة التسجيل

في التطبيق اكتب رقمك:

```text
+967781699203
```

سيتم الإرسال من Backend عبر CommPeak.

## 5) ملاحظات مهمة

- لا تضع CommPeak Token في Flutter.
- لا ترفع `backend/.env` إلى GitHub.
- استخدم `GLOBAL` للتجربة الآن.
- بعد اعتماد `GHIYARAK` في TextPeak Sender IDs غيّر `COMMPEAK_SMS_SENDER`.
- إذا رفعت Backend على Render/VPS، أضف IP السيرفر في IP ACL داخل CommPeak.
