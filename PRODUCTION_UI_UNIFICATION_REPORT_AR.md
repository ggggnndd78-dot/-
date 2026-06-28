# تقرير توحيد واجهات غيارك وتجهيز النسخة الإنتاجية

## الهدف
تم فحص نسخة المشروع المرفقة وإضافة طبقة تصميم وتنقل مشتركة حتى لا تبقى كل لوحة بتصميم مستقل. تم التركيز على توحيد الهوية البصرية، القوائم الجانبية، التجاوب بين المنصات، وسياسة الضيف وزر المتابعة كزائر.

## الملفات الأساسية التي تم تعديلها

- `frontend/lib/core/theme/app_colors.dart`
- `frontend/lib/core/theme/app_spacing.dart`
- `frontend/lib/core/theme/app_radius.dart`
- `frontend/lib/core/theme/app_text_styles.dart`
- `frontend/lib/core/i18n/app_localizations.dart`
- `frontend/lib/app/router/app_router.dart`
- `frontend/lib/features/auth/presentation/pages/login_page.dart`
- `frontend/lib/shared/widgets/app_scaffold.dart`
- `frontend/lib/features/merchant_market/presentation/widgets/merchant_drawer.dart`
- `frontend/lib/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart`
- `frontend/lib/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart`
- `frontend/lib/features/merchant_market/presentation/widgets/merchant_common_widgets.dart`
- `frontend/lib/features/merchant_market/presentation/widgets/merchant_page_header.dart`

## ملفات جديدة تمت إضافتها

- `frontend/lib/shared/navigation/app_navigation_config.dart`
- `frontend/lib/shared/layout/dashboard_shell.dart`
- `frontend/lib/shared/widgets/app_card.dart`
- `frontend/lib/shared/widgets/app_states.dart`
- `frontend/lib/shared/widgets/app_responsive_builder.dart`
- `frontend/lib/shared/widgets/app_login_required_dialog.dart`
- `frontend/lib/shared/widgets/app_page.dart`
- `frontend/lib/shared/widgets/app_dropdown.dart`
- `frontend/lib/shared/widgets/app_search_field.dart`
- `frontend/lib/shared/widgets/app_data_table.dart`
- `frontend/lib/shared/widgets/app_dialogs.dart`

## ما تم ضبطه

### 1. توحيد الثيم والهوية
تم توسيع ثيم المشروع ليشمل ألوانًا موحدة للحالات والسطوح والنصوص، ومسافات قياسية، وزوايا موحدة، وأنماط نصوص مشتركة.

### 2. توحيد التنقل والقوائم
تم إنشاء ملف مركزي لإعدادات التنقل حسب الدور والصلاحية:

`frontend/lib/shared/navigation/app_navigation_config.dart`

هذا الملف يحدد عناصر التنقل للضيف، العميل، التاجر، الورشة، المستودع، الدعم، والإدارة. الهدف أن لا تكون قائمة التاجر بتصميم مختلف عن باقي اللوحات.

### 3. توحيد Shell للوحات
تم إنشاء:

`DashboardShell`
`DashboardSidebar`
`DashboardTopBar`
`DashboardBottomNavigation`

داخل:

`frontend/lib/shared/layout/dashboard_shell.dart`

ويستخدم هذا النظام نفس النمط لكل اللوحات، مع اختلاف العناصر حسب الدور والصلاحية.

### 4. لوحة التاجر
تم استبدال Drawer التاجر القديم والمتكرر بتغليف موحد يعتمد على `DashboardSidebar`. كما تم ضبط `MerchantManagementScaffold` لاستخدام `DashboardShell` بدل بناء Scaffold مستقل بتصميم مختلف.

### 5. زر المتابعة كزائر
تمت إضافة زر واضح في شاشة تسجيل الدخول:

- عربي: `المتابعة كزائر`
- إنجليزي: `Continue as Guest`

الزر يستخدم منطق `continueAsGuest()` الموجود في `AuthController` ثم يوجه المستخدم إلى السوق العام.

### 6. سياسة الضيف
تم تعديل الراوتر بحيث يستطيع الضيف الوصول إلى:

- السوق
- البحث
- التصنيفات
- تفاصيل المنتج
- ملف المزود العام
- تقييمات المزود العامة
- تسجيل الدخول والتسجيل
- مركز المساعدة العام

ويمنع من الوصول إلى:

- السلة
- الدفع
- الطلبات
- المفضلة
- المقارنة المحمية
- المحادثة
- الدعم الخاص
- الملف الشخصي
- العناوين
- المركبات
- لوحات التاجر والورشة والإدارة

### 7. دعم التصميم المتجاوب
تم توجيه التصميم ليستخدم:

- Sidebar احترافي في Desktop/Web واسع
- Bottom navigation في الشاشات الصغيرة عند الحاجة
- نفس الهوية اللونية والمسافات في كل المنصات

### 8. التعريب والترجمة
تمت إضافة مفاتيح ترجمة للضيف والقوائم وبعض العناصر المشتركة، ومنع النصوص الجديدة من أن تكون Hardcoded.

## ملاحظات جودة مهمة

لم يتم تشغيل `flutter analyze` فعليًا داخل هذه البيئة لأن Flutter SDK غير مثبت هنا. تم إجراء فحص ثابت على الملفات المعدلة وتوازن الأقواس والمسارات الأساسية.

بعد فك الضغط شغل:

```powershell
cd frontend
flutter clean
flutter pub get
dart format lib
flutter analyze
flutter test
```

ثم شغل الباكند:

```powershell
cd backend
npm install
npx prisma generate
npm run build
```

## ملاحظة أمنية
تم حذف `backend/.env` من النسخة النهائية حتى لا يتم تسريب أسرار أو Tokens. استخدم `backend/.env.example` وأنشئ ملف `.env` محليًا بقيمك الحقيقية.
