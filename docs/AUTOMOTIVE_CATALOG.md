# Automotive Catalog and Marketplace

This release adds the vehicle catalog and spare-parts marketplace scope only.

## Vehicle catalog

Implemented:

- Vehicle brands/makes lookup.
- Vehicle models lookup by brand.
- Vehicle years lookup by model.
- Vehicle trims lookup by model and year.
- Engine-code lookup when compatibility data contains engine codes.
- Customer vehicle create/update/delete/default selection.
- Validation that selected model belongs to brand and selected trim fits the selected year.

Seeded base brands:

- Toyota, Hyundai, Kia, Nissan, Isuzu, Mitsubishi, Ford, Chevrolet, GMC, Lexus, Honda, Mercedes-Benz, BMW, Changan, Geely, MG.

## Marketplace

Implemented:

- Categories.
- Product brands.
- Products.
- Product media.
- Product specs.
- Product compatibility rules.
- Listings from approved merchants.
- Listing inventory snapshot.
- Listing price history.
- Stock movements.
- Public listing search.
- Search by part name, part number, product brand, vehicle make/model/year, city, condition, price range, and quality type.
- Multiple sellers for the same part through multiple listings on one product.
- Listing comparison by product.
- Similar listings by category.

## Not included

This scope does not include orders, payments, Excel import, or delivery workflows. Those belong to later scopes.
