# Ghiyarak Final Complete - Admin Documents Preview Fixed

This package fixes the remaining Admin Membership Applications document review issue.

## Fixed

- Admin can open uploaded JPG/PNG verification images inside the dashboard.
- Admin can open uploaded PDF verification documents inside the dashboard.
- Fullscreen document preview dialog added.
- Image viewer supports zoom and pan.
- PDF viewer reads document bytes directly from Base64 stored in database.
- Viewer handles raw Base64 and data URI Base64.

## Run

```powershell
cd backend
npx prisma migrate reset --force
npx prisma generate
npm run prisma:seed
npm run typecheck
npm run start:dev
```

```powershell
cd frontend
flutter pub get
flutter analyze
flutter run
```
