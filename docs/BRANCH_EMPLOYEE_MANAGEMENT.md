# Branch and Employee Management

This release adds the organization operations needed by approved merchants, workshops, and warehouses.

## Scope

- Add and update organization branches.
- Temporarily close and reopen branches.
- Save branch business hours.
- Add organization employees.
- Assign employee permissions.
- Assign access to all branches or selected branches.
- Suspend or reactivate employees.
- View employee activity from audit logs.

## Security Rules

- Only an approved organization owner can manage employees.
- A user can manage only their own organization.
- Employee permissions are restricted by organization type.
- Branch access is validated against the same organization.
- Employee status and permission changes are recorded in audit logs.
