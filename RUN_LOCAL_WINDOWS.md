# تشغيل Ghiyarak Phase 4 على Windows

## 1. إعداد الباكند

```powershell
cd C:\Users\hassa\StudioProjects\ghiyarak\backend
copy .env.example .env
notepad .env
```

ضع التوكن الحقيقي:

```env
SMS_PROVIDER="COMMPEAK_EVENT_SEND"
COMMPEAK_SMS_TOKEN="PASTE_REAL_TOKEN_HERE"
COMMPEAK_SMS_EVENT_SEND_URL="https://textpeak-streams.commpeak.com/event_send/"
COMMPEAK_SMS_STATUS_URL="https://textpeak-streams.commpeak.com/messages_status/"
COMMPEAK_SMS_EVENT_KEY="login_otp"
COMMPEAK_SMS_SENDER="GLOBAL"
```

## 2. تشغيل الباكند

```powershell
npm install
npm run prisma:generate
npm run prisma:deploy
npm run prisma:seed
npm run start:dev
```

Health check:

```powershell
curl.exe http://localhost:3000/api/v1/health
```

## 3. تشغيل Flutter

```powershell
cd C:\Users\hassa\StudioProjects\ghiyarak\frontend
flutter pub get
flutter clean
flutter run
```

## 4. اختبار Phase 4

```text
1. Register Customer -> OTP -> يدخل مباشرة.
2. Register Merchant -> OTP -> Organization -> Branch -> Profile -> Bank -> Hours -> Documents -> Status.
3. Register Workshop -> نفس المسار.
4. Register Warehouse -> نفس المسار.
5. قبل الموافقة لا تفتح لوحات التشغيل.
```
