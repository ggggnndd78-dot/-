# 05 Finance and Accounting Rules

Finance is not fully implemented in phases 0 to 4. This file reserves the required future constraints:

- No fake payment flow in production.
- Every payment must have a traceable reference.
- Every invoice must have a sequence.
- Future ledger entries must be immutable.
- Reversals must be done through reverse entries, not deletion.

