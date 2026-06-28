# تقرير إصلاح استعادة جلسة المدير واتجاه اللوحة

## المشكلة
بعد إعادة تشغيل التطبيق كان المستخدم الإداري يظهر باسم Super Admin، لكن التطبيق يفتح `/customer/center` ويعرض لوحة العميل بدل لوحة الإدارة. السبب أن مسار `dashboardRoute` القادم من الخادم أو المسار السابق كان أحيانًا يشير إلى لوحة العميل، ومنطق الواجهة كان يقبله حتى لو كان المستخدم مديرًا.

## ما تم إصلاحه
- تعديل `AppRouteResolver.resolvePostAuthRoute` حتى لا يقبل أي `nextRoute` أو `dashboardRoute` غير مناسب لدور المستخدم.
- منع المدير من البقاء داخل صفحات العميل المحمية؛ يتم توجيهه إلى `/admin/control-center`.
- تحسين `initializeSession` حتى لا يجعل الحالة `authenticated` بدون تحميل مستخدم صحيح.
- تعديل `AuthState.isCustomer` حتى لا يعتبر المستخدم عميلًا إذا كانت بيانات المستخدم غير محملة.
- جعل منطقة القائمة للإداري Admin حتى لو كان المسار السابق عام أو عميل.
- إزالة سبب تحذير `ListTile background color or ink splashes may be invisible` من لوحة العميل عن طريق استبدال عناصر `ListTile` الحساسة بعناصر `Material + InkWell` مخصصة.

## الملفات المعدلة
- `lib/shared/navigation/app_route_resolver.dart`
- `lib/app/router/app_router.dart`
- `lib/features/auth/logic/auth_controller.dart`
- `lib/features/auth/logic/auth_state.dart`
- `lib/shared/navigation/app_navigation_config.dart`
- `lib/features/auth/presentation/auth_navigation.dart`
- `lib/features/customer/presentation/customer_center_page.dart`
- `lib/features/marketplace/presentation/pages/marketplace_home_page.dart`

## السلوك المتوقع بعد الإصلاح
- إذا كان المستخدم Super Admin أو Admin Operations ثم أعاد تشغيل التطبيق، يتم توجيهه إلى لوحة الإدارة وليس لوحة العميل.
- إذا حاول المدير فتح صفحة عميل محمية، يتم توجيهه تلقائيًا إلى لوحة الإدارة.
- إذا كان المستخدم زائرًا، لا يتم اعتباره عميلًا ولا يفتح صفحات العميل.
- القائمة تستمر حسب اللغة: العربي من اليمين، الإنجليزي من اليسار.
