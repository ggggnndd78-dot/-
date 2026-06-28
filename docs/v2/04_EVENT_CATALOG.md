# 04 — كتالوج الأحداث Event Catalog

## 1. الهدف

النظام سيكون Event-Driven حتى تكون العمليات منظمة وقابلة للتوسع.

كل عملية مهمة لا تنفذ كأوامر متداخلة فقط، بل تولد حدثًا واضحًا يمكن ربطه بالإشعارات، السجلات، القيود المحاسبية، والعمليات الخلفية.

## 2. الأحداث الأساسية

### Auth Events

- OtpRequested
- OtpDispatched
- OtpVerified
- UserLoggedIn
- UserLoggedOut
- GuestSessionCreated

### Registration Events

- CustomerRegistered
- MerchantOnboardingStarted
- MerchantOnboardingSubmitted
- WorkshopOnboardingStarted
- WorkshopOnboardingSubmitted
- WarehouseOnboardingSubmitted

### Verification Events

- VerificationSubmitted
- VerificationApproved
- VerificationRejected
- VerificationDocumentsRequired
- VerificationSuspended

### Employee Events

- EmployeeInvited
- EmployeeActivated
- EmployeePermissionsChanged
- EmployeeSuspended

### Import Events

- ProductImportUploaded
- ProductImportParsed
- ProductImportValidationFailed
- ProductImportCompleted
- ProductImportPartiallyCompleted

### Marketplace Events

- ProductCreated
- ListingCreated
- StockChanged
- ListingApproved
- ListingRejected

### Order Events

- OrderCreated
- OrderConfirmed
- OrderStatusChanged
- OrderCancelled
- OrderDelivered

### Payment Events

- PaymentIntentCreated
- PaymentProofUploaded
- PaymentConfirmed
- PaymentRejected
- RefundCreated
- SettlementCreated

### Accounting Events

- AccountingEntryPosted
- AccountingEntryReversed
- SettlementEntryPosted

### Notification Events

- NotificationCreated
- EmailQueued
- EmailSent
- PushNotificationQueued
- PushNotificationSent

## 3. Outbox Pattern

سيتم تخزين الأحداث المهمة في جدول Outbox لضمان عدم ضياع الإشعارات أو القيود أو السجلات عند حدوث أخطاء مؤقتة.

## 4. مثال الموافقة على تاجر

VerificationApproved يؤدي إلى:

1. تفعيل المؤسسة.
2. منح صلاحيات التاجر.
3. إنشاء إشعار داخل التطبيق.
4. إرسال إيميل.
5. تسجيل Audit Log.
6. إنشاء إعدادات افتراضية للمؤسسة.
