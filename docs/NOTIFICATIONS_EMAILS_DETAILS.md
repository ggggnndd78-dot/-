# Phase 7 — Notifications and Emails Ready

## Scope

This phase implements the notification layer only. It does not add payment, delivery, marketplace, or accounting business logic.

## Implemented Channels

- In-app notifications stored in `notifications`
- Email notifications through the existing `EmailService`
- Firebase push notifications through `FirebasePushService`

## Implemented Tables

- `notification_templates`
- `email_notification_logs`
- `push_notification_logs`

Existing tables retained:

- `notifications`
- `notification_user_devices`

## Connected Phase Events

Provider verification review now dispatches:

- in-app notification
- email notification when the owner has an email
- Firebase push when the user has registered devices and Firebase is enabled

Covered verification events:

- `VerificationApproved`
- `VerificationRejected`
- `VerificationDocumentsRequired`
- `VerificationSuspended`

The notification dispatch also records a `NotificationDispatched` domain event.

## Firebase Push Configuration

Local development is safe by default:

```env
FIREBASE_PUSH_ENABLED="false"
```

Production configuration:

```env
FIREBASE_PUSH_ENABLED="true"
FIREBASE_SERVICE_ACCOUNT_PATH="C:/secure/ghiyarak-firebase-service-account.json"
```

or:

```env
FIREBASE_SERVICE_ACCOUNT_JSON="{...}"
```

## API Already Available

```text
POST /api/v1/notifications/devices
GET  /api/v1/notifications/my
GET  /api/v1/notifications/unread-count
PATCH /api/v1/notifications/:id/read
PATCH /api/v1/notifications/read-all
POST /api/v1/notifications/test
```

## Minimal Test

1. Login as a provider owner.
2. Submit verification request.
3. Login as admin.
4. Approve or reject request.
5. Provider owner should see the in-app notification.
6. If email is configured, an email log should be created.
7. If Firebase is configured and a device token is registered, push log should be created.
