# Product Imports

This release adds a minimal production-oriented Excel product import workflow for approved merchants, workshops, warehouses, and super admins.

## Scope

The workflow covers:

- Downloading the default Excel template.
- Uploading an Excel/CSV file.
- Reading headers and rows.
- Auto-mapping known columns.
- Validating rows before saving.
- Showing valid rows and row-level errors.
- Confirming the import.
- Creating products, compatibilities, listings, listing inventory, prices, and stock movements.
- Recording domain events for upload, parse, validation failure, completion, and partial completion.

## Required columns

```text
product_name
part_number
category
brand
vehicle_brand
vehicle_model
year_from
year_to
condition_type
quality_type
price_yer
stock_quantity
city
branch
description
```

## Access rules

Allowed only for:

- Approved merchant organization.
- Approved workshop organization.
- Approved warehouse organization.
- Super admin.

Denied when:

- Organization is not approved.
- User has no organization access.
- User lacks import/inventory/product permissions.
- Branch is missing or not owned by the organization.
- File is invalid.
- Required columns are missing.
- Rows contain invalid values.

## Backend endpoints

```text
GET  /api/v1/product-imports/template
GET  /api/v1/product-imports/jobs
GET  /api/v1/product-imports/jobs/:id
GET  /api/v1/product-imports/jobs/:id/rows
GET  /api/v1/product-imports/jobs/:id/errors
POST /api/v1/product-imports/jobs/upload
POST /api/v1/product-imports/jobs/:id/confirm
```

## Import result

Valid rows are saved only after confirmation. Invalid rows remain in the import report and are not published.

