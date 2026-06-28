# تقرير ضبط الفلاتر كقوائم اختيار

تم تعديل فلاتر الحالات التي كانت تظهر كشرائح/مربعات متعددة لتصبح قوائم اختيار Dropdown أكثر تنظيمًا ومناسبة للجوال.

## الملفات المعدلة

- `features/admin/presentation/pages/admin_verifications_page.dart`
  - تحويل فلتر طلبات الاعتماد من ChoiceChips إلى قائمة اختيار واحدة.

- `features/merchant_market/presentation/pages/merchant_orders_page.dart`
  - تحويل فلتر مراحل الطلبات من شريط شرائح أفقي إلى Dropdown مدمج.

- `features/merchant_market/presentation/pages/merchant_listings_page.dart`
  - تحويل فلتر المنتجات من تبويبات/مربعات كثيرة إلى Dropdown يحافظ على عدد العناصر لكل حالة.

- `features/merchant_market/presentation/pages/finance_reports/merchant_payments_page.dart`
  - تحويل فلتر حالة المدفوعات إلى Dropdown.

- `features/merchant_market/presentation/pages/finance_reports/merchant_settlements_page.dart`
  - تحويل فلتر حالة التسويات إلى Dropdown.

- `features/merchant_market/presentation/pages/sales_operations/merchant_returns_page.dart`
  - تحويل فلتر حالة المرتجعات إلى Dropdown.

- `features/merchant_market/presentation/pages/sales_operations/merchant_disputes_page.dart`
  - تحويل فلتر حالة النزاعات إلى Dropdown.

## الهدف

- تقليل ازدحام الواجهة.
- تحسين تجربة الجوال.
- منع الفلاتر من حجز مساحة كبيرة.
- المحافظة على نفس منطق الفلترة القديم بدون تغيير APIs.
