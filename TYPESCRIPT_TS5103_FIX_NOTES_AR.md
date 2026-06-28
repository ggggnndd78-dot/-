# إصلاح TypeScript TS5103

تم إصلاح خطأ تشغيل الباكند:

```text
error TS5103: Invalid value for --ignoreDeprecations
```

السبب كان وجود القيمة غير المدعومة `ignoreDeprecations: 6.0` داخل `backend/tsconfig.json`.

تمت إزالة هذا الخيار نهائيًا لأن إعدادات `baseUrl` و `moduleResolution=node10` القديمة لم تعد موجودة في نسخة المشروع الحالية، وبالتالي لا حاجة لإسكات تحذيرات TypeScript.

شغّل الباكند بعد فك النسخة:

```powershell
cd backend
npm install
npm run start:dev
```
