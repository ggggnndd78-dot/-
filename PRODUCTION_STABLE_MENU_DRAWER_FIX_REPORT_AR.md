# تقرير إصلاح ثبات Menu Drawer والتنقل

## الهدف
إصلاح مشكلة أن الضغط على عنصر داخل الـ Menu Drawer يغيّر الصفحة بينما تبقى القائمة مفتوحة، فيظهر للمستخدم كأن واجهة ثانية فتحت فوق واجهة أخرى وبداخلها Drawer أخرى.

## الإصلاحات

### 1. تثبيت سلوك عناصر القائمة
تم تعديل `DashboardSidebarTile` بحيث:
- في وضع الهاتف/الشاشات الصغيرة يغلق الـ Drawer أولًا.
- بعد إغلاق الـ Drawer ينتقل إلى المسار المطلوب في الإطار التالي.
- إذا كان المستخدم في نفس الصفحة، يغلق الـ Drawer فقط ولا يعيد تحميل الصفحة.

### 2. حفظ حالة Sidebar على سطح المكتب
تم تعديل `UnifiedSidebarFrame` لحفظ حالة فتح/إغلاق الـ Sidebar حسب مساحة التنقل، حتى لا تعود القائمة تفتح أو تغلق مع كل انتقال بين الصفحات.

### 3. إصلاح ListTile في إعدادات الإدارة
تمت إزالة استخدام `SizedBox` داخل `leading` في `ListTile` بصفحة إعدادات الإدارة واستبداله بأيقونة مباشرة لتجنب خطأ:

`Leading widget consumes the entire tile width`

## الملفات المعدلة
- `frontend/lib/shared/layout/dashboard_shell.dart`
- `frontend/lib/features/admin/presentation/pages/admin_settings_page.dart`

## ملاحظات تشغيل
يرجى تشغيل:

```powershell
cd frontend
flutter clean
flutter pub get
dart format lib
flutter analyze
flutter run -d windows
```

لم يتم تشغيل Flutter Analyze داخل بيئة ChatGPT لأن Flutter SDK غير متوفر هنا.
