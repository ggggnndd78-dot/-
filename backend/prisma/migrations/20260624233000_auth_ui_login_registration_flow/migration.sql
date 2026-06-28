INSERT IGNORE INTO `translation_keys` (`key`, `namespace`, `description`, `is_system`, `created_at`, `updated_at`) VALUES
('auth.login.title', 'auth', 'Secure login title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.login.button', 'auth', 'Login button', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.login.secure_subtitle', 'auth', 'Trusted device login subtitle', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.phone_hint_yemen', 'auth', 'Yemeni phone hint', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.trusted_device_note', 'auth', 'Trusted device privacy note', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.validation.phone_required', 'validation', 'Phone required', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.validation.yemeni_phone', 'validation', 'Yemeni phone validation', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.validation.otp_required', 'validation', 'OTP required', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.validation.otp_invalid', 'validation', 'OTP invalid', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.error.login_start_failed', 'auth', 'Login start failed', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.error.otp_failed', 'auth', 'OTP failed', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.error.otp_verify_failed', 'auth', 'OTP verify failed', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.register.title', 'registration', 'Register title', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.register.subtitle', 'registration', 'Register subtitle', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.account_type', 'registration', 'Account type field', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.choose_account_type', 'registration', 'Choose account type', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.select_account_type_required', 'registration', 'Account type required', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.customer_registration', 'registration', 'Customer information', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.basic_information', 'registration', 'Basic information', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.full_name', 'registration', 'Full name', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.city', 'registration', 'City', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.location', 'registration', 'Location', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.address', 'registration', 'Address', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.store_name', 'registration', 'Store name', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.workshop_name', 'registration', 'Workshop name', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.business_description', 'registration', 'Business description', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.provider_review_notice', 'registration', 'Provider review notice', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.create_customer_account', 'registration', 'Create customer account', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.verify_phone_continue_documents', 'registration', 'Verify and continue documents', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.back_to_login', 'registration', 'Back to login', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.otp_hint', 'auth', 'OTP hint', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.otp.sent_to', 'auth', 'OTP sent message', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.otp.provider_flow', 'auth', 'OTP provider flow', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.otp.customer_flow', 'auth', 'OTP customer flow', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('auth.otp.login_flow', 'auth', 'OTP login flow', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('role.customer', 'roles', 'Customer role label', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('role.merchant_owner', 'roles', 'Merchant role label', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
('role.workshop_owner', 'roles', 'Workshop owner role label', TRUE, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3));

INSERT IGNORE INTO `translation_values` (`translation_key_id`, `locale`, `value`, `platform`, `status`, `published_at`, `created_at`, `updated_at`)
SELECT k.id, v.locale, v.value, 'GLOBAL', 'PUBLISHED', CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)
FROM `translation_keys` k
JOIN (
SELECT 'auth.login.title' AS `key`, 'ar' AS locale, 'تسجيل الدخول الآمن' AS value UNION ALL
SELECT 'auth.login.title', 'en', 'Secure login' UNION ALL
SELECT 'auth.login.button', 'ar', 'تسجيل الدخول' UNION ALL
SELECT 'auth.login.button', 'en', 'Login' UNION ALL
SELECT 'auth.login.secure_subtitle', 'ar', 'أدخل رقم جوالك فقط. إذا كان جهازك موثوقًا سيتم الدخول مباشرة، وإذا كان جديدًا سنرسل رمز تحقق.' UNION ALL
SELECT 'auth.login.secure_subtitle', 'en', 'Enter only your phone number. Trusted devices sign in directly; new devices require OTP.' UNION ALL
SELECT 'auth.phone_hint_yemen', 'ar', 'مثال: 781699203 أو +967781699203' UNION ALL
SELECT 'auth.phone_hint_yemen', 'en', 'Example: 781699203 or +967781699203' UNION ALL
SELECT 'auth.trusted_device_note', 'ar', 'لا تظهر نوع حسابك في شاشة الدخول. النظام يحدد لوحة التحكم والصلاحيات تلقائيًا بعد التحقق.' UNION ALL
SELECT 'auth.trusted_device_note', 'en', 'The login screen does not expose account type. The system routes you automatically by role and permissions after verification.' UNION ALL
SELECT 'auth.validation.phone_required', 'ar', 'رقم الجوال مطلوب' UNION ALL
SELECT 'auth.validation.phone_required', 'en', 'Phone number is required' UNION ALL
SELECT 'auth.validation.yemeni_phone', 'ar', 'أدخل رقم جوال يمني صحيح يبدأ بـ 7 ويتكون من 9 أرقام.' UNION ALL
SELECT 'auth.validation.yemeni_phone', 'en', 'Enter a valid Yemeni mobile number starting with 7 and containing 9 digits.' UNION ALL
SELECT 'auth.validation.otp_required', 'ar', 'رمز التحقق مطلوب' UNION ALL
SELECT 'auth.validation.otp_required', 'en', 'Verification code is required' UNION ALL
SELECT 'auth.validation.otp_invalid', 'ar', 'رمز التحقق غير صالح' UNION ALL
SELECT 'auth.validation.otp_invalid', 'en', 'Invalid verification code' UNION ALL
SELECT 'auth.error.login_start_failed', 'ar', 'تعذر بدء تسجيل الدخول' UNION ALL
SELECT 'auth.error.login_start_failed', 'en', 'Could not start login' UNION ALL
SELECT 'auth.error.otp_failed', 'ar', 'تعذر إرسال رمز التحقق' UNION ALL
SELECT 'auth.error.otp_failed', 'en', 'Could not send verification code' UNION ALL
SELECT 'auth.error.otp_verify_failed', 'ar', 'تعذر التحقق من الرمز' UNION ALL
SELECT 'auth.error.otp_verify_failed', 'en', 'Could not verify code' UNION ALL
SELECT 'auth.register.title', 'ar', 'إنشاء حساب جديد' UNION ALL
SELECT 'auth.register.title', 'en', 'Create new account' UNION ALL
SELECT 'auth.register.subtitle', 'ar', 'اختر نوع الحساب أولًا، ثم أكمل البيانات المطلوبة فقط حسب نوع الحساب.' UNION ALL
SELECT 'auth.register.subtitle', 'en', 'Choose the account type first, then complete only the required fields for that type.' UNION ALL
SELECT 'auth.account_type', 'ar', 'نوع الحساب' UNION ALL
SELECT 'auth.account_type', 'en', 'Account type' UNION ALL
SELECT 'auth.choose_account_type', 'ar', 'اختر نوع الحساب' UNION ALL
SELECT 'auth.choose_account_type', 'en', 'Choose account type' UNION ALL
SELECT 'auth.select_account_type_required', 'ar', 'اختر نوع الحساب أولًا' UNION ALL
SELECT 'auth.select_account_type_required', 'en', 'Choose account type first' UNION ALL
SELECT 'auth.customer_registration', 'ar', 'بيانات العميل' UNION ALL
SELECT 'auth.customer_registration', 'en', 'Customer information' UNION ALL
SELECT 'auth.basic_information', 'ar', 'البيانات الأساسية' UNION ALL
SELECT 'auth.basic_information', 'en', 'Basic information' UNION ALL
SELECT 'auth.full_name', 'ar', 'الاسم الكامل' UNION ALL
SELECT 'auth.full_name', 'en', 'Full name' UNION ALL
SELECT 'auth.city', 'ar', 'المدينة' UNION ALL
SELECT 'auth.city', 'en', 'City' UNION ALL
SELECT 'auth.location', 'ar', 'الموقع' UNION ALL
SELECT 'auth.location', 'en', 'Location' UNION ALL
SELECT 'auth.address', 'ar', 'العنوان' UNION ALL
SELECT 'auth.address', 'en', 'Address' UNION ALL
SELECT 'auth.store_name', 'ar', 'اسم المتجر' UNION ALL
SELECT 'auth.store_name', 'en', 'Store name' UNION ALL
SELECT 'auth.workshop_name', 'ar', 'اسم الورشة' UNION ALL
SELECT 'auth.workshop_name', 'en', 'Workshop name' UNION ALL
SELECT 'auth.business_description', 'ar', 'وصف النشاط' UNION ALL
SELECT 'auth.business_description', 'en', 'Business description' UNION ALL
SELECT 'auth.provider_review_notice', 'ar', 'بعد التحقق من رقم الجوال ستنتقل إلى مرحلة رفع الوثائق. لن يتم فتح لوحة التاجر أو الورشة إلا بعد اعتماد الإدارة.' UNION ALL
SELECT 'auth.provider_review_notice', 'en', 'After phone verification you will continue to document upload. Merchant/workshop dashboards open only after admin approval.' UNION ALL
SELECT 'auth.create_customer_account', 'ar', 'إرسال رمز التحقق وإنشاء حساب العميل' UNION ALL
SELECT 'auth.create_customer_account', 'en', 'Send code and create customer account' UNION ALL
SELECT 'auth.verify_phone_continue_documents', 'ar', 'إرسال رمز التحقق ومتابعة الوثائق' UNION ALL
SELECT 'auth.verify_phone_continue_documents', 'en', 'Send code and continue documents' UNION ALL
SELECT 'auth.back_to_login', 'ar', 'العودة إلى تسجيل الدخول' UNION ALL
SELECT 'auth.back_to_login', 'en', 'Back to login' UNION ALL
SELECT 'auth.otp_hint', 'ar', 'أدخل رمز SMS' UNION ALL
SELECT 'auth.otp_hint', 'en', 'Enter SMS code' UNION ALL
SELECT 'auth.otp.sent_to', 'ar', 'تم إرسال رمز SMS إلى {phone}. سيتم توثيق هذا الجهاز بعد التحقق بنجاح.' UNION ALL
SELECT 'auth.otp.sent_to', 'en', 'SMS code was sent to {phone}. This device will be trusted after successful verification.' UNION ALL
SELECT 'auth.otp.provider_flow', 'ar', 'بعد التحقق ستنتقل لإكمال بيانات المنشأة ورفع المستندات.' UNION ALL
SELECT 'auth.otp.provider_flow', 'en', 'After verification you will continue business information and document upload.' UNION ALL
SELECT 'auth.otp.customer_flow', 'ar', 'بعد التحقق سيتم تفعيل حساب العميل مباشرة.' UNION ALL
SELECT 'auth.otp.customer_flow', 'en', 'After verification the customer account will be activated immediately.' UNION ALL
SELECT 'auth.otp.login_flow', 'ar', 'بعد التحقق سيتم توجيهك حسب صلاحيات حسابك.' UNION ALL
SELECT 'auth.otp.login_flow', 'en', 'After verification you will be routed according to your permissions.' UNION ALL
SELECT 'role.customer', 'ar', 'عميل' UNION ALL
SELECT 'role.customer', 'en', 'Customer' UNION ALL
SELECT 'role.merchant_owner', 'ar', 'تاجر' UNION ALL
SELECT 'role.merchant_owner', 'en', 'Merchant' UNION ALL
SELECT 'role.workshop_owner', 'ar', 'صاحب ورشة' UNION ALL
SELECT 'role.workshop_owner', 'en', 'Workshop owner'
) v ON v.`key` = k.`key`;
