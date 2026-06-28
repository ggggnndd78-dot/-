
-- Phase 22: System hardening, unification, runtime i18n, and analytics snapshots.

CREATE TABLE IF NOT EXISTS `system_modules` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(80) NOT NULL,
  `name_ar` VARCHAR(160) NOT NULL,
  `name_en` VARCHAR(160) NOT NULL,
  `route` VARCHAR(240) NULL,
  `icon` VARCHAR(80) NULL,
  `group_code` VARCHAR(80) NOT NULL,
  `permission_code` VARCHAR(120) NULL,
  `source_module` VARCHAR(80) NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
  `sort_order` INT NOT NULL DEFAULT 0,
  `metadata_json` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `system_modules_code_key` (`code`),
  KEY `system_modules_group_sort_idx` (`group_code`, `sort_order`),
  KEY `system_modules_permission_idx` (`permission_code`),
  KEY `system_modules_status_idx` (`status`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `translation_entries` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `translation_key` VARCHAR(180) NOT NULL,
  `locale` VARCHAR(10) NOT NULL,
  `value` TEXT NOT NULL,
  `namespace` VARCHAR(80) NOT NULL DEFAULT 'app',
  `platform` VARCHAR(40) NOT NULL DEFAULT 'GLOBAL',
  `is_system` BOOLEAN NOT NULL DEFAULT FALSE,
  `updated_by_user_id` INT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `translation_entries_key_locale_platform_key` (`translation_key`, `locale`, `platform`),
  KEY `translation_entries_namespace_locale_idx` (`namespace`, `locale`),
  KEY `translation_entries_updated_by_user_idx` (`updated_by_user_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `analytics_metric_snapshots` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `metric_key` VARCHAR(120) NOT NULL,
  `metric_group` VARCHAR(80) NOT NULL,
  `metric_label_ar` VARCHAR(180) NULL,
  `metric_label_en` VARCHAR(180) NULL,
  `numeric_value` DECIMAL(18,2) NOT NULL DEFAULT 0,
  `dimensions_json` JSON NULL,
  `source_module` VARCHAR(80) NULL,
  `period_start` DATETIME(3) NULL,
  `period_end` DATETIME(3) NULL,
  `calculated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `analytics_metric_snapshots_group_calculated_idx` (`metric_group`, `calculated_at`),
  KEY `analytics_metric_snapshots_key_calculated_idx` (`metric_key`, `calculated_at`),
  KEY `analytics_metric_snapshots_source_calculated_idx` (`source_module`, `calculated_at`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `system_audit_findings` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `severity` VARCHAR(20) NOT NULL,
  `category` VARCHAR(80) NOT NULL,
  `source_layer` VARCHAR(80) NOT NULL,
  `reference` VARCHAR(180) NULL,
  `description` TEXT NOT NULL,
  `root_cause` TEXT NULL,
  `impact` TEXT NULL,
  `recommendation` TEXT NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'OPEN',
  `created_by_user_id` INT NULL,
  `resolved_by_user_id` INT NULL,
  `resolved_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `system_audit_findings_severity_status_idx` (`severity`, `status`),
  KEY `system_audit_findings_category_status_idx` (`category`, `status`),
  KEY `system_audit_findings_source_layer_idx` (`source_layer`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `audit_integrity_checkpoints` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `checkpoint_key` VARCHAR(120) NOT NULL,
  `last_audit_log_id` INT NULL,
  `checksum` VARCHAR(128) NOT NULL,
  `record_count` INT NOT NULL DEFAULT 0,
  `metadata_json` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `audit_integrity_checkpoints_key` (`checkpoint_key`),
  KEY `audit_integrity_checkpoints_last_audit_log_id_idx` (`last_audit_log_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT IGNORE INTO `system_settings` (`key`, `value_text`, `value_json`, `description`, `is_public`, `created_at`, `updated_at`) VALUES
('platform.default_locale', 'ar', JSON_OBJECT('locale','ar'), 'Default runtime locale', TRUE, NOW(3), NOW(3)),
('platform.supported_locales', 'ar,en', JSON_ARRAY('ar','en'), 'Supported application locales', TRUE, NOW(3), NOW(3)),
('platform.rtl_locales', 'ar', JSON_ARRAY('ar'), 'RTL locales', TRUE, NOW(3), NOW(3)),
('security.audit_immutable', 'enabled', JSON_OBJECT('enabled', true), 'Audit log immutability policy', FALSE, NOW(3), NOW(3)),
('analytics.snapshot_strategy', 'daily_and_on_demand', JSON_OBJECT('mode','daily_and_on_demand'), 'Analytics snapshot strategy', FALSE, NOW(3), NOW(3));

INSERT IGNORE INTO `system_modules` (`code`, `name_ar`, `name_en`, `route`, `icon`, `group_code`, `permission_code`, `source_module`, `sort_order`) VALUES
('dashboard', 'لوحة المؤشرات', 'Dashboard', '/admin/dashboard', 'dashboard', 'operations', 'view_admin_panel', 'admin', 10),
('analytics', 'التحليلات', 'Analytics', '/admin/analytics', 'analytics', 'analytics', 'view_reports', 'admin', 20),
('users', 'المستخدمون', 'Users', '/admin/users', 'users', 'identity', 'manage_users', 'users', 30),
('organizations', 'المؤسسات', 'Organizations', '/admin/verifications', 'business', 'identity', 'review_verifications', 'organizations', 40),
('orders', 'الطلبات', 'Orders', '/admin/orders', 'orders', 'commerce', 'admin.orders.view', 'orders', 50),
('payments', 'المدفوعات', 'Payments', '/finance/review', 'payments', 'finance', 'finance.payments.review', 'payments', 60),
('accounting', 'المحاسبة', 'Accounting', '/finance/accounting', 'account_balance', 'finance', 'finance.accounting.manage', 'accounting', 70),
('delivery', 'الشحن والتوصيل', 'Delivery', '/admin/delivery', 'local_shipping', 'logistics', 'delivery.shipments.manage', 'delivery', 80),
('support', 'الدعم والشكاوى', 'Support', '/support/center', 'support_agent', 'support', 'support.tickets.manage', 'support', 90),
('reviews', 'التقييمات والسمعة', 'Reviews', '/support/reviews', 'star_rate', 'trust', 'manage_reviews', 'reviews', 100),
('loyalty', 'الولاء والمحفظة', 'Loyalty & Wallet', '/admin/coupons', 'loyalty', 'loyalty', 'coupons.manage', 'wallet_loyalty', 110),
('audit', 'سجل التدقيق', 'Audit Logs', '/admin/audit-logs', 'history', 'security', 'view_audit_logs', 'audit', 120),
('settings', 'إعدادات النظام', 'System Settings', '/admin/settings', 'settings', 'system', 'manage_settings', 'admin', 130),
('hardening', 'تقسية النظام', 'System Hardening', '/admin/system-hardening', 'security', 'system', 'manage_settings', 'admin', 140);

INSERT IGNORE INTO `translation_entries` (`translation_key`, `locale`, `value`, `namespace`, `platform`, `is_system`, `created_at`, `updated_at`) VALUES
('admin.system_hardening', 'ar', 'تقسية النظام', 'admin', 'GLOBAL', TRUE, NOW(3), NOW(3)),
('admin.system_hardening', 'en', 'System Hardening', 'admin', 'GLOBAL', TRUE, NOW(3), NOW(3)),
('admin.analytics_snapshots', 'ar', 'لقطات التحليلات', 'admin', 'GLOBAL', TRUE, NOW(3), NOW(3)),
('admin.analytics_snapshots', 'en', 'Analytics Snapshots', 'admin', 'GLOBAL', TRUE, NOW(3), NOW(3)),
('admin.module_registry', 'ar', 'سجل وحدات النظام', 'admin', 'GLOBAL', TRUE, NOW(3), NOW(3)),
('admin.module_registry', 'en', 'System Module Registry', 'admin', 'GLOBAL', TRUE, NOW(3), NOW(3));
