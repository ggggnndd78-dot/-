# 04 Event Catalog

Core events for phases 0 to 4:

```text
OtpRequested
OtpVerified
CustomerRegistered
MerchantOnboardingSubmitted
WorkshopOnboardingSubmitted
WarehouseOnboardingSubmitted
VerificationApproved
VerificationRejected
EmployeeInvited
EmployeeActivated
NotificationDispatched
```

Rules:

- Events describe business facts.
- Sensitive operations create audit logs.
- Admin approval/rejection must create notification and audit records.


## Phase 5 Verification Events

```text
VerificationApproved
VerificationRejected
VerificationDocumentsRequired
VerificationSuspended
```

كل حدث يكتب في Audit Log عن طريق EventBus، ويستخدم لإطلاق الإشعارات الداخلية والإيميل وتحديث حالة المؤسسة.

## Phase 6 Persisted Event Foundation

In Phase 6, core events are persisted to:

```text
domain_events
event_outbox
event_logs
```

Current connected events:

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

Boundary:

```text
This phase records and queues events only. It does not introduce background workers, accounting, payments, or future-phase dispatch logic.
```
