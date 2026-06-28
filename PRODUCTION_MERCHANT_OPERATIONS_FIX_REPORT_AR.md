# تقرير إصلاح عمليات التاجر بعد توحيد الواجهات

## الهدف
إصلاح مشاكل التحليل التي ظهرت بعد توحيد الواجهات، مع التركيز على العمليات غير المكتملة في لوحة التاجر وربطها من خلال `MerchantMarketRepository` بدل توزيع منطق الربط داخل الصفحات.

## مصدر المشاكل
الملف المرفق من المستخدم أوضح أن أغلب الأخطاء مانعة للبناء وتتمركز حول دوال ناقصة أو أنواع خاطئة في:

- `frontend/lib/features/merchant_market/data/merchant_market_repository.dart`
- صفحات إدارة الكتالوج والاستيراد والمخزون والطلبات والفروع والتوثيق والعروض.
- `frontend/lib/shared/widgets/app_data_table.dart`

## أهم الإصلاحات

### 1. إعادة بناء MerchantMarketRepository
تم إعادة تنظيم الريبو ليحتوي على عمليات التاجر الأساسية:

- جلب مؤسسة التاجر ومعرف المؤسسة.
- ملخص لوحة التاجر.
- جاهزية المتجر والتوثيق والمستندات.
- الحسابات البنكية.
- الفروع: عرض، تفاصيل، إنشاء، تعديل، حذف، ساعات العمل.
- المنتجات والعروض: إنشاء منتج، تعديل عرض، تغيير حالة العرض، رفع صور، البحث بالكود.
- الكتالوج: الأصناف، العلامات، الشركات، الموديلات.
- الاستيراد الجماعي: رفع ملف، عرض عمليات الاستيراد، تنفيذ الاستيراد.
- المخزون: عرض، تعديل كمية، حد إعادة الطلب، الحركات، التحويل بين الفروع.
- الطلبات: عرض الطلبات، تفاصيل الطلب، تغيير الحالة.
- الكوبونات والعروض.
- الفريق والصلاحيات والدعوات.
- الإشعارات وتفضيلاتها.
- المرتجعات والنزاعات والرسائل.
- الدعم والمحادثات.
- التقارير والمالية والمحافظ والمدفوعات والتسويات والفواتير.
- الشحنات والتعيين وإعادة الجدولة وتغيير الحالة.

### 2. إصلاح أخطاء الأنواع
- `getDashboardSummary` يرجع الآن `MerchantDashboardModel` بدل `MerchantBranchModel`.
- `getMerchantReadiness` يرجع الآن `MerchantReadinessModel` بدل `MerchantVerificationRequestModel`.
- تفاصيل الفرع تستخدم `resolvedBranch` غير قابل للـ null عند بناء `_BranchDetailsData`.

### 3. إصلاح دوال ناقصة
تم إضافة كل الدوال التي كانت الصفحات تستدعيها ولم تكن موجودة في الريبو، مثل:

- `getMerchantOrganizationId`
- `getMerchantOrganization`
- `getMerchantBranches`
- `getBranch`
- `createBranch`
- `getMyListings`
- `getCategories`
- `getPartBrands`
- `getVehicleMakes`
- `getVehicleModels`
- `createMerchantProduct`
- `uploadMerchantProductImage`
- `lookupProductByCode`
- `getMerchantInventory`
- `updateInventoryQuantity`
- `setInventoryReorderLevel`
- `transferInventory`
- `getMerchantOrders`
- `updateOrderStatus`
- `getCoupons`
- `createCoupon`
- `getBankAccounts`
- `createBankAccount`
- `deleteBankAccount`
- `getVerificationRequest`

### 4. إصلاحات UI/Lint
- استبدال `MaterialStateProperty` بـ `WidgetStateProperty` في `AppDataTable`.
- تغليف بعض تعليمات `if` بالأقواس للحفاظ على جودة الكود.

## ملاحظات مهمة
لم يتم تشغيل `flutter analyze` فعليًا داخل هذه البيئة لأن Flutter SDK غير مثبت هنا. تم إجراء فحص ثابت على أسماء الدوال المطلوبة من ملف الأخطاء، وتوازن الأقواس، وإصلاح الجذور الرئيسية للمشاكل.

## أوامر التحقق المطلوبة محليًا

```powershell
cd frontend
flutter clean
flutter pub get
dart format lib
flutter analyze
flutter test
```

ثم للباكند:

```powershell
cd backend
npm install
npx prisma generate
npm run build
```
