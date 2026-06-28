# Ghiyarak Enterprise v2.0 — Phase 7 Notifications and Emails

This release completes Phase 7 only.

## What changed

- Added notification templates table.
- Added email delivery logs.
- Added Firebase push delivery logs.
- Added Firebase push service.
- Connected admin verification approval/rejection/docs-required/suspension to:
  - In-app notification
  - Email notification
  - Firebase push notification
- Kept Firebase disabled by default for local development.

## Not changed

This phase does not add new order/payment/delivery behavior.
Those flows remain for their own phases.

## Run

```powershell
cd C:\Users\hassa\StudioProjects\ghiyarak\backend
npm install
npm run prisma:generate
npm run prisma:deploy
npm run prisma:seed
npm run start:dev
```

## Required local setting

```env
FIREBASE_PUSH_ENABLED="false"
```

Enable Firebase only after adding the service account safely outside Git.
