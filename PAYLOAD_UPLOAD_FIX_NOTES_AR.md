# إصلاح مشكلة رفع وثائق الاعتماد الكبيرة

تم إصلاح خطأ `PayloadTooLargeError: request entity too large` الذي يظهر عند إرسال طلب الانضمام مع صور/PDF محفوظة بصيغة Base64.

## ما تم تعديله

- تعطيل body parser الافتراضي في NestJS وتفعيل JSON parser مخصص بحد افتراضي `30mb`.
- إضافة متغيرات بيئة:
  - `REQUEST_BODY_LIMIT=30mb`
  - `JSON_BODY_LIMIT=30mb`
- تحويل خطأ حجم الطلب من 500 إلى 413 برسالة مفهومة للمستخدم.
- إضافة فحص في Flutter يمنع اختيار ملف أكبر من 5MB لكل وثيقة قبل الإرسال.
- إضافة ترجمة عربية/إنجليزية لرسالة حجم الملف الكبير.

## ملاحظات تشغيل

بعد استبدال النسخة، نفذ في الباكند:

```powershell
cd backend
npm install
npm run start:dev
```

وفي الفرونت:

```powershell
cd frontend
flutter clean
flutter pub get
flutter run -d windows
```
