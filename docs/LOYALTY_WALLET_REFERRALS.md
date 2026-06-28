# Ghiyarak — Loyalty, Wallet, Coupons & Referral System

## Scope

This document describes the Phase 20 implementation for customer engagement and rewards. It builds on the existing orders, workshop services, payments, accounting, notifications, RBAC, and audit logs without redesigning previous phases.

## Implemented Capabilities

- Customer wallet accounts and wallet ledger entries.
- Wallet top-up requests with finance approval.
- Wallet payment for marketplace orders and service orders.
- Loyalty accounts, point earning, redemption, and reversal.
- Coupon validation and redemption for orders and service orders.
- Coupon controls for expiration, global/per-user limits, minimum value, free delivery, stackability flag, and eligible target lists.
- Referral codes, referral relationships, and referral rewards.
- Notifications for wallet, loyalty, coupon, and referral events.
- Audit logs for financial-impacting reward actions.

## Main Backend Endpoints

### Wallet

```text
GET    /wallet/me
GET    /wallet/me/ledger
POST   /wallet/me/topups
PATCH  /wallet/topups/:transactionId/approve
POST   /wallet/orders/:id/pay
POST   /wallet/service-orders/:id/pay
POST   /wallet/admin/adjust
```

### Loyalty & Coupons

```text
GET    /loyalty/me
GET    /loyalty/me/transactions
POST   /loyalty/redeem-to-wallet
POST   /loyalty/orders/:id/reward
POST   /loyalty/orders/:id/reverse
POST   /loyalty/service-orders/:id/reward
GET    /loyalty/coupons
GET    /loyalty/coupons/manage
POST   /loyalty/coupons
PATCH  /loyalty/coupons/:id/status
POST   /loyalty/coupons/validate
POST   /loyalty/orders/:id/coupons/redeem
POST   /loyalty/service-orders/:id/coupons/redeem
```

### Referrals

```text
GET    /referrals/me
POST   /referrals/me/code
POST   /referrals/apply
POST   /referrals/:relationshipId/qualify
```

### Retention Campaigns

```text
GET    /retention/campaigns/manage
POST   /retention/campaigns
POST   /retention/campaigns/:id/dispatch
```

## Database Changes

Phase 20 hardens existing wallet/loyalty tables and adds referral tables:

```text
wallet_ledger_entries.idempotency_key
loyalty_point_transactions.idempotency_key
loyalty_coupon_redemptions.idempotency_key
loyalty_coupons.stackable
loyalty_coupons.eligible_category_ids_json
loyalty_coupons.eligible_service_ids_json
loyalty_coupons.eligible_merchant_ids_json
loyalty_coupons.eligible_workshop_ids_json
referral_codes
referral_relationships
referral_rewards
```

## Financial Integrity Rules

- Wallet debits cannot create negative balances.
- Wallet and loyalty movements support idempotency keys.
- Coupon usage is counted and restricted by global/per-user limits.
- Referral rewards are granted once per relationship through unique idempotency keys.
- All wallet, loyalty, coupon, and referral actions write audit records where the action has financial or reputation impact.

## Security Rules

- Customers can only access their own wallet, points, coupons, and referrals.
- Admin/finance roles manage wallet adjustments, coupons, referral qualification, and campaigns.
- Self-referrals are blocked.
- Duplicate referrals are blocked using one referral relationship per referred user.

## Flutter Screens

- Customer wallet dashboard.
- Customer loyalty and coupon screen.
- Customer referral dashboard.
- Admin coupon management screen.
- Retention campaign screen.

## Future Integration Notes

- Accounting integration can post wallet movements as financial transactions in a later hardening sprint.
- Advanced campaign segmentation can be added without changing the referral or coupon schema.
- Coupon eligibility currently uses JSON ID lists to avoid over-modeling while keeping future expansion possible.
