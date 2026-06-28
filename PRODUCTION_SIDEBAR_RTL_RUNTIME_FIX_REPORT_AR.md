# تقرير إصلاح القائمة الجانبية و Runtime Layout

## المشكلة
ظهرت القائمة الجانبية في جهة غير مناسبة للغة العربية، كما ظهر خطأ Flutter Runtime:

- Vertical viewport was given unbounded height
- RenderBox was not laid out
- الخطأ مرتبط بـ `marketplace_home_page.dart` و `app_scaffold.dart`

## السبب الجذري
كان `AppScaffold` يلف كل محتوى الصفحة داخل `SingleChildScrollView`، بينما صفحات كثيرة داخل المشروع تستخدم `ListView` أو `RefreshIndicator` + `ListView` كجذر للمحتوى. هذا أدى إلى وضع Scrollable داخل Scrollable بدون ارتفاع محدد.

## الإصلاحات

1. تعديل `AppScaffold`:
   - إزالة الـ `SingleChildScrollView` العام.
   - إعطاء المحتوى قيود ارتفاع صحيحة من خلال `Padding + Align + ConstrainedBox`.
   - ترك مسؤولية التمرير للصفحة نفسها إذا كانت تستخدم `ListView` أو `SingleChildScrollView`.

2. ضبط اتجاه القائمة الجانبية حسب اللغة:
   - إذا كانت اللغة عربية، يتم ضبط `TextDirection.rtl` وتظهر القائمة في اليمين.
   - إذا كانت اللغة إنجليزية، يتم استخدام الاتجاه الحالي وتظهر القائمة في اليسار.

3. تعديل `DashboardShell`:
   - توحيد اتجاه الـ Desktop Sidebar حسب اللغة.
   - ضبط `Row.textDirection` بوضوح.
   - ضبط ظل القائمة حسب الجهة الصحيحة.

4. توسيع `AppNavigationConfig`:
   - توحيد عناصر التاجر داخل القائمة الجانبية المشتركة.
   - إضافة عناصر تشغيلية إضافية للتاجر مثل ملف المتجر، التوثيق، الكتالوج، الاستيراد، الفريق، الإشعارات، المرتجعات، النزاعات، التقييمات، المحفظة، التسويات، والفواتير.
   - تحسين تحديد منطقة التنقل للصفحات المحمية الخاصة بالعميل مثل السلة، الدفع، المفضلة، المقارنة، الإرجاع، الإلغاء، النزاعات، والتقييم.

5. إضافة مفاتيح ترجمة عربية وإنجليزية لعناصر التاجر الجديدة.

## الملفات المعدلة

- frontend/lib/shared/widgets/app_scaffold.dart
- frontend/lib/shared/layout/dashboard_shell.dart
- frontend/lib/shared/navigation/app_navigation_config.dart
- frontend/lib/core/i18n/app_localizations.dart

## ملاحظات تشغيل

بعد فك الضغط شغل:

```powershell
cd frontend
flutter clean
flutter pub get
dart format lib
flutter analyze
flutter run -d windows
```

إذا بقيت أخطاء Runtime، أرسل أول خطأ من الأعلى فقط لأنه عادة يكون السبب الجذري.
