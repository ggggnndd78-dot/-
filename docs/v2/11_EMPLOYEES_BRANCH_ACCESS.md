# Employees and Branch Access

## Business rule

Approved merchants, workshops, and warehouses can add employees.

An employee belongs to one organization and can be restricted to one or more branches. The employee sees only permissions granted by the owner.

## API endpoints

### List employees
`GET /api/v1/organizations/{organizationId}/employees`

### Add employee
`POST /api/v1/organizations/{organizationId}/employees`

```json
{
  "displayName": "موظف المبيعات",
  "phone": "733333333",
  "permissions": ["merchant.products.manage", "merchant.orders.manage"],
  "branchIds": ["branch_public_id"]
}
```

### Update permissions
`PATCH /api/v1/organizations/{organizationId}/employees/{memberId}/permissions`

```json
{
  "permissions": ["merchant.inventory.manage"],
  "branchIds": ["branch_public_id"]
}
```

## Security rules

- Only organization owner can manage employees.
- Organization must be approved.
- Employee cannot receive permissions outside organization type.
- Branch access must belong to same organization.
- Every operation publishes an event and writes an audit log.
