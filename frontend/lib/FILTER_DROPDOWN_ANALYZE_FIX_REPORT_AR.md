# تقرير إصلاح فلاتر المنتجات والتحليلات

تم إصلاح الأخطاء التي ظهرت بعد تحويل الفلاتر إلى قوائم Dropdown:

- إضافة الكومبوننت الناقص `_FilterSortSection` داخل صفحة منتجات التاجر.
- جعل ترتيب المنتجات يظهر كقائمة Dropdown بدل عناصر مبعثرة.
- إبقاء زر فلترة متقدمة صغيرًا ومنظمًا.
- إصلاح تحذير `use_build_context_synchronously` في صفحة تحليلات الإدارة عبر حفظ الرسائل قبل العملية غير المتزامنة والتحقق من `context.mounted`.

الملفات المعدلة:

- `features/merchant_market/presentation/pages/merchant_listings_page.dart`
- `features/admin/presentation/pages/admin_analytics_page.dart`
