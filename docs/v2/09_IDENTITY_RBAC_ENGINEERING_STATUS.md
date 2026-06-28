# Ghiyarak Enterprise v2.0 — Phase 1 + Phase 2 Engineering Status

## Scope completed in this package

This package starts the real Enterprise v2 foundation under a root folder named `ghiyarak`.

### Backend foundation
- Kept the current NestJS + Prisma + MySQL architecture.
- Added `CommunicationsModule` with real-provider-ready Email and SMS delivery services.
- Added OTP delivery abstraction used by Auth.
- Added internal `EventBusModule` for event-driven operations.
- Connected auth flows to domain events and audit logs.
- Extended OTP to support phone or email.
- Added hashed OTP storage, expiry, max attempts, and consumed-state behavior.
- Added employee-management foundation for approved merchants, workshops, and warehouses.
- Added Prisma models/migration for employee invitations, employee permissions, and branch access.

### Identity and RBAC foundation
- Roles expanded for customer, merchant owner/employee, workshop owner/employee, warehouse owner/employee, driver, support, finance, content, admin.
- Permissions expanded for merchant, workshop, warehouse, finance, support, content, delivery, and admin operations.
- Auth payload includes roles, permissions, organizations, and organization verification status.

### Event-driven foundation
- OtpRequested
- OtpVerified
- GuestSessionCreated
- EmployeeInvited
- EmployeePermissionsUpdated

These events are currently published through an internal in-process event bus and written to audit logs. Later phases will extend this to an outbox table for resilient async workers.

## Important production behavior

Email and SMS OTP providers are not fake in production:
- In development, if provider URLs are empty, messages are logged for local testing.
- In production, if provider URLs are not configured, OTP delivery fails safely.

## Next package

`Ghiyarak Enterprise v2.1` will focus on:
- Onboarding UI/flows for Customer, Merchant, Workshop, Warehouse.
- Admin verification workflow connected to email/app notifications.
- Role-based Flutter routing for Android/Web/Windows.
