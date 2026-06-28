# تقرير تعميم الفلاتر كقوائم

تم تحويل الفلاتر التي كانت تظهر كمربعات/شرائح كثيرة إلى قوائم اختيار أكثر ترتيبًا ومناسبة للجوال.

## الملفات المعدلة
- customer_chat_page.dart: فلتر حالة المحادثات إلى Dropdown مع خيار غير مقروء فقط.
- categories_page.dart: فلتر مجموعات التصنيفات إلى Dropdown.
- notifications_page.dart: فلتر نوع الإشعارات إلى Dropdown.
- provider_reviews_page.dart: فلتر نوع التقييم والنجوم إلى Dropdown.
- merchant_branches_real_page.dart: فلتر الفروع إلى Dropdown.
- merchant_inventory_page.dart: فلتر الفرع في المخزون إلى Dropdown.
- customer_disputes_page.dart: فلتر حالة النزاعات إلى Dropdown.

## السياسة
أي فلتر أحادي الاختيار يجب أن يكون Dropdown بدل مربعات متعددة، لتقليل الزحمة في الواجهة وتحسين تجربة الجوال.
