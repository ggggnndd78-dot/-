# Ghiyarak Production Deployment

This document defines the final Phase 24 local-production deployment checklist.

## Backend local production build

```powershell
cd backend
copy .env.example .env
npm install
npx prisma generate
npx prisma migrate deploy
npm run prisma:seed
npm run build:prod
npm run start:prod
```

## Flutter release checks

```powershell
cd frontend
flutter pub get
flutter analyze
flutter test
flutter build apk
flutter build web
flutter build windows
```

## Final preflight

```powershell
cd backend
npm run preflight
npm run qa:all
```

## Required production settings

- Use real MySQL credentials.
- Replace all default JWT secrets.
- Keep SMS and email credentials in `.env` only.
- Never commit `.env`.
- Run migrations before starting the backend.
- Verify `/api/v1/health` before opening the app.
