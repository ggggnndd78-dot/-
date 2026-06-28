
-- Phase 21: Enterprise Admin Control Center settings seed.
-- This migration intentionally avoids destructive schema changes and uses the existing system_settings table.

INSERT INTO system_settings (`key`, value_json, value_text, description, is_public, created_at, updated_at)
VALUES
  ('platform.default_locale', JSON_OBJECT('locale', 'ar'), 'ar', 'Default platform locale used before a user selects a language.', TRUE, NOW(), NOW()),
  ('platform.supported_locales', JSON_ARRAY('ar', 'en'), 'ar,en', 'Runtime-supported platform locales.', TRUE, NOW(), NOW()),
  ('platform.rtl_locales', JSON_ARRAY('ar'), 'ar', 'Locales rendered right-to-left.', TRUE, NOW(), NOW()),
  ('platform.currency', JSON_OBJECT('code', 'YER', 'symbol', 'ر.ي'), 'YER', 'Default platform currency.', TRUE, NOW(), NOW()),
  ('feature.admin_control_center', JSON_OBJECT('enabled', TRUE), 'enabled', 'Enterprise Admin Control Center enabled flag.', TRUE, NOW(), NOW()),
  ('feature.analytics_center', JSON_OBJECT('enabled', TRUE), 'enabled', 'Admin analytics center enabled flag.', TRUE, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  value_json = VALUES(value_json),
  value_text = VALUES(value_text),
  description = VALUES(description),
  is_public = VALUES(is_public),
  updated_at = NOW();
