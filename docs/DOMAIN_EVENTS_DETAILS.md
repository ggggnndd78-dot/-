# Phase 6 — Domain Events Foundation

## Scope

هذه المرحلة تضبط أساس الأحداث فقط، بدون Worker متقدم وبدون Payments وبدون Accounting وبدون أي انتقال لمراحل لاحقة.

## What was added

```text
domain_events
event_outbox
event_logs
```

## Backend files

```text
backend/src/common/events/domain-event.interface.ts
backend/src/common/events/event-bus.service.ts
backend/src/common/events/event-bus.module.ts
backend/src/modules/events/events.module.ts
backend/src/modules/events/events.controller.ts
backend/src/modules/events/events.service.ts
backend/prisma/migrations/20260624000000_phase6_domain_events/migration.sql
```

## EventBus behavior

When a service publishes a business event, the system now:

```text
1. Stores the business fact in domain_events
2. Creates a pending outbox record in event_outbox
3. Writes a recording log in event_logs
4. Writes an audit log entry
```

## Events currently connected

```text
OtpRequested
OtpVerified
GuestSessionCreated
MerchantOnboardingSubmitted
WorkshopOnboardingSubmitted
WarehouseOnboardingSubmitted
VerificationDocumentUploaded
VerificationApproved
VerificationRejected
VerificationDocumentsRequired
VerificationSuspended
```

## Admin inspection APIs

All endpoints require admin access with `view_audit_logs` permission:

```text
GET /api/v1/admin/events/domain
GET /api/v1/admin/events/outbox
GET /api/v1/admin/events/logs
```

Optional query parameters:

```text
name
aggregateType
aggregateId
status
eventId
take
skip
```

## Important boundary

This phase does not dispatch events to external systems yet. It only records and queues them safely so future phases can process them without rewriting current services.
