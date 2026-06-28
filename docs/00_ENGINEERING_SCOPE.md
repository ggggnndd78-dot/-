# Ghiyarak Phases 0 to 4 — Engineering Scope

## Phase 0 — Requirements and scenarios

The project is an enterprise automotive platform, not a simple store. The system has one backend, one database, one API, and Flutter clients for Android, Web, and Windows Desktop. Each user sees features based on role, permissions, organization, branch access, and approval status.

Core roles:

```text
Guest
Customer
Merchant Owner
Merchant Employee
Workshop Owner
Workshop Employee
Warehouse Owner
Warehouse Employee
Driver
Customer Support
Finance Manager
Content Manager
Super Admin
```

## Phase 1 — Architecture foundation

Backend is organized into common infrastructure, configuration, database, auth, users, organizations, employees, notifications, admin, and future business modules.

Flutter is organized into app, core, shared, and feature folders, with role-based navigation.

## Phase 2 — Auth and OTP

Implemented OTP rules:

- OTP is never stored as plain text.
- OTP hash is stored.
- OTP has expiry.
- OTP has max attempts.
- OTP is consumed after successful verification.
- Guest session and refresh-token foundation are present.
- SMS delivery is routed through CommPeak/TextPeak event_send.

## Phase 3 — RBAC and employees

The platform supports role and permission concepts, organization membership, employee permissions, and branch access. Employees belong to an organization and must not see data outside their organization or unauthorized branches.

## Phase 4 — Role-based registration

Customer accounts become active directly after OTP. Merchant, Workshop, and Warehouse accounts complete onboarding and remain pending review until admin approval.

