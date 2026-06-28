# Ghiyarak Backend

تشغيل محلي بدون Docker.

```powershell
copy .env.example .env
npm install
npx prisma generate
npx prisma migrate deploy
npm run prisma:seed
npm run build
npm run start:dev
```

## SMS OTP

هذه النسخة تستخدم CommPeak/TextPeak SMS Streams API. ضع التوكن الحقيقي في `backend/.env` فقط:

```env
SMS_PROVIDER="COMMPEAK"
COMMPEAK_SMS_TOKEN="PASTE_COMMPEAK_TRANSACTIONAL_STREAM_TOKEN_HERE"
COMMPEAK_SMS_SENDER="GLOBAL"
```
