# Ghiyarak v2.5 - إصلاح خطأ Dart في صفحة التسجيل

## المشكلة
ظهر الخطأ التالي في Flutter Analyzer:

```text
The argument type 'Map<String, String>?' can't be assigned to the parameter type 'Map<String, Object?>'.
```

وكان السبب أن دالة `_showDocumentSnack` في:

```text
frontend/lib/features/auth/presentation/pages/register_page.dart
```

كانت تستقبل `Map<String, String>?` بينما دالة الترجمة `context.tr` تستقبل `Map<String, Object?>`.

## الإصلاح
تم تعديل توقيع الدالة إلى:

```dart
void _showDocumentSnack(String key, {Map<String, Object?> params = const {}})
```

وبذلك صار النوع مطابقًا لنظام الترجمة، وانتهى خطأ التحليل عند السطر 280.

## ملاحظات تشغيل
بعد فك النسخة شغّل:

```powershell
cd backend
npm install
npm run start:dev
```

ثم:

```powershell
cd frontend
flutter clean
flutter pub get
flutter run -d windows
```

## فحص تم
تم تشغيل فحص الباكند static QA ونجح.
