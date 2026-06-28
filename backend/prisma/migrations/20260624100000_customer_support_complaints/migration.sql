-- Phase 18: Customer support, complaint management, help center, FAQs and WhatsApp support.
-- Expands the existing support foundation without replacing legacy tables.

ALTER TABLE `support_tickets`
  MODIFY COLUMN `status` ENUM('OPEN','IN_PROGRESS','WAITING_SUPPORT','WAITING_CUSTOMER','RESOLVED','CLOSED','ESCALATED') NOT NULL DEFAULT 'OPEN';

ALTER TABLE `support_ticket_messages`
  MODIFY COLUMN `message_type` ENUM('CUSTOMER_MESSAGE','SUPPORT_MESSAGE','MERCHANT_MESSAGE','SYSTEM_NOTE','INTERNAL_NOTE') NOT NULL DEFAULT 'CUSTOMER_MESSAGE';

ALTER TABLE `support_complaints`
  MODIFY COLUMN `status` ENUM('SUBMITTED','UNDER_REVIEW','INVESTIGATION','WAITING_CUSTOMER','WAITING_PROVIDER','RESOLVED','REJECTED','CLOSED') NOT NULL DEFAULT 'SUBMITTED';

ALTER TABLE `support_tickets`
  ADD COLUMN `payment_id` INTEGER NULL,
  ADD COLUMN `shipment_id` INTEGER NULL;

ALTER TABLE `support_complaints`
  ADD COLUMN `payment_id` INTEGER NULL,
  ADD COLUMN `shipment_id` INTEGER NULL;

CREATE INDEX `support_tickets_payment_id_status_idx` ON `support_tickets`(`payment_id`, `status`);
CREATE INDEX `support_tickets_shipment_id_status_idx` ON `support_tickets`(`shipment_id`, `status`);
CREATE INDEX `support_complaints_payment_id_status_idx` ON `support_complaints`(`payment_id`, `status`);
CREATE INDEX `support_complaints_shipment_id_status_idx` ON `support_complaints`(`shipment_id`, `status`);

ALTER TABLE `support_tickets` ADD CONSTRAINT `support_tickets_payment_id_fkey` FOREIGN KEY (`payment_id`) REFERENCES `payment_transactions`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_tickets` ADD CONSTRAINT `support_tickets_shipment_id_fkey` FOREIGN KEY (`shipment_id`) REFERENCES `delivery_shipments`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_complaints` ADD CONSTRAINT `support_complaints_payment_id_fkey` FOREIGN KEY (`payment_id`) REFERENCES `payment_transactions`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_complaints` ADD CONSTRAINT `support_complaints_shipment_id_fkey` FOREIGN KEY (`shipment_id`) REFERENCES `delivery_shipments`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS `support_ticket_attachments` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `ticket_id` INTEGER NOT NULL,
  `message_id` INTEGER NULL,
  `uploaded_by_user_id` INTEGER NULL,
  `scope` ENUM('TICKET','MESSAGE','COMPLAINT') NOT NULL DEFAULT 'MESSAGE',
  `file_url` VARCHAR(500) NOT NULL,
  `file_name` VARCHAR(255) NULL,
  `file_type` VARCHAR(80) NULL,
  `file_size_bytes` INTEGER NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `support_ticket_attachments_publicId_key`(`publicId`),
  INDEX `support_ticket_attachments_ticket_id_created_at_idx`(`ticket_id`, `created_at`),
  INDEX `support_ticket_attachments_message_id_idx`(`message_id`),
  INDEX `support_ticket_attachments_uploaded_by_user_id_created_at_idx`(`uploaded_by_user_id`, `created_at`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `support_ticket_attachments` ADD CONSTRAINT `support_ticket_attachments_ticket_id_fkey` FOREIGN KEY (`ticket_id`) REFERENCES `support_tickets`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `support_ticket_attachments` ADD CONSTRAINT `support_ticket_attachments_message_id_fkey` FOREIGN KEY (`message_id`) REFERENCES `support_ticket_messages`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_ticket_attachments` ADD CONSTRAINT `support_ticket_attachments_uploaded_by_user_id_fkey` FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS `help_center_categories` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `code` VARCHAR(80) NOT NULL,
  `title_ar` VARCHAR(160) NOT NULL,
  `title_en` VARCHAR(160) NULL,
  `description_ar` VARCHAR(500) NULL,
  `description_en` VARCHAR(500) NULL,
  `icon` VARCHAR(80) NULL,
  `status` ENUM('DRAFT','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'PUBLISHED',
  `sort_order` INTEGER NOT NULL DEFAULT 0,
  `created_by_user_id` INTEGER NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `help_center_categories_publicId_key`(`publicId`),
  UNIQUE INDEX `help_center_categories_code_key`(`code`),
  INDEX `help_center_categories_status_sort_order_idx`(`status`, `sort_order`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `help_center_articles` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `category_id` INTEGER NULL,
  `slug` VARCHAR(180) NOT NULL,
  `title_ar` VARCHAR(220) NOT NULL,
  `title_en` VARCHAR(220) NULL,
  `summary_ar` VARCHAR(500) NULL,
  `summary_en` VARCHAR(500) NULL,
  `body_ar` TEXT NOT NULL,
  `body_en` TEXT NULL,
  `status` ENUM('DRAFT','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
  `is_featured` BOOLEAN NOT NULL DEFAULT false,
  `view_count` INTEGER NOT NULL DEFAULT 0,
  `sort_order` INTEGER NOT NULL DEFAULT 0,
  `created_by_user_id` INTEGER NULL,
  `updated_by_user_id` INTEGER NULL,
  `published_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `help_center_articles_publicId_key`(`publicId`),
  UNIQUE INDEX `help_center_articles_slug_key`(`slug`),
  INDEX `help_center_articles_category_id_status_idx`(`category_id`, `status`),
  INDEX `help_center_articles_status_is_featured_sort_order_idx`(`status`, `is_featured`, `sort_order`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `faqs` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `category_id` INTEGER NULL,
  `question_ar` VARCHAR(300) NOT NULL,
  `question_en` VARCHAR(300) NULL,
  `answer_ar` TEXT NOT NULL,
  `answer_en` TEXT NULL,
  `status` ENUM('DRAFT','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'PUBLISHED',
  `sort_order` INTEGER NOT NULL DEFAULT 0,
  `view_count` INTEGER NOT NULL DEFAULT 0,
  `created_by_user_id` INTEGER NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `faqs_publicId_key`(`publicId`),
  INDEX `faqs_category_id_status_idx`(`category_id`, `status`),
  INDEX `faqs_status_sort_order_idx`(`status`, `sort_order`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `whatsapp_support_links` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `department` ENUM('SALES','SUPPORT','COMPLAINTS','TECHNICAL','FINANCE','GENERAL') NOT NULL DEFAULT 'GENERAL',
  `title_ar` VARCHAR(160) NOT NULL,
  `title_en` VARCHAR(160) NULL,
  `phone_e164` VARCHAR(30) NOT NULL,
  `message_template` VARCHAR(500) NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT true,
  `sort_order` INTEGER NOT NULL DEFAULT 0,
  `created_by_user_id` INTEGER NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `whatsapp_support_links_publicId_key`(`publicId`),
  INDEX `whatsapp_support_links_department_is_active_idx`(`department`, `is_active`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `help_center_categories` ADD CONSTRAINT `help_center_categories_created_by_user_id_fkey` FOREIGN KEY (`created_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `help_center_articles` ADD CONSTRAINT `help_center_articles_category_id_fkey` FOREIGN KEY (`category_id`) REFERENCES `help_center_categories`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `help_center_articles` ADD CONSTRAINT `help_center_articles_created_by_user_id_fkey` FOREIGN KEY (`created_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `help_center_articles` ADD CONSTRAINT `help_center_articles_updated_by_user_id_fkey` FOREIGN KEY (`updated_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `faqs` ADD CONSTRAINT `faqs_category_id_fkey` FOREIGN KEY (`category_id`) REFERENCES `help_center_categories`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `faqs` ADD CONSTRAINT `faqs_created_by_user_id_fkey` FOREIGN KEY (`created_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `whatsapp_support_links` ADD CONSTRAINT `whatsapp_support_links_created_by_user_id_fkey` FOREIGN KEY (`created_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

INSERT INTO `help_center_categories` (`publicId`, `code`, `title_ar`, `title_en`, `description_ar`, `status`, `sort_order`, `updated_at`)
VALUES
  (UUID(), 'orders', 'الطلبات', 'Orders', 'مساعدة حول إنشاء ومتابعة الطلبات.', 'PUBLISHED', 10, CURRENT_TIMESTAMP(3)),
  (UUID(), 'payments', 'الدفع والمالية', 'Payments', 'مساعدة حول الدفع والتحويلات وإثبات الدفع.', 'PUBLISHED', 20, CURRENT_TIMESTAMP(3)),
  (UUID(), 'delivery', 'التوصيل والشحن', 'Delivery', 'مساعدة حول الشحن والتتبع والتسليم.', 'PUBLISHED', 30, CURRENT_TIMESTAMP(3)),
  (UUID(), 'workshops', 'خدمات الورش', 'Workshops', 'مساعدة حول الحجوزات وخدمات الورش.', 'PUBLISHED', 40, CURRENT_TIMESTAMP(3))
ON DUPLICATE KEY UPDATE `title_ar` = VALUES(`title_ar`), `status` = VALUES(`status`), `updated_at` = CURRENT_TIMESTAMP(3);

INSERT INTO `faqs` (`publicId`, `category_id`, `question_ar`, `answer_ar`, `status`, `sort_order`, `updated_at`)
SELECT UUID(), c.id, 'كيف أفتح تذكرة دعم؟', 'افتح مركز الدعم ثم اختر إنشاء تذكرة واكتب تفاصيل المشكلة. يمكنك ربط التذكرة بطلب أو دفع أو شحنة عند توفرها.', 'PUBLISHED', 10, CURRENT_TIMESTAMP(3)
FROM `help_center_categories` c WHERE c.code = 'orders'
ON DUPLICATE KEY UPDATE `updated_at` = CURRENT_TIMESTAMP(3);

INSERT INTO `whatsapp_support_links` (`publicId`, `department`, `title_ar`, `title_en`, `phone_e164`, `message_template`, `is_active`, `sort_order`, `updated_at`)
VALUES
  (UUID(), 'SUPPORT', 'دعم العملاء', 'Customer Support', '+967000000000', 'مرحباً، أحتاج مساعدة في منصة غيارك.', true, 10, CURRENT_TIMESTAMP(3)),
  (UUID(), 'COMPLAINTS', 'الشكاوى', 'Complaints', '+967000000000', 'مرحباً، أريد تقديم شكوى في منصة غيارك.', true, 20, CURRENT_TIMESTAMP(3));
