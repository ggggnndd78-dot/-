# تقرير إصلاح أخطاء Flutter Analyze الأخيرة

تم إصلاح الأخطاء التي ظهرت بعد تشغيل `flutter analyze` في الواجهة الأمامية.

## الأخطاء المعالجة

1. إضافة `closeBranchTemporarily` إلى `MerchantMarketRepository`.
   - تغلق كل أيام عمل الفرع مؤقتًا عبر تحديث ساعات العمل إلى `isClosed=true`.

2. إضافة `exportMerchantReportCsv` إلى `MerchantMarketRepository`.
   - تستدعي endpoint تصدير تقارير التاجر وتعيد محتوى CSV كنص قابل للنسخ أو الحفظ.

3. إضافة `cancelEmployeeInvitation` إلى `MerchantMarketRepository`.
   - تلغي دعوة موظف من خلال endpoint دعوات موظفي المؤسسة.

4. إضافة `removeMember` إلى `MerchantMarketRepository`.
   - تزيل عضو/موظف من المؤسسة عبر endpoint أعضاء المؤسسة.

5. إصلاح تحذير Flutter الجديد في `merchant_bulk_import_page.dart`.
   - تم استبدال `value:` بـ `initialValue:` داخل `DropdownButtonFormField`.

## الملفات المعدلة

- `frontend/lib/features/merchant_market/data/merchant_market_repository.dart`
- `frontend/lib/features/merchant_market/presentation/pages/catalog_management/merchant_bulk_import_page.dart`

## ملاحظات تشغيل

لم يتم تشغيل Flutter SDK داخل بيئة ChatGPT لأن Flutter غير مثبت هنا. بعد فك الضغط شغل:

```powershell
cd frontend
flutter clean
flutter pub get
dart format lib
flutter analyze
flutter test
```

إذا ظهرت أخطاء جديدة، أرسل مخرجات `flutter analyze` كما هي.
