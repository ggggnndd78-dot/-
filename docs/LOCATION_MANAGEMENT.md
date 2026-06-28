# Ghiyarak Location Management

This document describes the location foundation implemented for the Ghiyarak Electronic Platform.

## Scope

The implemented scope is intentionally limited to location management:

- Default Yemen country and city data.
- City, district, and area lookup APIs.
- Customer address management.
- Admin city management.
- Delivery zones and delivery fees by city.

No marketplace, order, payment, accounting, or delivery tracking logic is added here.

## Default Yemeni cities

The seed data includes:

- صنعاء
- عدن
- تعز
- الحديدة
- إب
- المكلا
- ذمار
- مأرب
- سيئون
- عمران
- صعدة
- البيضاء

## Database tables

The location foundation uses:

- `geo_countries`
- `geo_states`
- `geo_cities`
- `geo_districts`
- `geo_areas`
- `addresses`
- `delivery_zones`
- `city_delivery_fees`

## Public APIs

```http
GET /api/v1/locations/countries
GET /api/v1/locations/states
GET /api/v1/locations/cities
GET /api/v1/locations/districts?cityId=1
GET /api/v1/locations/areas?districtId=1
GET /api/v1/locations/delivery-fees?cityId=1
GET /api/v1/locations/delivery-zones?cityId=1
```

## Authenticated customer APIs

```http
GET /api/v1/locations/addresses/my
POST /api/v1/locations/addresses
PATCH /api/v1/locations/addresses/:id
DELETE /api/v1/locations/addresses/:id
```

## Admin APIs

The admin APIs require `manage_location` permission.

```http
GET /api/v1/locations/admin/cities
POST /api/v1/locations/admin/cities
PATCH /api/v1/locations/admin/cities/:id
POST /api/v1/locations/admin/cities/:cityId/districts
PATCH /api/v1/locations/admin/districts/:id
PUT /api/v1/locations/admin/cities/:cityId/delivery-fee
GET /api/v1/locations/admin/delivery-zones
POST /api/v1/locations/admin/delivery-zones
PATCH /api/v1/locations/admin/delivery-zones/:id
```

## Flutter additions

- City selection continues to use the existing location selection page.
- Customer addresses are handled through `MyAddressesPage`.
- Admin city delivery fees are handled through `AdminLocationsPage`.

## Notes

This implementation is production-oriented and minimal. It prepares the platform for future business flows without introducing future order, payment, or delivery tracking behavior.
