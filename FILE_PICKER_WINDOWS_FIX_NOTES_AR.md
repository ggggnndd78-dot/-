# Ghiyarak v2.3 — إصلاح اختيار الملفات في Windows

## سبب المشكلة
عند الضغط على زر **رفع الملف** في صفحة وثائق التحقق لم تكن نافذة اختيار الملفات تظهر، لأن ملفات تسجيل إضافات Flutter Desktop داخل Windows كانت ناقصة ولا تسجل إضافة `file_picker`، لذلك قد يحدث `MissingPluginException` أو يتوقف التطبيق أثناء التصحيح.

## الإصلاحات المنفذة
- تسجيل إضافة `file_picker` في Windows runner.
- تسجيل إضافة `url_launcher_windows` لأن لوحة الإدارة تستخدم فتح الروابط/الملفات.
- تسجيل الإضافات المقابلة في Linux و macOS حتى لا تبقى ملفات المنصات ناقصة.
- إضافة `try/catch` داخل `_pickDocument` حتى لا ينهار التطبيق إذا فشل File Picker.
- إضافة رسائل عربية/إنجليزية واضحة عند فشل فتح نافذة الملفات.
- تفعيل `lockParentWindow` حتى تظهر نافذة اختيار الملفات فوق تطبيق Windows بدل أن تختفي خلفه.
- إزالة تحذيرات `DropdownButtonFormField.value` واستبدالها بـ `initialValue` في الملفات التي ظهرت في Problems.
- إزالة تحذير `unnecessary_cast` في صفحة الترجمات.
- إزالة تحذير `unnecessary_non_null_assertion` في صفحة إدارة المستخدمين.
- إزالة `ignoreDeprecations: 6.0` من `backend/tsconfig.json` لأنه غير صالح مع TypeScript 5.9.3 ويسبب TS5103.
- تشغيل فحص Backend Static QA بنجاح.

## أوامر التشغيل المطلوبة بعد فك النسخة

```powershell
cd backend
npm install
npm run start:dev
```

ثم افتح نافذة PowerShell ثانية:

```powershell
cd frontend
flutter clean
flutter pub get
flutter run -d windows
```

> مهم: `flutter clean` و `flutter pub get` ضرورية بعد هذا الإصلاح لأن Flutter يولد ملفات تسجيل الإضافات للويندوز أثناء البناء.
