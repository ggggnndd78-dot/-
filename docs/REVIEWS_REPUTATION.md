# Ghiyarak Reviews & Reputation Management

## Existing Codebase Assessment

Phase 18 already had basic reviews inside the Support module. The audit found that the old flow was too permissive for production because review creation could be attempted without a strict completed order or completed service order reference. Phase 19 keeps backward compatibility for legacy `/support/reviews/*` endpoints, but introduces the enterprise-grade `/reviews/*` module and routes all legacy creation/moderation through the stronger review rules.

## Critical Issues Corrected

| Severity | Issue | Correction |
|---|---|---|
| CRITICAL | Reviews could be created without reliable purchase/service eligibility. | Product/merchant reviews now require a delivered order; workshop/service reviews require a completed service order. |
| HIGH | No service_reviews table. | Added `review_service_reviews`. |
| HIGH | No replies, moderation history, media, or reputation summary tables. | Added replies, media, moderation actions, and reputation summaries. |
| HIGH | Average ratings were recalculated from the last page of reviews only. | Added incremental reputation summary recomputation after review/moderation actions. |
| HIGH | Weak anti-abuse rules. | Added duplicate prevention, self-review prevention, organization reply ownership, and audit logs. |

## Database Changes

Added:

- `review_service_reviews`
- `review_media`
- `review_replies`
- `review_moderation_actions`
- `review_reputation_summaries`

Updated Prisma relations for:

- Users
- Organizations
- Products
- Orders
- Workshop service orders
- Workshop services

## Review Eligibility

### Product Review

Allowed only when:

- The user owns the order.
- The order status is `DELIVERED`.
- The order contains the reviewed product.
- The user is not a member of the seller organization.

### Merchant Review

Allowed only when:

- The user owns the order.
- The order status is `DELIVERED`.
- The order belongs to the reviewed merchant organization.
- The user is not a member of that organization.

### Workshop Review

Allowed only when:

- The user owns the service order.
- The service order status is `COMPLETED`.
- The service order belongs to the reviewed workshop organization.
- The user is not a member of that organization.

### Service Review

Allowed only when:

- The user owns the completed service order.
- The service order has been completed.

## API Changes

New production review APIs:

```text
POST   /reviews/products
POST   /reviews/merchants
POST   /reviews/workshops
POST   /reviews/services
GET    /reviews/my
POST   /reviews/reply
POST   /reviews/report
PATCH  /reviews/moderation
GET    /reviews/admin
GET    /reviews/products/:productId
GET    /reviews/merchants/:organizationId
GET    /reviews/workshops/:organizationId
GET    /reviews/services/:workshopServiceId
GET    /reviews/reputation/:targetType/:targetId
```

Legacy support review APIs remain for compatibility, but now delegate to the hardened review service.

## Security

- Customers can create reviews only for verified completed transactions.
- Customers cannot self-review their own organizations.
- Merchants and workshops can reply only to reviews belonging to their organization.
- Support/admin users can moderate reviews.
- Every review, reply, report, and moderation action writes audit logs.

## Reputation Engine

Reputation summaries include:

- Average rating
- Total reviews
- Rating distribution 1–5
- Reputation score

This prevents expensive aggregation on every public product/merchant/workshop page.

## Flutter Updates

Updated the Reviews screen to support:

- Product reviews
- Merchant reviews
- Workshop reviews
- Service reviews
- Admin moderation view
- Hide/restore moderation actions
- Verified transaction input fields

## Production Notes

The current implementation is a production-safe foundation. Future enhancements may add:

- Video reviews
- Multilingual reviews
- Rich image upload integration with private file storage
- Moderation queues by severity
- Review-linked complaint escalation
- Advanced reputation analytics dashboards
