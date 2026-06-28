# Ghiyarak Enterprise System Hardening & Unification

## Scope

This document covers the Phase 22 hardening layer. It does not redesign completed business modules. It adds production-safe unification controls across the existing modular monolith.

## Existing Codebase Assessment

Reviewed layers:

- Backend NestJS modules: auth, RBAC, users, organizations, employees, catalog, listings, carts, orders, workshops, payments, accounting, delivery, support, reviews, wallet/loyalty, notifications, audit and admin.
- Prisma schema and migrations from identity through enterprise control center.
- Flutter structure under `app/`, `core/`, `shared/`, and `features/`.
- Existing runtime locale controller and lightweight Arabic/English localization.
- Existing Admin Control Center and analytics endpoints.

## Key Findings

| Severity | Area | Finding | Action |
|---|---|---|---|
| HIGH | Admin | Admin module navigation was partially hardcoded. | Added `system_modules` registry and RBAC-filtered endpoint. |
| HIGH | i18n | UI had runtime locale switching, but no admin-managed translation catalog. | Added `translation_entries` and catalog APIs. |
| MEDIUM | Analytics | Metrics were calculated live per request. | Added `analytics_metric_snapshots` and refresh endpoint. |
| MEDIUM | Naming | Schema mostly uses snake_case mapping, but older tables use mixed domain prefixes. | Added naming report without renaming production tables. |
| MEDIUM | Audit | Audit logs were append-only by convention, but no integrity checkpoint. | Added `audit_integrity_checkpoints` and checksum endpoint. |

## Naming Convention Standardization Plan

### Database

Rules:

- Table names use snake_case.
- Keep table names short and domain-oriented.
- Avoid repeated context words.
- Do not rename production tables during hardening unless compatibility views are added.

Phase 22 adds a naming report endpoint instead of destructive renames:

```text
GET /api/v1/admin/system-hardening/naming
```

### Backend

Rules:

- Controller: `<domain>.controller.ts`
- Service: `<domain>.service.ts`
- DTO: `<action>-<domain>.dto.ts` when needed
- REST paths use plural nouns and short resource names.

### Flutter

Rules:

- Feature-first under `features/`
- Shared components under `shared/widgets`
- Runtime state under `core/` or feature-specific providers
- No duplicate screen families for the same business domain

## Database Normalization Report

Phase 22 adds these system-level tables:

```text
system_modules
translation_entries
analytics_metric_snapshots
system_audit_findings
audit_integrity_checkpoints
```

These tables are intentionally separate from operational tables. They do not duplicate orders, payments, support, reviews, delivery, or accounting logic.

## Backend Refactor Implemented

New Admin endpoints:

```text
GET  /admin/system-hardening/overview
GET  /admin/system-hardening/naming
GET  /admin/system-hardening/modules
PATCH /admin/system-hardening/findings/:id/resolve
GET  /admin/i18n/catalog
PUT  /admin/i18n/catalog/:key
GET  /admin/analytics/snapshots
POST /admin/analytics/snapshots/refresh
POST /admin/audit-logs/integrity-checkpoint
```

The implementation reuses:

- JwtAuthGuard
- PermissionsGuard
- AuditService
- AdminService
- System settings

## Frontend Restructuring Implemented

Added:

```text
features/admin/presentation/pages/admin_system_hardening_page.dart
```

Updated:

```text
core/config/api_endpoints.dart
app/router/route_names.dart
app/router/app_router.dart
features/admin/data/admin_repository.dart
features/admin/presentation/pages/admin_settings_page.dart
core/i18n/app_localizations.dart
```

## Unified Admin Control Center Design

Phase 22 adds a registry-backed model for admin modules:

```text
system_modules.code
system_modules.name_ar
system_modules.name_en
system_modules.route
system_modules.permission_code
system_modules.group_code
```

This allows future modules to be controlled from data rather than scattered hardcoded page lists.

## Global i18n Architecture Fix

The app already supports runtime Arabic/English switching. Phase 22 adds database-backed runtime translation catalog readiness:

```text
translation_entries.translation_key
translation_entries.locale
translation_entries.value
translation_entries.namespace
translation_entries.platform
```

This supports:

- UI text migration to keys
- Notification localization
- Admin-managed wording
- Future validation message catalog

## Analytics Centralization Design

Added snapshot table:

```text
analytics_metric_snapshots
```

This enables:

- Pre-aggregated metrics
- Dashboard fast loading
- Historical metric storage
- Future BI/export integration

## Security Hardening Report

Phase 22 adds:

- RBAC-protected hardening endpoints
- Audit logs for translation changes
- Audit logs for analytics refresh
- Audit logs for integrity checkpoint creation
- Centralized module visibility by permission
- Audit checksum checkpoint

Existing controls preserved:

- Helmet
- Validation pipe
- Exception filter
- JWT auth
- Permissions guard
- Audit service

## Performance Optimization Plan

Implemented:

- Analytics snapshot endpoint
- Registry-based admin modules
- Indexed system tables
- Naming report via information_schema
- Paginated translation and snapshot endpoints

Recommended later:

- Scheduled worker for metric snapshots
- Redis cache for public settings/translations
- BI export pipeline
- Slow query monitoring

## Final Production-Ready Phase 22 Architecture

Ghiyarak now has a system-level unification layer for:

- Admin module registry
- Runtime translation catalog
- Analytics metric snapshots
- Architecture audit findings
- Audit log integrity checkpoints
- Naming standard reporting

This hardening phase preserves backward compatibility while preparing the platform for enterprise-scale administration and operations.
