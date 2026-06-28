# Cart and Order Management

This release completes the marketplace cart and order scope for Ghiyarak without adding payment gateway, accounting ledger, delivery driver, refund, or workshop booking logic.

## Scope

- Customer cart management.
- Multi-seller cart checkout.
- Automatic split of checkout into separate seller-scoped orders.
- Customer-only order creation.
- Merchant view limited to orders belonging to their organization.
- Admin view for full order records.
- Order status history for every status change.
- Basic invoice records after successful checkout.
- Practical coupon support through existing loyalty coupon tables.
- Consistent stock reservation, release, and sold-stock movement records.
- Audit logging for important cart/order operations.

## Main Tables

- `commerce_carts`
- `commerce_cart_items`
- `commerce_orders`
- `commerce_order_items`
- `commerce_order_status_history`
- `commerce_invoices`
- `commerce_order_fees`
- `loyalty_coupons`
- `loyalty_coupon_redemptions`
- `stock_movements`

Compatibility views are also created using the requested business names when supported by the migration:

- `carts`
- `cart_items`
- `orders`
- `order_items`
- `order_status_history`
- `invoices`
- `order_fees`
- `coupons`

## Order Statuses

- `PENDING`
- `CONFIRMED`
- `PROCESSING`
- `READY_FOR_PICKUP`
- `OUT_FOR_DELIVERY`
- `DELIVERED`
- `CANCELLED`
- `RETURN_REQUESTED`
- `REFUNDED`

## Security Rules

- Guests cannot checkout.
- Checkout requires authentication and the `orders.create` permission.
- Cart APIs require authentication and the `cart.manage` permission.
- Customer order viewing requires `orders.view_own` and is scoped to the authenticated user.
- Merchants require `merchant.orders.manage` and can only see orders for their organization.
- Merchants cannot update orders outside their organization.
- Admin order APIs require `admin.orders.view`.
- Order totals are calculated server-side.
- Stock is checked server-side before checkout.
- Order creation is transactional.
- If any item is unavailable or out of stock, checkout fails safely.

## Stock Handling

- Checkout reserves stock using `reservedQuantity` on listing and listing inventory.
- Checkout writes `ORDER_RESERVED` stock movement records.
- Customer, merchant, or admin cancellation releases reserved stock.
- Cancellation writes `ORDER_RESERVATION_RELEASED` stock movement records.
- Delivery converts reserved stock to sold stock and writes `ORDER_SOLD` stock movement records.

## Backend APIs

Customer:

- `GET /cart`
- `POST /cart/items`
- `PATCH /cart/items/:id`
- `DELETE /cart/items/:id`
- `DELETE /cart`
- `POST /checkout/preview`
- `POST /orders`
- `GET /orders/my`
- `GET /orders/:id`
- `PATCH /orders/:id/cancel`

Merchant:

- `GET /merchant/orders`
- `GET /merchant/orders/:id`
- `PATCH /merchant/orders/:id/status`

Admin:

- `GET /admin/orders`
- `GET /admin/orders/:id`
- `PATCH /admin/orders/:id/status`

## Flutter Screens

Customer:

- Cart page.
- Checkout preview page.
- My orders page.
- Order details page.

Merchant:

- Merchant orders page.
- Merchant order details page.
- Status update actions.

Admin:

- Admin orders page.
- Admin order details page.
- Status update actions.

## Notes

This scope intentionally does not implement payment settlement, accounting entries, delivery shipment creation, refund processing, advanced coupon rules, or workshop bookings. Those belong to later phases.
