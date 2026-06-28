# Ghiyarak Map Location + Access Policy Update

This version adds a mandatory map-based location step for merchant/workshop registration.

## Business registration location
- Address is no longer free text only.
- The user taps the address field to open a map.
- The user selects the exact store/workshop location on the map.
- The app saves latitude, longitude, and a Google Maps URL.
- Backend rejects merchant/workshop registration if map location is missing.
- Backend rejects coordinates outside Yemen's approximate geographic bounds.

## Database
`org_organization_branches` now stores:
- `latitude`
- `longitude`
- `map_url`
- `map_provider`
- `location_selected_at`

## Admin review
Admin verification details now show:
- Governorate/city
- District
- Area
- Address
- Latitude/longitude
- Direct map URL
- Button to open the location on the map
- Image previews for Base64 documents
- PDF document metadata for Base64 PDF review

## Access policy
- Login is phone-only.
- Trusted device token is required for direct login.
- New device requires OTP.
- Role-aware navigation hides unrelated dashboard sections from drawer/bottom navigation.
