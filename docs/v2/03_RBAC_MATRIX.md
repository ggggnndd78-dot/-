# 03 — مصفوفة الأدوار والصلاحيات RBAC

## 1. الأدوار

| الدور | الوصف |
|---|---|
| GUEST | زائر غير مسجل |
| CUSTOMER | عميل مسجل |
| MERCHANT_OWNER | مالك متجر قطع غيار |
| MERCHANT_EMPLOYEE | موظف تابع لتاجر |
| WORKSHOP_OWNER | مالك ورشة |
| WORKSHOP_EMPLOYEE | موظف تابع لورشة |
| WAREHOUSE_OWNER | مالك مستودع |
| WAREHOUSE_EMPLOYEE | موظف مستودع |
| DRIVER | مندوب توصيل |
| CUSTOMER_SUPPORT | دعم فني |
| FINANCE_MANAGER | مدير مالي |
| CONTENT_MANAGER | مدير محتوى |
| SUPER_ADMIN | مدير عام كامل الصلاحيات |

## 2. صلاحيات عامة

| الصلاحية | Guest | Customer | Merchant Owner | Workshop Owner | Admin |
|---|---:|---:|---:|---:|---:|
| marketplace.browse | نعم | نعم | نعم | نعم | نعم |
| listings.view | نعم | نعم | نعم | نعم | نعم |
| cart.manage | لا | نعم | لا | لا | نعم |
| orders.create | لا | نعم | لا | لا | نعم |
| profile.manage | لا | نعم | نعم | نعم | نعم |
| notifications.view | لا | نعم | نعم | نعم | نعم |

## 3. صلاحيات التاجر

| الصلاحية | Owner | Employee |
|---|---:|---:|
| merchant.dashboard.view | نعم | حسب التفويض |
| merchant.products.manage | نعم | حسب التفويض |
| merchant.inventory.manage | نعم | حسب التفويض |
| merchant.orders.view | نعم | حسب التفويض |
| merchant.orders.update_status | نعم | حسب التفويض |
| merchant.branches.manage | نعم | لا إلا إذا منحها |
| merchant.employees.manage | نعم | لا إلا إذا منحها |
| merchant.imports.manage | نعم | حسب التفويض |
| merchant.reports.view | نعم | حسب التفويض |

## 4. صلاحيات الورشة

| الصلاحية | Owner | Employee |
|---|---:|---:|
| workshop.dashboard.view | نعم | حسب التفويض |
| workshop.services.manage | نعم | حسب التفويض |
| workshop.bookings.view | نعم | حسب التفويض |
| workshop.bookings.update_status | نعم | حسب التفويض |
| workshop.technicians.manage | نعم | حسب التفويض |
| workshop.branches.manage | نعم | لا إلا إذا منحها |
| workshop.employees.manage | نعم | لا إلا إذا منحها |
| workshop.imports.manage | نعم | حسب التفويض |
| workshop.reports.view | نعم | حسب التفويض |

## 5. صلاحيات الإدارة

- admin.dashboard.view
- admin.users.manage
- admin.roles.manage
- admin.permissions.manage
- admin.verifications.review
- admin.organizations.suspend
- admin.products.moderate
- admin.orders.view_all
- admin.payments.view_all
- admin.audit.view
- admin.settings.manage

## 6. قاعدة الفرع Branch Access

كل موظف تابع لمؤسسة يجب أن يكون له نطاق وصول:

- كل الفروع.
- فرع واحد.
- عدة فروع محددة.

لا يسمح للموظف بالوصول إلى بيانات فرع غير مصرح له.
