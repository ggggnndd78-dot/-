-- Phase 7 - Notifications and email/push delivery logs.
-- Minimal production-safe additions only for this phase.

CREATE TABLE IF NOT EXISTS `notification_templates` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `event_key` VARCHAR(80) NOT NULL,
  `channel` VARCHAR(20) NOT NULL,
  `title_ar` VARCHAR(160) NOT NULL,
  `body_ar` VARCHAR(500) NOT NULL,
  `title_en` VARCHAR(160) NULL,
  `body_en` VARCHAR(500) NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT true,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `notification_templates_publicId_key` (`publicId`),
  UNIQUE KEY `notification_templates_event_key_channel_key` (`event_key`, `channel`),
  KEY `notification_templates_event_active_idx` (`event_key`, `is_active`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `email_notification_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `user_id` INT NULL,
  `to_email` VARCHAR(255) NOT NULL,
  `subject` VARCHAR(180) NOT NULL,
  `body` TEXT NOT NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'SENT',
  `provider` VARCHAR(40) NOT NULL DEFAULT 'console',
  `error` TEXT NULL,
  `metadata_json` JSON NULL,
  `sent_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email_notification_logs_publicId_key` (`publicId`),
  KEY `email_notification_logs_user_created_idx` (`user_id`, `created_at`),
  KEY `email_notification_logs_status_created_idx` (`status`, `created_at`),
  CONSTRAINT `email_notification_logs_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `push_notification_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `user_id` INT NULL,
  `fcm_token` VARCHAR(512) NULL,
  `title` VARCHAR(160) NOT NULL,
  `body` VARCHAR(500) NOT NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'SENT',
  `provider` VARCHAR(40) NOT NULL DEFAULT 'firebase',
  `error` TEXT NULL,
  `metadata_json` JSON NULL,
  `sent_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `push_notification_logs_publicId_key` (`publicId`),
  KEY `push_notification_logs_user_created_idx` (`user_id`, `created_at`),
  KEY `push_notification_logs_status_created_idx` (`status`, `created_at`),
  CONSTRAINT `push_notification_logs_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT IGNORE INTO `notification_templates` (`publicId`, `event_key`, `channel`, `title_ar`, `body_ar`, `title_en`, `body_en`) VALUES
('phase7-template-verification-approved-inapp', 'VerificationApproved', 'IN_APP', 'تم اعتماد المنشأة', 'تم اعتماد طلبك. يمكنك الآن استخدام لوحة التحكم حسب صلاحياتك.', 'Verification approved', 'Your verification request has been approved.'),
('phase7-template-verification-rejected-inapp', 'VerificationRejected', 'IN_APP', 'تم رفض طلب الاعتماد', 'تم رفض طلب الاعتماد. راجع السبب وأعد الإرسال بعد التصحيح.', 'Verification rejected', 'Your verification request was rejected.'),
('phase7-template-documents-required-inapp', 'VerificationDocumentsRequired', 'IN_APP', 'مطلوب مستندات إضافية', 'يحتاج طلب الاعتماد إلى مستندات أو بيانات إضافية.', 'Additional documents required', 'Your verification request needs additional documents.'),
('phase7-template-verification-suspended-inapp', 'VerificationSuspended', 'IN_APP', 'تم تعليق المنشأة', 'تم تعليق المنشأة. تواصل مع الإدارة لمعرفة التفاصيل.', 'Organization suspended', 'Your organization has been suspended.');
