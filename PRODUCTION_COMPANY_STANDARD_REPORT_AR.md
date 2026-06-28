# تقرير ضبط نسخة الإنتاج حسب معيار شركة برمجية

تمت مراجعة النسخة الأخيرة وإضافة تحسينات إنتاجية فعلية على مستوى الواجهة، السياسات، المحاسبة، وفحوصات النشر.

## ما تم ضبطه فعليًا

### 1. واجهة متعددة المنصات

- تعديل `AppScaffold` حتى لا يستخدم نفس تنقل الموبايل على سطح المكتب.
- إضافة شريط جانبي احترافي للشاشات الواسعة وDesktop/Web.
- إبقاء Bottom Navigation للشاشات الصغيرة والموبايل.
- إضافة قرار منصة مركزي في `PlatformLayout.isDesktopShell`.

### 2. السياسات والصلاحيات

- الحفاظ على حماية الصفحات عبر `_RequireAccess`.
- الحفاظ على تجاوز الإدارة للإشراف عبر `auth.isAdmin` بدون اشتراط مؤسسة تاجر/ورشة.
- استمرار سياسة اعتماد التاجر والورشة للمستخدمين غير الإداريين.

### 3. القيود المحاسبية

- إضافة منع القيد الذي يحتوي سطرًا مدينًا ودائنًا معًا.
- منع السطر الصفري داخل القيد.
- منع السطور السالبة.
- منع استخدام حساب محاسبي غير نشط.
- توحيد والتحقق من رمز العملة.
- منع خلط العملات في رصيد المؤسسة.
- إجبار كل Financial Transaction على مبلغ موجب.
- جعل الاسترداد يرجع من أصل الدفع المناسب: نقدي/بنكي/محفظة.

### 4. النشر والتشغيل

- تقوية `preflight.js` حتى يرفض أسرار الإنتاج الافتراضية.
- رفض CORS المحلي في وضع الإنتاج.
- رفض الإنتاج بدون إعدادات بيئة حقيقية.
- تحديث Static QA ليتأكد من وجود طبقة الواجهة المتكيفة ومن حمايات المحاسبة.

## ملفات مهمة تم تعديلها

- `frontend/lib/shared/widgets/app_scaffold.dart`
- `frontend/lib/core/platform/platform_layout.dart`
- `backend/src/modules/accounting/accounting.service.ts`
- `backend/scripts/deployment/preflight.js`
- `backend/scripts/qa/static-check.js`
- `docs/PRODUCTION_ACCEPTANCE_CHECKLIST_AR.md`

## أوامر الفحص المطلوبة بعد فك الضغط

```powershell
cd backend
npm install
npx prisma generate
npm run test
npm run build
npm run start:dev
```

```powershell
cd frontend
flutter clean
flutter pub get
flutter analyze
flutter run -d windows
```

## ملاحظة هندسية

هذه نسخة إنتاجية محسّنة وقابلة للاختبار الجاد. لا يمكن تأكيد أنها Production Release نهائية 100% إلا بعد تشغيل build والتحليل والاتصال بقاعدة البيانات على جهازك، لأن هذه البيئة لا تحتوي Flutter SDK ولا node_modules ولا MySQL.

## أمن الأسرار

تم حذف `backend/.env` من الحزمة النهائية حتى لا يتم تسريب أي Tokens أو أسرار. استخدم `backend/.env.example` كقالب فقط، وأنشئ ملف `.env` محليًا على جهازك بقيم جديدة وآمنة قبل التشغيل.
