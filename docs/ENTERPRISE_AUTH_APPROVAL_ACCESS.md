# Ghiyarak Enterprise Authentication, Trusted Devices, Registration Approval & Access Control

## Implemented Scope

This release upgrades the platform authentication layer from OTP-only login to an enterprise trusted-device flow integrated with RBAC, audit logs, notifications, verification applications, and full localization support.

## Backend Additions

### New Auth APIs

- `POST /api/v1/auth/login/start`
- `POST /api/v1/auth/login/verify-device-otp`
- `POST /api/v1/auth/register/customer`
- `POST /api/v1/auth/register/business`
- `POST /api/v1/auth/session/validate`
- `GET /api/v1/auth/devices`
- `DELETE /api/v1/auth/devices/:id`
- `POST /api/v1/auth/logout-all-devices`

Legacy APIs remain available:

- `POST /api/v1/auth/request-otp`
- `POST /api/v1/auth/verify-otp`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`

## Database Additions

Migration:

`20260624220000_enterprise_auth_access_control`

New tables:

- `auth_trusted_devices`
- `auth_sessions`

Enhanced tables:

- `iam_users`
  - `failed_login_count`
  - `locked_until`
  - `last_login_at`
- `iam_otp_requests`
  - `ip_address`
  - `user_agent`
- `iam_refresh_tokens`
  - `device_id`
  - `session_id`
  - `ip_address`
  - `user_agent`
- `org_verification_documents`
  - `file_size_bytes`
  - `file_content_base64`
  - `storage_provider`
  - `storage_key`
  - `upload_status`
  - `side`

## Trusted Device Flow

1. User enters phone number.
2. Frontend sends device fingerprint and optional trusted device token.
3. Backend checks `auth_trusted_devices`.
4. Trusted device: direct login without OTP.
5. Unknown/new device: OTP required.
6. After OTP verification, backend creates or refreshes trusted device record and returns a device token.
7. Frontend stores device token in secure storage.

## Registration

### Customer

- Phone OTP verification.
- Customer role assignment.
- Account status `ACTIVE`.
- Immediate access.

### Merchant / Workshop

- Phone OTP verification.
- Organization created with `PENDING_REVIEW`.
- Owner role assigned.
- Documents stored through verification document service.
- Business modules remain locked until approval.

## Documents

Supported types:

- National ID: front + back image.
- Passport: image.
- Bank Statement: PDF.
- Commercial Registration: image or PDF.

Files are represented by metadata and optional Base64 content in dedicated document columns, never inside source code.

## Admin Approval Workflow

Existing admin verification APIs now support the enterprise membership workflow:

- list applications
- view application details
- preview images/PDF base64 content
- approve
- reject
- request documents
- suspend

Each action produces:

- audit log
- status history record
- approval action record
- event bus message
- owner notification

## Security

Implemented:

- OTP hashing
- trusted device token hashing
- refresh token rotation
- session tracking
- device revocation
- logout all devices
- IP tracking
- user agent tracking
- account lock after OTP failure threshold
- audit logging for device trust/revocation and membership submission

## Flutter

Added:

- device fingerprint service
- trusted device token secure storage
- login start flow
- direct trusted-device login
- OTP only for new devices
- session validation on splash/startup
- dashboard route returned from backend

## Localization

All new backend messages use translation keys. Frontend continues sending:

- `Accept-Language`
- `X-Locale`

Default language remains Arabic.
