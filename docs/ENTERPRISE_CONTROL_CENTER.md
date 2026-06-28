# Ghiyarak Enterprise Control Center

## Scope
Phase 21 adds a unified bilingual administration layer for all completed phases.

## Backend
- `/admin/control-center` returns permission-aware modules and KPI cards.
- `/admin/analytics/enterprise` returns cross-domain grouped metrics.
- `/admin/localization` exposes localization settings.
- `/admin/feature-flags` manages feature switches through existing `system_settings`.

## Frontend
- Runtime Arabic/English switching via Riverpod and SharedPreferences.
- RTL/LTR direction adapts without rebuilding separate apps.
- Admin control center uses responsive enterprise cards and design tokens.

## Security
All endpoints are protected through existing JWT + PermissionsGuard. Sensitive updates write audit logs.

## Performance
The dashboard uses bounded count/group queries and avoids unpaginated detail loading. Large module lists remain navigation metadata only.
