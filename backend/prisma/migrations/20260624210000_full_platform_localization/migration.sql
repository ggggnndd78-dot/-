CREATE TABLE IF NOT EXISTS `translation_keys` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `key` VARCHAR(220) NOT NULL,
  `namespace` VARCHAR(80) NOT NULL DEFAULT 'app',
  `description` TEXT NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'PUBLISHED',
  `is_system` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `translation_keys_key_key` (`key`),
  INDEX `translation_keys_namespace_status_idx` (`namespace`, `status`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `translation_values` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `translation_key_id` INT NOT NULL,
  `locale` VARCHAR(10) NOT NULL,
  `value` TEXT NOT NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'PUBLISHED',
  `platform` VARCHAR(40) NOT NULL DEFAULT 'GLOBAL',
  `published_at` DATETIME(3) NULL,
  `updated_by_user_id` INT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `translation_values_key_locale_platform_key` (`translation_key_id`, `locale`, `platform`),
  INDEX `translation_values_locale_status_idx` (`locale`, `status`),
  INDEX `translation_values_platform_locale_idx` (`platform`, `locale`),
  CONSTRAINT `translation_values_translation_key_id_fkey` FOREIGN KEY (`translation_key_id`) REFERENCES `translation_keys`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `iam_users` MODIFY `locale` VARCHAR(10) NOT NULL DEFAULT 'ar';

INSERT IGNORE INTO `system_settings` (`key`, `value_text`, `description`, `is_public`, `created_at`, `updated_at`) VALUES
('platform.default_locale', 'ar', 'Default platform language', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('platform.supported_locales', 'ar,en', 'Supported platform languages', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('platform.rtl_locales', 'ar', 'Right-to-left locales', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('i18n.remote_catalog_enabled', 'true', 'Enable database-driven translations for Flutter and API messages', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3));



INSERT IGNORE INTO `translation_keys` (`key`, `namespace`, `description`, `is_system`, `created_at`, `updated_at`) VALUES
('app.name', 'app', 'app.name', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.loading', 'common', 'common.loading', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.retry', 'common', 'common.retry', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.cancel', 'common', 'common.cancel', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.confirm', 'common', 'common.confirm', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.save', 'common', 'common.save', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.close', 'common', 'common.close', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.search', 'common', 'common.search', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.filter', 'common', 'common.filter', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.empty', 'common', 'common.empty', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.success', 'common', 'common.success', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.error.unexpected', 'common', 'common.error.unexpected', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.forbidden', 'common', 'common.forbidden', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('common.unauthorized', 'common', 'common.unauthorized', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('validation.required', 'validation', 'validation.required', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('validation.phone', 'validation', 'validation.phone', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('validation.email', 'validation', 'validation.email', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('validation.file_type', 'validation', 'validation.file_type', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.login', 'auth', 'auth.login', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.create_account', 'auth', 'auth.create_account', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.phone', 'auth', 'auth.phone', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.email', 'auth', 'auth.email', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.otp', 'auth', 'auth.otp', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.verify_otp', 'auth', 'auth.verify_otp', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.trusted_device', 'auth', 'auth.trusted_device', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.logout', 'auth', 'auth.logout', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.logout_all_devices', 'auth', 'auth.logout_all_devices', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.invalid_otp', 'auth', 'auth.invalid_otp', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.otp_expired', 'auth', 'auth.otp_expired', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.account_locked', 'auth', 'auth.account_locked', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('registration.customer', 'registration', 'registration.customer', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('registration.merchant', 'registration', 'registration.merchant', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('registration.workshop', 'registration', 'registration.workshop', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('registration.full_name', 'registration', 'registration.full_name', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('registration.city', 'registration', 'registration.city', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('registration.location', 'registration', 'registration.location', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('registration.address', 'registration', 'registration.address', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('registration.store_name', 'registration', 'registration.store_name', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('registration.workshop_name', 'registration', 'registration.workshop_name', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('registration.description', 'registration', 'registration.description', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('registration.submitted', 'registration', 'registration.submitted', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('documents.national_id', 'documents', 'documents.national_id', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('documents.passport', 'documents', 'documents.passport', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('documents.bank_statement', 'documents', 'documents.bank_statement', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('documents.commercial_registration', 'documents', 'documents.commercial_registration', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('documents.front_side', 'documents', 'documents.front_side', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('documents.back_side', 'documents', 'documents.back_side', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('documents.upload', 'documents', 'documents.upload', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('marketplace.title', 'marketplace', 'marketplace.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('products.title', 'products', 'products.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('inventory.title', 'inventory', 'inventory.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('cart.title', 'cart', 'cart.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('checkout.title', 'checkout', 'checkout.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('orders.title', 'orders', 'orders.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('orders.status.pending', 'orders', 'orders.status.pending', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('orders.status.confirmed', 'orders', 'orders.status.confirmed', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('orders.status.processing', 'orders', 'orders.status.processing', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('orders.status.delivered', 'orders', 'orders.status.delivered', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('orders.status.cancelled', 'orders', 'orders.status.cancelled', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('payments.title', 'payments', 'payments.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('payments.method.cod', 'payments', 'payments.method.cod', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('payments.method.bank_transfer', 'payments', 'payments.method.bank_transfer', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('payments.proof_upload', 'payments', 'payments.proof_upload', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('accounting.title', 'accounting', 'accounting.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('wallet.title', 'wallet', 'wallet.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('wallet.balance', 'wallet', 'wallet.balance', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('wallet.insufficient_balance', 'wallet', 'wallet.insufficient_balance', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('loyalty.title', 'loyalty', 'loyalty.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('loyalty.points', 'loyalty', 'loyalty.points', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('coupons.title', 'coupons', 'coupons.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('referrals.title', 'referrals', 'referrals.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('workshops.title', 'workshops', 'workshops.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('bookings.title', 'bookings', 'bookings.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('delivery.title', 'delivery', 'delivery.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('support.title', 'support', 'support.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('complaints.title', 'support', 'complaints.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('reviews.title', 'reviews', 'reviews.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('notifications.title', 'notifications', 'notifications.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('employees.title', 'employees', 'employees.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('branches.title', 'branches', 'branches.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('merchant.dashboard', 'merchant', 'merchant.dashboard', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('workshop.dashboard', 'workshop', 'workshop.dashboard', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('warehouse.dashboard', 'warehouse', 'warehouse.dashboard', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('driver.dashboard', 'driver', 'driver.dashboard', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('finance.dashboard', 'finance', 'finance.dashboard', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('admin.title', 'admin', 'admin.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('admin.applications', 'admin', 'admin.applications', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('admin.approve', 'admin', 'admin.approve', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('admin.reject', 'admin', 'admin.reject', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('admin.request_documents', 'admin', 'admin.request_documents', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('admin.suspend', 'admin', 'admin.suspend', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('settings.title', 'settings', 'settings.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('settings.language', 'settings', 'settings.language', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('settings.arabic', 'settings', 'settings.arabic', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('settings.english', 'settings', 'settings.english', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('settings.language_changed', 'settings', 'settings.language_changed', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('audit.title', 'audit', 'audit.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('analytics.title', 'analytics', 'analytics.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('reports.title', 'reports', 'reports.title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('exports.pdf', 'exports', 'exports.pdf', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('exports.excel', 'exports', 'exports.excel', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('sms.otp', 'sms', 'sms.otp', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('email.approved_merchant', 'email', 'email.approved_merchant', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('email.approved_workshop', 'email', 'email.approved_workshop', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('email.rejected_application', 'email', 'email.rejected_application', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3));

INSERT IGNORE INTO `translation_values` (`translation_key_id`, `locale`, `value`, `platform`, `status`, `published_at`, `created_at`, `updated_at`)
SELECT k.id, v.locale, v.value, 'GLOBAL', 'PUBLISHED', CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)
FROM `translation_keys` k
JOIN (
SELECT 'app.name' AS `key`, 'ar' AS `locale`, 'غيارك' AS `value`
UNION ALL
SELECT 'app.name' AS `key`, 'en' AS `locale`, 'Ghiyarak' AS `value`
UNION ALL
SELECT 'common.loading' AS `key`, 'ar' AS `locale`, 'جاري التحميل...' AS `value`
UNION ALL
SELECT 'common.loading' AS `key`, 'en' AS `locale`, 'Loading...' AS `value`
UNION ALL
SELECT 'common.retry' AS `key`, 'ar' AS `locale`, 'إعادة المحاولة' AS `value`
UNION ALL
SELECT 'common.retry' AS `key`, 'en' AS `locale`, 'Retry' AS `value`
UNION ALL
SELECT 'common.cancel' AS `key`, 'ar' AS `locale`, 'إلغاء' AS `value`
UNION ALL
SELECT 'common.cancel' AS `key`, 'en' AS `locale`, 'Cancel' AS `value`
UNION ALL
SELECT 'common.confirm' AS `key`, 'ar' AS `locale`, 'تأكيد' AS `value`
UNION ALL
SELECT 'common.confirm' AS `key`, 'en' AS `locale`, 'Confirm' AS `value`
UNION ALL
SELECT 'common.save' AS `key`, 'ar' AS `locale`, 'حفظ' AS `value`
UNION ALL
SELECT 'common.save' AS `key`, 'en' AS `locale`, 'Save' AS `value`
UNION ALL
SELECT 'common.close' AS `key`, 'ar' AS `locale`, 'إغلاق' AS `value`
UNION ALL
SELECT 'common.close' AS `key`, 'en' AS `locale`, 'Close' AS `value`
UNION ALL
SELECT 'common.search' AS `key`, 'ar' AS `locale`, 'بحث' AS `value`
UNION ALL
SELECT 'common.search' AS `key`, 'en' AS `locale`, 'Search' AS `value`
UNION ALL
SELECT 'common.filter' AS `key`, 'ar' AS `locale`, 'تصفية' AS `value`
UNION ALL
SELECT 'common.filter' AS `key`, 'en' AS `locale`, 'Filter' AS `value`
UNION ALL
SELECT 'common.empty' AS `key`, 'ar' AS `locale`, 'لا توجد بيانات حالياً' AS `value`
UNION ALL
SELECT 'common.empty' AS `key`, 'en' AS `locale`, 'No data available' AS `value`
UNION ALL
SELECT 'common.success' AS `key`, 'ar' AS `locale`, 'تمت العملية بنجاح' AS `value`
UNION ALL
SELECT 'common.success' AS `key`, 'en' AS `locale`, 'Operation completed successfully' AS `value`
UNION ALL
SELECT 'common.error.unexpected' AS `key`, 'ar' AS `locale`, 'حدث خطأ غير متوقع' AS `value`
UNION ALL
SELECT 'common.error.unexpected' AS `key`, 'en' AS `locale`, 'Something went wrong' AS `value`
UNION ALL
SELECT 'common.forbidden' AS `key`, 'ar' AS `locale`, 'لا تملك صلاحية تنفيذ هذه العملية' AS `value`
UNION ALL
SELECT 'common.forbidden' AS `key`, 'en' AS `locale`, 'You are not allowed to perform this action' AS `value`
UNION ALL
SELECT 'common.unauthorized' AS `key`, 'ar' AS `locale`, 'يرجى تسجيل الدخول أولاً' AS `value`
UNION ALL
SELECT 'common.unauthorized' AS `key`, 'en' AS `locale`, 'Please sign in first' AS `value`
UNION ALL
SELECT 'validation.required' AS `key`, 'ar' AS `locale`, 'هذا الحقل مطلوب' AS `value`
UNION ALL
SELECT 'validation.required' AS `key`, 'en' AS `locale`, 'This field is required' AS `value`
UNION ALL
SELECT 'validation.phone' AS `key`, 'ar' AS `locale`, 'رقم الجوال غير صحيح' AS `value`
UNION ALL
SELECT 'validation.phone' AS `key`, 'en' AS `locale`, 'Invalid phone number' AS `value`
UNION ALL
SELECT 'validation.email' AS `key`, 'ar' AS `locale`, 'البريد الإلكتروني غير صحيح' AS `value`
UNION ALL
SELECT 'validation.email' AS `key`, 'en' AS `locale`, 'Invalid email address' AS `value`
UNION ALL
SELECT 'validation.file_type' AS `key`, 'ar' AS `locale`, 'نوع الملف غير مدعوم' AS `value`
UNION ALL
SELECT 'validation.file_type' AS `key`, 'en' AS `locale`, 'Unsupported file type' AS `value`
UNION ALL
SELECT 'auth.login' AS `key`, 'ar' AS `locale`, 'تسجيل الدخول' AS `value`
UNION ALL
SELECT 'auth.login' AS `key`, 'en' AS `locale`, 'Login' AS `value`
UNION ALL
SELECT 'auth.create_account' AS `key`, 'ar' AS `locale`, 'إنشاء حساب' AS `value`
UNION ALL
SELECT 'auth.create_account' AS `key`, 'en' AS `locale`, 'Create account' AS `value`
UNION ALL
SELECT 'auth.phone' AS `key`, 'ar' AS `locale`, 'رقم الجوال' AS `value`
UNION ALL
SELECT 'auth.phone' AS `key`, 'en' AS `locale`, 'Phone number' AS `value`
UNION ALL
SELECT 'auth.email' AS `key`, 'ar' AS `locale`, 'البريد الإلكتروني' AS `value`
UNION ALL
SELECT 'auth.email' AS `key`, 'en' AS `locale`, 'Email address' AS `value`
UNION ALL
SELECT 'auth.otp' AS `key`, 'ar' AS `locale`, 'رمز التحقق' AS `value`
UNION ALL
SELECT 'auth.otp' AS `key`, 'en' AS `locale`, 'Verification code' AS `value`
UNION ALL
SELECT 'auth.verify_otp' AS `key`, 'ar' AS `locale`, 'تحقق من الرمز' AS `value`
UNION ALL
SELECT 'auth.verify_otp' AS `key`, 'en' AS `locale`, 'Verify code' AS `value`
UNION ALL
SELECT 'auth.trusted_device' AS `key`, 'ar' AS `locale`, 'هذا الجهاز موثوق' AS `value`
UNION ALL
SELECT 'auth.trusted_device' AS `key`, 'en' AS `locale`, 'Trusted device' AS `value`
UNION ALL
SELECT 'auth.logout' AS `key`, 'ar' AS `locale`, 'تسجيل الخروج' AS `value`
UNION ALL
SELECT 'auth.logout' AS `key`, 'en' AS `locale`, 'Logout' AS `value`
UNION ALL
SELECT 'auth.logout_all_devices' AS `key`, 'ar' AS `locale`, 'تسجيل الخروج من كل الأجهزة' AS `value`
UNION ALL
SELECT 'auth.logout_all_devices' AS `key`, 'en' AS `locale`, 'Logout from all devices' AS `value`
UNION ALL
SELECT 'auth.invalid_otp' AS `key`, 'ar' AS `locale`, 'رمز التحقق غير صحيح' AS `value`
UNION ALL
SELECT 'auth.invalid_otp' AS `key`, 'en' AS `locale`, 'The verification code is invalid' AS `value`
UNION ALL
SELECT 'auth.otp_expired' AS `key`, 'ar' AS `locale`, 'انتهت صلاحية رمز التحقق' AS `value`
UNION ALL
SELECT 'auth.otp_expired' AS `key`, 'en' AS `locale`, 'The verification code has expired' AS `value`
UNION ALL
SELECT 'auth.account_locked' AS `key`, 'ar' AS `locale`, 'تم قفل الحساب مؤقتاً بسبب محاولات متكررة' AS `value`
UNION ALL
SELECT 'auth.account_locked' AS `key`, 'en' AS `locale`, 'Account is temporarily locked due to repeated attempts' AS `value`
UNION ALL
SELECT 'registration.customer' AS `key`, 'ar' AS `locale`, 'تسجيل عميل' AS `value`
UNION ALL
SELECT 'registration.customer' AS `key`, 'en' AS `locale`, 'Customer registration' AS `value`
UNION ALL
SELECT 'registration.merchant' AS `key`, 'ar' AS `locale`, 'تسجيل تاجر' AS `value`
UNION ALL
SELECT 'registration.merchant' AS `key`, 'en' AS `locale`, 'Merchant registration' AS `value`
UNION ALL
SELECT 'registration.workshop' AS `key`, 'ar' AS `locale`, 'تسجيل ورشة' AS `value`
UNION ALL
SELECT 'registration.workshop' AS `key`, 'en' AS `locale`, 'Workshop registration' AS `value`
UNION ALL
SELECT 'registration.full_name' AS `key`, 'ar' AS `locale`, 'الاسم الكامل' AS `value`
UNION ALL
SELECT 'registration.full_name' AS `key`, 'en' AS `locale`, 'Full name' AS `value`
UNION ALL
SELECT 'registration.city' AS `key`, 'ar' AS `locale`, 'المدينة' AS `value`
UNION ALL
SELECT 'registration.city' AS `key`, 'en' AS `locale`, 'City' AS `value`
UNION ALL
SELECT 'registration.location' AS `key`, 'ar' AS `locale`, 'الموقع' AS `value`
UNION ALL
SELECT 'registration.location' AS `key`, 'en' AS `locale`, 'Location' AS `value`
UNION ALL
SELECT 'registration.address' AS `key`, 'ar' AS `locale`, 'العنوان' AS `value`
UNION ALL
SELECT 'registration.address' AS `key`, 'en' AS `locale`, 'Address' AS `value`
UNION ALL
SELECT 'registration.store_name' AS `key`, 'ar' AS `locale`, 'اسم المتجر' AS `value`
UNION ALL
SELECT 'registration.store_name' AS `key`, 'en' AS `locale`, 'Store name' AS `value`
UNION ALL
SELECT 'registration.workshop_name' AS `key`, 'ar' AS `locale`, 'اسم الورشة' AS `value`
UNION ALL
SELECT 'registration.workshop_name' AS `key`, 'en' AS `locale`, 'Workshop name' AS `value`
UNION ALL
SELECT 'registration.description' AS `key`, 'ar' AS `locale`, 'وصف النشاط' AS `value`
UNION ALL
SELECT 'registration.description' AS `key`, 'en' AS `locale`, 'Business description' AS `value`
UNION ALL
SELECT 'registration.submitted' AS `key`, 'ar' AS `locale`, 'تم إرسال طلبك بنجاح وهو حالياً قيد المراجعة. سنقوم بإشعارك عند اكتمال المراجعة.' AS `value`
UNION ALL
SELECT 'registration.submitted' AS `key`, 'en' AS `locale`, 'Your application has been submitted successfully and is currently under review. We will notify you once the review process is completed.' AS `value`
UNION ALL
SELECT 'documents.national_id' AS `key`, 'ar' AS `locale`, 'الهوية الوطنية' AS `value`
UNION ALL
SELECT 'documents.national_id' AS `key`, 'en' AS `locale`, 'National ID' AS `value`
UNION ALL
SELECT 'documents.passport' AS `key`, 'ar' AS `locale`, 'جواز السفر' AS `value`
UNION ALL
SELECT 'documents.passport' AS `key`, 'en' AS `locale`, 'Passport' AS `value`
UNION ALL
SELECT 'documents.bank_statement' AS `key`, 'ar' AS `locale`, 'كشف حساب بنكي' AS `value`
UNION ALL
SELECT 'documents.bank_statement' AS `key`, 'en' AS `locale`, 'Bank Statement' AS `value`
UNION ALL
SELECT 'documents.commercial_registration' AS `key`, 'ar' AS `locale`, 'السجل التجاري' AS `value`
UNION ALL
SELECT 'documents.commercial_registration' AS `key`, 'en' AS `locale`, 'Commercial Registration' AS `value`
UNION ALL
SELECT 'documents.front_side' AS `key`, 'ar' AS `locale`, 'الصورة الأمامية' AS `value`
UNION ALL
SELECT 'documents.front_side' AS `key`, 'en' AS `locale`, 'Front side image' AS `value`
UNION ALL
SELECT 'documents.back_side' AS `key`, 'ar' AS `locale`, 'الصورة الخلفية' AS `value`
UNION ALL
SELECT 'documents.back_side' AS `key`, 'en' AS `locale`, 'Back side image' AS `value`
UNION ALL
SELECT 'documents.upload' AS `key`, 'ar' AS `locale`, 'رفع المستند' AS `value`
UNION ALL
SELECT 'documents.upload' AS `key`, 'en' AS `locale`, 'Upload document' AS `value`
UNION ALL
SELECT 'marketplace.title' AS `key`, 'ar' AS `locale`, 'سوق قطع الغيار' AS `value`
UNION ALL
SELECT 'marketplace.title' AS `key`, 'en' AS `locale`, 'Spare Parts Marketplace' AS `value`
UNION ALL
SELECT 'products.title' AS `key`, 'ar' AS `locale`, 'المنتجات' AS `value`
UNION ALL
SELECT 'products.title' AS `key`, 'en' AS `locale`, 'Products' AS `value`
UNION ALL
SELECT 'inventory.title' AS `key`, 'ar' AS `locale`, 'المخزون' AS `value`
UNION ALL
SELECT 'inventory.title' AS `key`, 'en' AS `locale`, 'Inventory' AS `value`
UNION ALL
SELECT 'cart.title' AS `key`, 'ar' AS `locale`, 'السلة' AS `value`
UNION ALL
SELECT 'cart.title' AS `key`, 'en' AS `locale`, 'Cart' AS `value`
UNION ALL
SELECT 'checkout.title' AS `key`, 'ar' AS `locale`, 'إتمام الطلب' AS `value`
UNION ALL
SELECT 'checkout.title' AS `key`, 'en' AS `locale`, 'Checkout' AS `value`
UNION ALL
SELECT 'orders.title' AS `key`, 'ar' AS `locale`, 'طلباتي' AS `value`
UNION ALL
SELECT 'orders.title' AS `key`, 'en' AS `locale`, 'My Orders' AS `value`
UNION ALL
SELECT 'orders.status.pending' AS `key`, 'ar' AS `locale`, 'قيد الانتظار' AS `value`
UNION ALL
SELECT 'orders.status.pending' AS `key`, 'en' AS `locale`, 'Pending' AS `value`
UNION ALL
SELECT 'orders.status.confirmed' AS `key`, 'ar' AS `locale`, 'مؤكد' AS `value`
UNION ALL
SELECT 'orders.status.confirmed' AS `key`, 'en' AS `locale`, 'Confirmed' AS `value`
UNION ALL
SELECT 'orders.status.processing' AS `key`, 'ar' AS `locale`, 'قيد التجهيز' AS `value`
UNION ALL
SELECT 'orders.status.processing' AS `key`, 'en' AS `locale`, 'Processing' AS `value`
UNION ALL
SELECT 'orders.status.delivered' AS `key`, 'ar' AS `locale`, 'تم التسليم' AS `value`
UNION ALL
SELECT 'orders.status.delivered' AS `key`, 'en' AS `locale`, 'Delivered' AS `value`
UNION ALL
SELECT 'orders.status.cancelled' AS `key`, 'ar' AS `locale`, 'ملغي' AS `value`
UNION ALL
SELECT 'orders.status.cancelled' AS `key`, 'en' AS `locale`, 'Cancelled' AS `value`
UNION ALL
SELECT 'payments.title' AS `key`, 'ar' AS `locale`, 'المدفوعات' AS `value`
UNION ALL
SELECT 'payments.title' AS `key`, 'en' AS `locale`, 'Payments' AS `value`
UNION ALL
SELECT 'payments.method.cod' AS `key`, 'ar' AS `locale`, 'الدفع عند الاستلام' AS `value`
UNION ALL
SELECT 'payments.method.cod' AS `key`, 'en' AS `locale`, 'Cash on Delivery' AS `value`
UNION ALL
SELECT 'payments.method.bank_transfer' AS `key`, 'ar' AS `locale`, 'تحويل بنكي' AS `value`
UNION ALL
SELECT 'payments.method.bank_transfer' AS `key`, 'en' AS `locale`, 'Bank Transfer' AS `value`
UNION ALL
SELECT 'payments.proof_upload' AS `key`, 'ar' AS `locale`, 'رفع إثبات الدفع' AS `value`
UNION ALL
SELECT 'payments.proof_upload' AS `key`, 'en' AS `locale`, 'Upload payment proof' AS `value`
UNION ALL
SELECT 'accounting.title' AS `key`, 'ar' AS `locale`, 'المحاسبة' AS `value`
UNION ALL
SELECT 'accounting.title' AS `key`, 'en' AS `locale`, 'Accounting' AS `value`
UNION ALL
SELECT 'wallet.title' AS `key`, 'ar' AS `locale`, 'محفظتي' AS `value`
UNION ALL
SELECT 'wallet.title' AS `key`, 'en' AS `locale`, 'My Wallet' AS `value`
UNION ALL
SELECT 'wallet.balance' AS `key`, 'ar' AS `locale`, 'رصيد المحفظة' AS `value`
UNION ALL
SELECT 'wallet.balance' AS `key`, 'en' AS `locale`, 'Wallet balance' AS `value`
UNION ALL
SELECT 'wallet.insufficient_balance' AS `key`, 'ar' AS `locale`, 'رصيد المحفظة غير كافٍ' AS `value`
UNION ALL
SELECT 'wallet.insufficient_balance' AS `key`, 'en' AS `locale`, 'Wallet balance is insufficient' AS `value`
UNION ALL
SELECT 'loyalty.title' AS `key`, 'ar' AS `locale`, 'نقاط الولاء' AS `value`
UNION ALL
SELECT 'loyalty.title' AS `key`, 'en' AS `locale`, 'Loyalty Points' AS `value`
UNION ALL
SELECT 'loyalty.points' AS `key`, 'ar' AS `locale`, 'النقاط' AS `value`
UNION ALL
SELECT 'loyalty.points' AS `key`, 'en' AS `locale`, 'Points' AS `value`
UNION ALL
SELECT 'coupons.title' AS `key`, 'ar' AS `locale`, 'الكوبونات' AS `value`
UNION ALL
SELECT 'coupons.title' AS `key`, 'en' AS `locale`, 'Coupons' AS `value`
UNION ALL
SELECT 'referrals.title' AS `key`, 'ar' AS `locale`, 'الإحالات' AS `value`
UNION ALL
SELECT 'referrals.title' AS `key`, 'en' AS `locale`, 'Referrals' AS `value`
UNION ALL
SELECT 'workshops.title' AS `key`, 'ar' AS `locale`, 'الورش' AS `value`
UNION ALL
SELECT 'workshops.title' AS `key`, 'en' AS `locale`, 'Workshops' AS `value`
UNION ALL
SELECT 'bookings.title' AS `key`, 'ar' AS `locale`, 'الحجوزات' AS `value`
UNION ALL
SELECT 'bookings.title' AS `key`, 'en' AS `locale`, 'Bookings' AS `value`
UNION ALL
SELECT 'delivery.title' AS `key`, 'ar' AS `locale`, 'الشحن والتوصيل' AS `value`
UNION ALL
SELECT 'delivery.title' AS `key`, 'en' AS `locale`, 'Delivery' AS `value`
UNION ALL
SELECT 'support.title' AS `key`, 'ar' AS `locale`, 'الدعم والشكاوى' AS `value`
UNION ALL
SELECT 'support.title' AS `key`, 'en' AS `locale`, 'Support & Complaints' AS `value`
UNION ALL
SELECT 'complaints.title' AS `key`, 'ar' AS `locale`, 'الشكاوى' AS `value`
UNION ALL
SELECT 'complaints.title' AS `key`, 'en' AS `locale`, 'Complaints' AS `value`
UNION ALL
SELECT 'reviews.title' AS `key`, 'ar' AS `locale`, 'التقييمات' AS `value`
UNION ALL
SELECT 'reviews.title' AS `key`, 'en' AS `locale`, 'Reviews' AS `value`
UNION ALL
SELECT 'notifications.title' AS `key`, 'ar' AS `locale`, 'الإشعارات' AS `value`
UNION ALL
SELECT 'notifications.title' AS `key`, 'en' AS `locale`, 'Notifications' AS `value`
UNION ALL
SELECT 'employees.title' AS `key`, 'ar' AS `locale`, 'الموظفون' AS `value`
UNION ALL
SELECT 'employees.title' AS `key`, 'en' AS `locale`, 'Employees' AS `value`
UNION ALL
SELECT 'branches.title' AS `key`, 'ar' AS `locale`, 'الفروع' AS `value`
UNION ALL
SELECT 'branches.title' AS `key`, 'en' AS `locale`, 'Branches' AS `value`
UNION ALL
SELECT 'merchant.dashboard' AS `key`, 'ar' AS `locale`, 'لوحة التاجر' AS `value`
UNION ALL
SELECT 'merchant.dashboard' AS `key`, 'en' AS `locale`, 'Merchant Dashboard' AS `value`
UNION ALL
SELECT 'workshop.dashboard' AS `key`, 'ar' AS `locale`, 'لوحة الورشة' AS `value`
UNION ALL
SELECT 'workshop.dashboard' AS `key`, 'en' AS `locale`, 'Workshop Dashboard' AS `value`
UNION ALL
SELECT 'warehouse.dashboard' AS `key`, 'ar' AS `locale`, 'لوحة المستودع' AS `value`
UNION ALL
SELECT 'warehouse.dashboard' AS `key`, 'en' AS `locale`, 'Warehouse Dashboard' AS `value`
UNION ALL
SELECT 'driver.dashboard' AS `key`, 'ar' AS `locale`, 'لوحة السائق' AS `value`
UNION ALL
SELECT 'driver.dashboard' AS `key`, 'en' AS `locale`, 'Driver Dashboard' AS `value`
UNION ALL
SELECT 'finance.dashboard' AS `key`, 'ar' AS `locale`, 'لوحة المالية' AS `value`
UNION ALL
SELECT 'finance.dashboard' AS `key`, 'en' AS `locale`, 'Finance Dashboard' AS `value`
UNION ALL
SELECT 'admin.title' AS `key`, 'ar' AS `locale`, 'مركز التحكم' AS `value`
UNION ALL
SELECT 'admin.title' AS `key`, 'en' AS `locale`, 'Control Center' AS `value`
UNION ALL
SELECT 'admin.applications' AS `key`, 'ar' AS `locale`, 'طلبات العضوية' AS `value`
UNION ALL
SELECT 'admin.applications' AS `key`, 'en' AS `locale`, 'Membership Applications' AS `value`
UNION ALL
SELECT 'admin.approve' AS `key`, 'ar' AS `locale`, 'اعتماد' AS `value`
UNION ALL
SELECT 'admin.approve' AS `key`, 'en' AS `locale`, 'Approve' AS `value`
UNION ALL
SELECT 'admin.reject' AS `key`, 'ar' AS `locale`, 'رفض' AS `value`
UNION ALL
SELECT 'admin.reject' AS `key`, 'en' AS `locale`, 'Reject' AS `value`
UNION ALL
SELECT 'admin.request_documents' AS `key`, 'ar' AS `locale`, 'طلب مستندات إضافية' AS `value`
UNION ALL
SELECT 'admin.request_documents' AS `key`, 'en' AS `locale`, 'Request additional documents' AS `value`
UNION ALL
SELECT 'admin.suspend' AS `key`, 'ar' AS `locale`, 'تعليق' AS `value`
UNION ALL
SELECT 'admin.suspend' AS `key`, 'en' AS `locale`, 'Suspend' AS `value`
UNION ALL
SELECT 'settings.title' AS `key`, 'ar' AS `locale`, 'الإعدادات' AS `value`
UNION ALL
SELECT 'settings.title' AS `key`, 'en' AS `locale`, 'Settings' AS `value`
UNION ALL
SELECT 'settings.language' AS `key`, 'ar' AS `locale`, 'اللغة' AS `value`
UNION ALL
SELECT 'settings.language' AS `key`, 'en' AS `locale`, 'Language' AS `value`
UNION ALL
SELECT 'settings.arabic' AS `key`, 'ar' AS `locale`, 'العربية' AS `value`
UNION ALL
SELECT 'settings.arabic' AS `key`, 'en' AS `locale`, 'Arabic' AS `value`
UNION ALL
SELECT 'settings.english' AS `key`, 'ar' AS `locale`, 'الإنجليزية' AS `value`
UNION ALL
SELECT 'settings.english' AS `key`, 'en' AS `locale`, 'English' AS `value`
UNION ALL
SELECT 'settings.language_changed' AS `key`, 'ar' AS `locale`, 'يمكنك تغيير اللغة فورًا بدون إعادة تشغيل' AS `value`
UNION ALL
SELECT 'settings.language_changed' AS `key`, 'en' AS `locale`, 'You can change language instantly without restart' AS `value`
UNION ALL
SELECT 'audit.title' AS `key`, 'ar' AS `locale`, 'سجل التدقيق' AS `value`
UNION ALL
SELECT 'audit.title' AS `key`, 'en' AS `locale`, 'Audit log' AS `value`
UNION ALL
SELECT 'analytics.title' AS `key`, 'ar' AS `locale`, 'التحليلات' AS `value`
UNION ALL
SELECT 'analytics.title' AS `key`, 'en' AS `locale`, 'Analytics' AS `value`
UNION ALL
SELECT 'reports.title' AS `key`, 'ar' AS `locale`, 'التقارير' AS `value`
UNION ALL
SELECT 'reports.title' AS `key`, 'en' AS `locale`, 'Reports' AS `value`
UNION ALL
SELECT 'exports.pdf' AS `key`, 'ar' AS `locale`, 'تصدير PDF' AS `value`
UNION ALL
SELECT 'exports.pdf' AS `key`, 'en' AS `locale`, 'Export PDF' AS `value`
UNION ALL
SELECT 'exports.excel' AS `key`, 'ar' AS `locale`, 'تصدير Excel' AS `value`
UNION ALL
SELECT 'exports.excel' AS `key`, 'en' AS `locale`, 'Export Excel' AS `value`
UNION ALL
SELECT 'sms.otp' AS `key`, 'ar' AS `locale`, 'رمز التحقق الخاص بك في غيارك هو {code}. لا تشاركه مع أي شخص.' AS `value`
UNION ALL
SELECT 'sms.otp' AS `key`, 'en' AS `locale`, 'Your Ghiyarak verification code is {code}. Do not share it with anyone.' AS `value`
UNION ALL
SELECT 'email.approved_merchant' AS `key`, 'ar' AS `locale`, 'تم اعتماد حساب التاجر في غيارك. يمكنك الآن الدخول إلى لوحة التاجر وإدارة نشاطك.' AS `value`
UNION ALL
SELECT 'email.approved_merchant' AS `key`, 'en' AS `locale`, 'Your Ghiyarak merchant account has been successfully approved. You can now access your merchant dashboard and start managing your business.' AS `value`
UNION ALL
SELECT 'email.approved_workshop' AS `key`, 'ar' AS `locale`, 'تم اعتماد حساب الورشة في غيارك. يمكنك الآن الدخول إلى لوحة الورشة وإدارة خدماتك.' AS `value`
UNION ALL
SELECT 'email.approved_workshop' AS `key`, 'en' AS `locale`, 'Your Ghiyarak workshop account has been successfully approved. You can now access your workshop dashboard and start managing your services.' AS `value`
UNION ALL
SELECT 'email.rejected_application' AS `key`, 'ar' AS `locale`, 'تعذر اعتماد طلبك لأن البيانات أو المستندات لا تلبي متطلبات المنصة. يرجى تحديث البيانات وإرسال طلب جديد.' AS `value`
UNION ALL
SELECT 'email.rejected_application' AS `key`, 'en' AS `locale`, 'Your application could not be approved because the submitted information or documents did not meet the platform requirements. Please update your information and submit a new application.' AS `value`
) v ON v.`key` = k.`key`;

INSERT IGNORE INTO `iam_permissions` (`code`, `module_code`, `name`, `created_at`) VALUES
('i18n.catalog.manage', 'system', 'Manage translation catalog', CURRENT_TIMESTAMP(3));

INSERT IGNORE INTO `iam_role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id
FROM `iam_roles` r JOIN `iam_permissions` p ON p.code = 'i18n.catalog.manage'
WHERE r.code IN ('super_admin', 'admin_super');
