# Workshop Booking System

## Scope

This document describes the production-safe workshop service and booking implementation for Ghiyarak Electronic Platform.

The implementation focuses only on workshop services and bookings. It does not implement payment gateways, accounting ledger, delivery drivers, refunds, or advanced finance flows.

## Current Codebase Assessment

The existing codebase already had a workshop foundation with:

- Workshop service management
- Workshop technicians
- Workshop bookings
- Service orders
- Diagnostic reports
- Maintenance records
- Customer maintenance screen
- Workshop operations screens

The audit found that the foundation was usable, but Phase 14 required stabilization in the following areas:

- Missing normalized service categories and master service catalog
- Missing workshop branch metadata for booking settings
- Missing booking slots with capacity control
- Booking creation was not protected against double booking
- Workshop operation endpoints needed explicit permission decorators
- Customer booking actions needed a customer-only permission
- Workshop actions needed audit logging
- Flutter booking flow needed date and slot selection

## Critical Issues Addressed

### Booking concurrency

- Severity: CRITICAL
- Problem: Two customers could request the same time without a slot-level capacity check.
- Fix: Added `booking_slots` and transactional slot booking using `updateMany` with `bookedCount < capacity`.

### Missing workshop service catalog

- Severity: HIGH
- Problem: Services were mostly free-form workshop entries.
- Fix: Added `service_categories` and `services` master catalog with the required default services.

### Weak permission enforcement

- Severity: HIGH
- Problem: Existing workshop controller depended mainly on authentication and service checks.
- Fix: Added `PermissionsGuard` and `@RequirePermissions` on customer and workshop operations.

### Missing audit trail

- Severity: HIGH
- Problem: Workshop booking and service operations had limited audit coverage.
- Fix: Added safe audit logging to booking slot creation, service creation/update, technician creation, booking creation/cancellation/status updates, service orders, diagnostics, maintenance records, and reviews.

## Database Changes

Added:

- `service_categories`
- `services`
- `workshop_branches`
- `booking_slots`

Updated:

- `workshop_services.service_id`
- `workshop_bookings.booking_slot_id`

Added enum:

- `BookingSlotStatus`: `AVAILABLE`, `FULL`, `CLOSED`

## Seed Data

The seed now includes the required workshop service catalog:

- Computer Diagnostics / فحص كمبيوتر
- Brake Replacement / تغيير الفحمات
- Oil Change / تغيير الزيوت
- Air Conditioning / التكييف
- Tires / الإطارات
- Polishing / التلميع
- Car Wash / الغسيل
- Body Repair / السمكرة
- Painting / الدهان
- Electrical Services / الكهرباء
- Mechanical Services / الميكانيكا
- General Inspection / الفحص العام

The seed also creates sample booking slots for the sample approved workshop when available.

## API Changes

Customer/public workshop APIs:

- `GET /workshops/service-categories`
- `GET /workshops/catalog-services`
- `GET /workshops/services`
- `GET /workshops/services/:id`
- `GET /workshops/booking-slots`
- `POST /workshops/bookings`
- `GET /workshops/bookings/my`
- `GET /workshops/bookings/:id`
- `PATCH /workshops/bookings/:id/cancel`
- `POST /workshops/bookings/:id/rating`
- `GET /workshops/maintenance-records/my`

Workshop operation APIs:

- `GET /workshop/operations/services`
- `POST /workshop/operations/services`
- `PATCH /workshop/operations/services/:id`
- `PATCH /workshop/operations/services/:id/status`
- `GET /workshop/operations/technicians`
- `POST /workshop/operations/technicians`
- `GET /workshop/operations/booking-slots`
- `POST /workshop/operations/booking-slots`
- `GET /workshop/operations/bookings`
- `PATCH /workshop/operations/bookings/:id/status`
- `POST /workshop/operations/bookings/:id/service-order`
- `GET /workshop/operations/service-orders`
- `PATCH /workshop/operations/service-orders/:id/status`
- `POST /workshop/operations/service-orders/:id/diagnostics`
- `POST /workshop/operations/service-orders/:id/maintenance-record`

## Security Considerations

- Customer booking requires `workshop.bookings.create`.
- Workshop management requires workshop operation permissions.
- Workshop organization must be approved before services, slots, and bookings can operate.
- Workshop employee access is checked against organization and branch scope.
- Booking slot creation checks active branch access.
- Customers cannot book with vehicles that do not belong to them.
- Customers cannot cancel or rate bookings that do not belong to them.
- Terminal bookings and service orders cannot be modified incorrectly.

## Performance Considerations

- Booking slot lookup is indexed by organization, branch, date, status, and service.
- Slot booking uses a single transactional update to prevent overbooking.
- Workshop operation list endpoints limit booking slot results to a reasonable page size.
- Service catalog is normalized for future caching.

## Flutter Changes

Customer:

- Customer maintenance page now supports date selection.
- Customer can select available booking slots.
- Customer can create booking with a slot or fallback preferred time.
- Customer can cancel REQUESTED/CONFIRMED bookings.
- Customer can submit a simple rating after completion.

Workshop:

- Workshop services screen can create a default booking slot for tomorrow.
- Repository supports service categories, booking slots, slot creation, cancellation, and rating.

## Migration

Migration added:

```text
backend/prisma/migrations/20260624060000_workshop_booking_system/migration.sql
```

Run after installing dependencies:

```bash
cd backend
npm install
npx prisma migrate dev
npx prisma generate
npm run start:dev
```

## QA Checklist

- Customer can view workshop services.
- Customer can select date and available slot.
- Customer cannot book a past slot.
- Customer cannot book full slot.
- Booking increments slot booked count.
- Slot becomes FULL when capacity is reached.
- Customer cancellation releases slot count.
- Workshop can create booking slot.
- Workshop can confirm booking.
- Workshop can create service order.
- Workshop can complete service order.
- Customer can rate only completed booking.
- Audit logs are written for critical actions.

## Known Local Build Notes

This package does not include `node_modules` or Flutter generated tool state. Backend and Flutter builds must be run after dependency installation on the developer machine.
