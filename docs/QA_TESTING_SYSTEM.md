# Ghiyarak QA & Testing System

This document defines the final Phase 23 QA layer added to the project.

## Backend QA commands

```powershell
cd backend
npm install
npx prisma generate
npm run typecheck
npm run test
npm run start:dev
npm run test:smoke
```

## QA dashboard APIs

- `GET /api/v1/quality/readiness`
- `POST /api/v1/quality/runs`
- `GET /api/v1/quality/runs`
- `POST /api/v1/quality/runs/:id/results`
- `GET /api/v1/quality/release-checklist`
- `PATCH /api/v1/quality/release-checklist/:id`

## Release rules

Production release is blocked until readiness returns `READY`.
