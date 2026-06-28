# Ghiyarak v2.0 Complete Package Note

This package is based on the full `env_fixed_real_auth` version and includes the MySQL migration identifier fix.

Fixed issue:

```text
Identifier name 'org_member_permissions_organization_member_id_permission_code_key' is too long
```

The long unique/index names were shortened in:

```text
backend/prisma/schema.prisma
backend/prisma/migrations/20260616210000_enterprise_v2_identity_rbac_foundation/migration.sql
```

Run from a clean database if a previous migration failed:

```powershell
cd ghiyarak\backend
npx prisma migrate reset --force
npx prisma generate
npx prisma migrate deploy
npm run prisma:seed
npm run build
npm run start:dev
```

If reset fails, recreate the database manually:

```sql
DROP DATABASE IF EXISTS ghiyarak;
CREATE DATABASE ghiyarak CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```
