# Ghiyarak Payment & Financial Foundation

## Scope

This document covers the production-safe payment foundation added for the Ghiyarak Electronic Platform. It intentionally avoids full accounting ledger implementation, delivery driver settlement automation, and real gateway SDK integration. Those remain future phases.

## Existing Codebase Assessment

The existing project already included:

- OTP authentication and refresh-token based access.
- RBAC permissions and guards.
- Organizations, branches, employees, and approval workflow.
- Cart and order management.
- Workshop service orders.
- Notifications, audit logs, and domain events.
- A legacy `payment_transactions` table used for simple manual payment tracking.
- A central invoice table mapped as `commerce_invoices`.

The previous payment layer was useful as a placeholder but not enough for real financial operations because it did not model payment methods, attempts, uploaded proofs, webhook verification, refunds, or settlements separately.

## Critical Issues Found

| Severity | Issue | Impact | Fix Applied |
|---|---|---|---|
| CRITICAL | Payment confirmation could be too manual/simple | Risk of financial inconsistency | Added payment intent, proof review, webhook-ready flow, and backend-only confirmation |
| CRITICAL | No payment webhook model | Future gateway callbacks would be unsafe | Added `payment_webhooks` with signature verification and idempotency |
| HIGH | No payment methods table | Hard to add real providers later | Added `payment_methods` configuration table |
| HIGH | No bank transfer proof workflow | Finance cannot review evidence reliably | Added `payment_proofs` and finance approval/rejection APIs |
| HIGH | No payment attempts | Gateway/provider retries cannot be traced | Added `payment_attempts` |
| HIGH | Refund and settlement readiness missing | Future accounting would be blocked | Added minimal `refunds` and `settlements` foundation |
| MEDIUM | Legacy transaction model too narrow | Harder to expand safely | Extended existing `payment_transactions` while preserving compatibility |

## Architecture Compatibility

The implementation reuses the current architecture:

- Existing NestJS module pattern.
- Existing Prisma database layer.
- Existing `PaymentsModule` instead of creating a duplicate module.
- Existing `AuditService`.
- Existing `EventBusService`.
- Existing `NotificationsService`.
- Existing RBAC permissions.
- Existing Flutter repository/navigation structure.

The legacy `payment_transactions` table remains available for backward compatibility, but it is now connected to invoices, payment methods, attempts, proofs, refunds, and future webhooks.

## Database Changes

Added or expanded:

- `payment_methods`
- `payment_attempts`
- `payment_proofs`
- `payment_webhooks`
- `refunds`
- `settlements`
- `payment_transactions`
- `commerce_invoices`

### Important Constraints

- `payment_methods.code` is unique.
- `payment_transactions.internal_reference` is unique.
- `payment_transactions.idempotency_key` is unique when present.
- `payment_webhooks.idempotency_key` is unique.
- `refunds.refund_number` is unique.
- `settlements.settlement_number` is unique.

### Default Payment Methods

Seeded payment methods:

- `CASH_ON_PICKUP`
- `CASH_ON_DELIVERY`
- `BANK_TRANSFER`
- `LOCAL_WALLET`
- `PAYMENT_GATEWAY`

## Payment Flows

### Cash on Delivery / Pickup

1. Customer selects COD or cash pickup.
2. Backend creates a payment intent.
3. Payment status becomes `PENDING_COD`.
4. Payment is confirmed later by finance/operations after collection.
5. Invoice becomes `PAID` only after backend confirmation.

### Bank Transfer

1. Customer creates a payment intent with `BANK_TRANSFER`.
2. Status becomes `WAITING_PROOF`.
3. Customer uploads proof.
4. Status becomes `UNDER_REVIEW`.
5. Finance approves or rejects.
6. Approved proof confirms the payment and marks the invoice as `PAID`.
7. Rejected proof marks the payment/order as rejected or failed.

### Local Wallet Providers

Local wallets use the same proof-review foundation now, with provider configuration separated so a real provider API can be added later without redesign.

### Future Payment Gateway

1. Backend creates a payment intent.
2. `payment_attempts` stores gateway attempts.
3. Gateway calls `POST /payments/webhooks/:provider`.
4. Backend verifies HMAC signature.
5. Backend validates amount, currency, and payment reference.
6. Backend processes the webhook only once using idempotency.
7. Payment confirmation is backend-only.

## API Changes

### Customer APIs

- `GET /payments/methods`
- `POST /payments/orders/:id/intents`
- `POST /payments/orders/:id/transactions` backward-compatible alias
- `GET /payments/orders/:id/transactions`
- `GET /payments/my`
- `POST /payments/:id/proofs`
- `POST /refunds`

### Finance APIs

- `GET /finance/payments`
- `GET /finance/payment-proofs`
- `POST /finance/payment-proofs/:id/approve`
- `POST /finance/payment-proofs/:id/reject`
- `GET /finance/refunds`
- `POST /finance/refunds/:id/approve`
- `POST /finance/refunds/:id/reject`
- `POST /finance/refunds/:id/mark-refunded`
- `GET /finance/settlements`
- `POST /finance/settlements`
- `POST /finance/settlements/:id/approve`
- `POST /finance/settlements/:id/mark-paid`

### Webhook API

- `POST /payments/webhooks/:provider`

Webhook signature header:

```text
x-payment-signature: sha256=<hmac-sha256>
```

Environment variables:

```env
PAYMENT_WEBHOOK_SECRET="CHANGE_ME_PAYMENT_WEBHOOK_SECRET_MIN_32_CHARS"
PAYMENT_WEBHOOK_SECRET_PAYMENT_GATEWAY="optional provider-specific secret"
PAYMENT_WEBHOOK_SECRET_LOCAL_WALLET="optional provider-specific secret"
```

## Security Review

Applied controls:

- Backend-only payment confirmation.
- Proof approval requires `finance.payments.review`.
- Finance dashboards require `finance.payments.review`.
- Customer payment data is restricted to the payer.
- Webhooks require HMAC signature verification.
- Webhooks use idempotency keys.
- Amount and currency are validated before webhook confirmation.
- Financial actions create audit logs.
- Customer notifications are sent for important payment events.

## UI/UX Additions

Added Flutter screens:

- Payment selection screen.
- Payment status screen.
- Proof upload flow.
- Finance proof review screen.
- Finance refunds screen.
- Finance settlements screen.

Existing order details screen now exposes a payment button when the order is not paid.

All screens include simple loading, error, and empty states consistent with the current Flutter style.

## Performance Considerations

- Finance queries are paginated with `take` and `skip` limits.
- Payment tables have indexes for status/date/provider/reference lookups.
- Webhook processing is idempotent to avoid duplicate updates.
- Proof review queries include only necessary related records.
- Default maximum list size is limited to protect dashboards.

## Future Accounting Compatibility

This phase is accounting-ready but does not create double-entry ledger records yet.

Future accounting can safely consume:

- Confirmed payment transactions.
- Paid invoices.
- Refund requests and completed refunds.
- Settlements by organization and period.
- Payment attempts and webhook logs for reconciliation.

The future ledger phase should create immutable journal entries from confirmed payments, refunds, and paid settlements.

## Phase Boundary

This phase does not include:

- Real payment gateway SDK integration.
- Double-entry accounting ledger.
- Automated delivery settlement.
- Advanced coupon/refund policies.
- Bank API reconciliation.
