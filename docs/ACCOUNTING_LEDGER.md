# Ghiyarak Accounting Ledger & Financial Integrity

This document describes the Phase 16 accounting foundation implemented for Ghiyarak.

## Scope

This phase adds a production-safe accounting layer for financial traceability. It does not replace payment, settlement, or refund modules. It posts accounting effects when those modules complete financial actions.

## Core Tables

- `ledger_accounts`
- `journal_entries`
- `journal_entry_lines`
- `financial_transactions`
- `merchant_balances`
- `refund_entries`

## Accounting Rules

- Every journal entry must be balanced: total debit equals total credit.
- Journal entries are immutable after posting.
- Duplicate posting is prevented through idempotency keys.
- Financial source records are traceable to payment, order, invoice, refund, or settlement where available.
- Merchant balances are updated only when a new accounting post is created.

## Default Chart of Accounts

| Code | Arabic Name | Type | Normal Balance |
|---|---|---|---|
| 1000 | النقدية | ASSET | DEBIT |
| 1010 | الحسابات البنكية | ASSET | DEBIT |
| 1100 | الذمم المدينة | ASSET | DEBIT |
| 1200 | أصول المحافظ | ASSET | DEBIT |
| 2000 | مستحقات التجار والورش | LIABILITY | CREDIT |
| 2100 | التزامات محافظ العملاء | LIABILITY | CREDIT |
| 2200 | التزامات الاسترداد | LIABILITY | CREDIT |
| 4000 | إيرادات السوق | REVENUE | CREDIT |
| 4100 | إيرادات الخدمات | REVENUE | CREDIT |
| 4200 | إيرادات التوصيل | REVENUE | CREDIT |
| 5000 | مصروفات الاسترداد | EXPENSE | DEBIT |
| 5100 | مصروفات تشغيلية | EXPENSE | DEBIT |

## Posting Events

### Payment Confirmed

Debit:
- Cash / Bank / Wallet Asset

Credit:
- Merchant and Workshop Payables

### COD Delivered

Debit:
- Cash

Credit:
- Merchant and Workshop Payables

### Refund Completed

Debit:
- Merchant and Workshop Payables

Credit:
- Cash

### Settlement Paid

Debit:
- Merchant and Workshop Payables

Credit:
- Bank Accounts

## API Endpoints

- `POST /finance/accounting/initialize-chart`
- `GET /finance/accounting/accounts`
- `GET /finance/accounting/accounts/:id/ledger`
- `GET /finance/accounting/journal-entries`
- `GET /finance/accounting/journal-entries/:id`
- `GET /finance/accounting/financial-transactions`
- `GET /finance/accounting/merchant-balances`

## Required Permission

All accounting endpoints require:

```text
finance.accounting.manage
```

## Integration Points

- Payment proof approval posts `PAYMENT_CONFIRMED` journal.
- Manual payment confirmation posts `PAYMENT_CONFIRMED` journal.
- Gateway/webhook payment confirmation posts `PAYMENT_CONFIRMED` journal through the same confirmation function.
- COD delivered from merchant order workflow posts `COD_DELIVERED` journal.
- Completed refunds post `REFUND_COMPLETED` journal.
- Paid settlements post `SETTLEMENT_PAID` journal.

## Production Notes

- Accounting entries are not deleted.
- Reversal entries should be added in a future advanced finance phase if manual corrections are needed.
- This phase intentionally avoids a full ERP accounting UI and focuses on a safe ledger foundation.
