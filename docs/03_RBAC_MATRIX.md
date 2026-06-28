# 03 RBAC Matrix

## Main permissions

```text
marketplace.browse
cart.manage
orders.create
merchant.products.manage
merchant.inventory.manage
merchant.orders.manage
merchant.employees.manage
merchant.branches.manage
workshop.services.manage
workshop.bookings.manage
workshop.employees.manage
workshop.branches.manage
warehouse.inventory.manage
finance.payments.review
admin.verifications.review
admin.users.manage
admin.audit.view
```

## Security rules

- User must have a valid session.
- User must have the required role or permission.
- Organization employees are scoped to their organization.
- Branch employees are scoped to allowed branches.
- Every sensitive operation is recorded in audit logs.


## Phase 5 Admin Verification Permissions

```text
review_verifications:
- عرض طلبات التوثيق
- فتح المستندات
- الموافقة
- الرفض
- طلب مستندات إضافية
- تعليق الحساب
```
