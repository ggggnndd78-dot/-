# Migration and Full i18n Fix

This package fixes the failed localization migration and the Flutter i18n scanner syntax issue.

## Fixed database issue

The localization migration previously referenced legacy table names:

- `users`
- `permissions`
- `roles`
- `role_permissions`

The actual Prisma mappings use:

- `iam_users`
- `iam_permissions`
- `iam_roles`
- `iam_role_permissions`

The migration `20260624210000_full_platform_localization` now targets the correct tables and seeds Arabic/English translation keys for all major modules.

## Development database recovery

If your local database already failed during this migration, reset it before running again:

```powershell
cd backend
npx prisma migrate reset --force
npx prisma generate
npm run prisma:seed
npm run start:dev
```

If you want to keep data, resolve the failed migration manually only after reviewing the partial objects created in MySQL.

## Fixed Flutter issue

`frontend/tool/i18n_hardcoded_scan.dart` now compiles correctly and can be run from the frontend directory:

```powershell
cd frontend
dart run tool/i18n_hardcoded_scan.dart
```

The scan reports possible hardcoded UI strings without failing the build.
