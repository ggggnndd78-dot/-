# Ghiyarak — التشغيل المحلي اليدوي بدون Docker

هذه الصفحة تختصر تشغيل المشروع بدون Docker وبدون ملفات scripts.

## Backend

```powershell
cd ghiyarak\backend
npm install
copy .env.example .env
```

عدّل `backend/.env` ثم نفذ:

```powershell
npx prisma generate
npx prisma migrate deploy
npm run prisma:seed
npm run build
npm run start:dev
```

## Health

```powershell
Invoke-RestMethod http://localhost:3000/api/v1/health
```

## Swagger

```text
http://localhost:3000/api/docs
```

## Flutter Android

```powershell
cd ghiyarak\frontend
flutter clean
flutter pub get
flutter run -d emulator --dart-define=GHIYARAK_API_BASE_URL=http://10.0.2.2:3000/api/v1 --dart-define=GHIYARAK_LOCALE=ar
```

## Flutter Web

```powershell
cd ghiyarak\frontend
flutter clean
flutter pub get
flutter run -d chrome --dart-define=GHIYARAK_API_BASE_URL=http://localhost:3000/api/v1 --dart-define=GHIYARAK_LOCALE=ar
```

## Flutter Windows

```powershell
cd ghiyarak\frontend
flutter clean
flutter pub get
flutter run -d windows --dart-define=GHIYARAK_API_BASE_URL=http://localhost:3000/api/v1 --dart-define=GHIYARAK_LOCALE=ar
```
