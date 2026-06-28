# Ghiyarak Delivery & Logistics Management

## Scope

This document defines the production-safe Phase 17 delivery and logistics implementation.

The module supports:

- Store pickup
- Internal driver delivery
- External driver delivery
- Local shipping companies
- City and branch delivery fee rules
- Shipment tracking
- Driver-only shipment access
- Merchant shipment management
- Admin shipment visibility
- COD delivery compatibility with payment/accounting

## Database Additions

New tables:

- `delivery_drivers`
- `delivery_local_shipping_companies`
- `delivery_fees`

Extended tables:

- `delivery_methods`
- `delivery_shipments`
- `delivery_shipment_tracking_events`

## Shipment Lifecycle

Supported shipment statuses:

- `PENDING`
- `READY_FOR_PICKUP`
- `PICKED_UP`
- `IN_TRANSIT`
- `OUT_FOR_DELIVERY`
- `DELIVERED`
- `FAILED`
- `CANCELLED`
- `RETURNED`

Allowed transitions are enforced in backend service logic.

## Security Rules

- Customer can see only shipments related to their own orders.
- Driver can see and update only shipments assigned to their driver profile.
- Merchant/workshop/warehouse staff can manage shipments only for their organization.
- Admin operations can see and manage all shipments.
- Every shipment creation, assignment, driver acceptance, and status update is audited.

## COD + Accounting Compatibility

When a COD shipment is marked `DELIVERED`, the delivery service calls the accounting engine to confirm COD collection and post the ledger impact using the existing Phase 16 accounting service.

This avoids fake payment confirmation from the Flutter client.

## API Summary

### Lookup

- `GET /delivery/methods`
- `GET /delivery/fees`
- `GET /delivery/shipping-companies`

### Delivery Management

- `POST /delivery/orders/:id/shipments`
- `GET /delivery/merchant/shipments`
- `GET /delivery/admin/shipments`
- `GET /delivery/driver/shipments`
- `GET /delivery/shipments/:id`
- `PATCH /delivery/shipments/:id/assign`
- `PATCH /delivery/shipments/:id/driver-accept`
- `PATCH /delivery/shipments/:id/status`

### Drivers

- `GET /delivery/drivers`
- `POST /delivery/drivers`
- `PATCH /delivery/drivers/:id`

### Shipping Companies

- `POST /delivery/shipping-companies`
- `PATCH /delivery/shipping-companies/:id`

### Delivery Fees

- `POST /delivery/fees`

## Flutter Screens

Updated screen:

- `ShipmentsPage`

It now supports:

- Customer shipment tracking
- Merchant shipment management
- Driver assigned deliveries
- Admin shipment management

## Production Notes

- External shipping API integration is intentionally not implemented in this phase.
- Delivery fee rules are ready for city/branch/method logic and future distance-based pricing.
- Shipment tracking events are immutable operational records.
