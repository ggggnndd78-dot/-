# Ghiyarak Membership/Auth/Locations Final Update

## Included
- Phone-number-only login screen.
- Yemeni mobile validation for 70, 71, 73, 77, 78.
- Phone number uniqueness is enforced through `iam_users.phone_normalized`.
- Login no longer creates accounts automatically for unknown numbers.
- New-device login requires OTP and creates a trusted device token.
- Existing trusted device can enter directly.
- Registration begins with account type only: customer, merchant, workshop.
- Customer registers with phone + email and becomes active immediately.
- Merchant/workshop registration uses governorate/city/district/area dropdowns from database.
- Merchant/workshop documents are uploaded as Base64 and reviewed from admin dashboard.
- Required document rules are enforced in backend and Flutter.
- Seed now includes Yemeni governorates, districts and default areas for dropdown selection.
- Demo accounts remain available for testing after `npm run prisma:seed`.

## Run
```powershell
cd backend
npx prisma migrate reset --force
npx prisma generate
npm run prisma:seed
npm run typecheck
npm run start:dev
```

Then:
```powershell
cd frontend
flutter pub get
flutter analyze
flutter run
```
