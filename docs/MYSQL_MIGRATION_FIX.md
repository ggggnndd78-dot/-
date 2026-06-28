# MySQL Migration Fix — Phase 0–2

## Fixed issue

The previous migration failed on MySQL with:

```text
Error: P3018
Database error code: 1059
Identifier name 'org_member_permissions_organization_member_id_permission_code_key' is too long
```

MySQL limits identifier names to 64 characters. The migration now uses short explicit names:

```text
omp_member_perm_uq
omba_member_branch_uq
omp_member_fk
omba_member_fk
omba_branch_fk
oei_org_fk
```

The Prisma schema was also updated with matching `map` names so future migrations do not generate long identifiers again.

## Important because your previous run partially failed

If the old failed migration already touched your local database, reset the local database before running the fixed version.

This is safe only for local development if you do not have important data in the `ghiyarak` database.

### Option A — Prisma reset

```powershell
cd ghiyarak\backend
npx prisma migrate reset --force
```

Then run:

```powershell
npx prisma generate
npx prisma migrate deploy
npm run prisma:seed
npm run build
npm run start:dev
```

### Option B — Drop and recreate database manually

If MySQL root has no password:

```powershell
mysql -u root -e "DROP DATABASE IF EXISTS ghiyarak; CREATE DATABASE ghiyarak CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

If MySQL root has a password:

```powershell
mysql -u root -p -e "DROP DATABASE IF EXISTS ghiyarak; CREATE DATABASE ghiyarak CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

Then run:

```powershell
cd ghiyarak\backend
npx prisma generate
npx prisma migrate deploy
npm run prisma:seed
npm run build
npm run start:dev
```

## Notes about npm warnings

The `npm warn deprecated` messages are warnings from transitive packages. They did not stop the project.

The real blocking error was the MySQL identifier length in the migration, and that is fixed in this version.
