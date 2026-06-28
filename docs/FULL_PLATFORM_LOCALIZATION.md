# Ghiyarak Full Platform Localization

This release upgrades localization from an admin-only feature into a platform-wide Arabic/English architecture.

## Implemented

- Arabic is the default locale.
- English is supported as a runtime-selectable locale.
- Flutter sends `Accept-Language` and `X-Locale` with every API request.
- Backend reads `Accept-Language` and returns localized error envelopes.
- User language preference is stored locally and in `users.locale`.
- Public translation catalog endpoint is available for Flutter.
- Admin/Super Admin can manage translations through database-backed catalog APIs.
- New normalized tables:
  - `translation_keys`
  - `translation_values`
- Existing `translation_entries` remains as a compatibility mirror.
- Notifications support localized title/body when translation keys are passed.
- OTP email/SMS templates are localized by translation keys.
- Flutter supports instant RTL/LTR switching without logout, restart or rebuild.

## APIs

- `GET /api/v1/system/localization`
- `GET /api/v1/system/translations/catalog?locale=ar&platform=FLUTTER`
- `PATCH /api/v1/me/locale`
- `GET /api/v1/admin/i18n/catalog`
- `PUT /api/v1/admin/i18n/catalog/:key`

## Required Commands

```powershell
cd backend
npm install
npx prisma generate
npx prisma migrate deploy
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

## Notes

The platform now has a database-driven localization foundation. New user-facing strings must be added as translation keys and consumed through `context.tr('key')` in Flutter or `I18nService` in NestJS.
