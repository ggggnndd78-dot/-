# 06 — قواعد الوصول حسب المنصة والدور

## 1. القاعدة العامة

Android وWeb وWindows Desktop كلها تستخدم نفس API ونفس نظام الصلاحيات.

لا يوجد منطق مختلف في الباك إند حسب المنصة، لكن الواجهة تعرض الصفحات حسب الدور.

## 2. Android

مناسب لـ:

- Guest
- Customer
- Merchant Owner
- Merchant Employee
- Workshop Owner
- Workshop Employee
- Warehouse Owner
- Driver
- Support عند الحاجة
- Admin عند الحاجة

## 3. Web

مناسب لـ:

- Super Admin
- Finance Manager
- Content Manager
- Customer Support
- Merchant Owner
- Workshop Owner
- Warehouse Owner
- Employees

## 4. Windows Desktop

مناسب للإدارة والتشغيل الداخلي:

- Super Admin
- Finance Manager
- Support
- Merchant/Workshop/Warehouse back office

## 5. قواعد التوجيه

بعد تسجيل الدخول:

- إذا Super Admin → Admin Dashboard.
- إذا Finance Manager → Finance Dashboard.
- إذا Customer Support → Support Dashboard.
- إذا Merchant Owner Approved → Merchant Dashboard.
- إذا Merchant Owner Pending → Verification Status.
- إذا Workshop Owner Approved → Workshop Dashboard.
- إذا Workshop Owner Pending → Verification Status.
- إذا Employee → Dashboard حسب صلاحياته.
- إذا Customer → Customer Home.
- إذا Guest → Marketplace Browse.
