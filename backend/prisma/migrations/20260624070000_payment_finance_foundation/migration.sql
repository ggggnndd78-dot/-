-- Ghiyarak Phase 15: Real Payments & Financial Foundation

ALTER TABLE `commerce_orders`
  MODIFY `payment_method` ENUM('CASH_ON_DELIVERY','CASH_ON_PICKUP','BANK_TRANSFER','WALLET','LOCAL_WALLET','PAYMENT_GATEWAY') NOT NULL DEFAULT 'CASH_ON_PICKUP',
  MODIFY `payment_status` ENUM('UNPAID','PENDING_COD','WAITING_PROOF','PENDING_REVIEW','UNDER_REVIEW','PAID','CONFIRMED','FAILED','REJECTED','CANCELLED','EXPIRED','REFUNDED','PARTIALLY_REFUNDED') NOT NULL DEFAULT 'UNPAID';

ALTER TABLE `payment_transactions`
  MODIFY `provider` ENUM('MANUAL','CASH','BANK_TRANSFER','WALLET','LOCAL_WALLET','EXTERNAL','PAYMENT_GATEWAY') NOT NULL DEFAULT 'MANUAL',
  MODIFY `payment_method` ENUM('CASH_ON_DELIVERY','CASH_ON_PICKUP','BANK_TRANSFER','WALLET','LOCAL_WALLET','PAYMENT_GATEWAY') NULL,
  MODIFY `status` ENUM('INITIATED','PENDING_COD','WAITING_PROOF','PENDING_REVIEW','UNDER_REVIEW','AUTHORIZED','CONFIRMED','PAID','REJECTED','FAILED','CANCELLED','EXPIRED','REFUNDED','PARTIALLY_REFUNDED') NOT NULL DEFAULT 'INITIATED';

ALTER TABLE `commerce_invoices`
  MODIFY `order_id` INTEGER NULL,
  ADD COLUMN `invoice_type` ENUM('ORDER','SERVICE_ORDER','MANUAL') NOT NULL DEFAULT 'ORDER' AFTER `public_id`,
  ADD COLUMN `service_order_id` INTEGER NULL AFTER `order_id`,
  ADD COLUMN `customer_id` INTEGER NULL AFTER `service_order_id`,
  ADD COLUMN `status` ENUM('DRAFT','ISSUED','PAID','CANCELLED','REFUNDED') NOT NULL DEFAULT 'ISSUED' AFTER `currency`,
  ADD COLUMN `paid_at` DATETIME(3) NULL AFTER `issued_at`,
  ADD COLUMN `cancelled_at` DATETIME(3) NULL AFTER `paid_at`;

CREATE INDEX `commerce_invoices_service_order_id_idx` ON `commerce_invoices`(`service_order_id`);
CREATE INDEX `commerce_invoices_customer_status_idx` ON `commerce_invoices`(`customer_id`, `status`);
CREATE INDEX `commerce_invoices_status_issued_at_idx` ON `commerce_invoices`(`status`, `issued_at`);

CREATE TABLE `payment_methods` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `code` VARCHAR(60) NOT NULL,
  `name_ar` VARCHAR(140) NOT NULL,
  `name_en` VARCHAR(140) NULL,
  `kind` ENUM('COD','BANK_TRANSFER','LOCAL_WALLET','PAYMENT_GATEWAY') NOT NULL,
  `provider_code` VARCHAR(80) NULL,
  `instructions_ar` TEXT NULL,
  `instructions_en` TEXT NULL,
  `requires_proof` BOOLEAN NOT NULL DEFAULT false,
  `requires_webhook` BOOLEAN NOT NULL DEFAULT false,
  `allow_for_orders` BOOLEAN NOT NULL DEFAULT true,
  `allow_for_services` BOOLEAN NOT NULL DEFAULT true,
  `status` ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  `sort_order` INTEGER NOT NULL DEFAULT 0,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `payment_methods_publicId_key`(`publicId`),
  UNIQUE INDEX `payment_methods_code_key`(`code`),
  INDEX `payment_methods_kind_status_idx`(`kind`, `status`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `payment_transactions`
  ADD COLUMN `invoice_id` INTEGER NULL AFTER `publicId`,
  ADD COLUMN `payment_method_config_id` INTEGER NULL AFTER `organization_id`,
  ADD COLUMN `idempotency_key` VARCHAR(120) NULL AFTER `external_reference`,
  ADD COLUMN `reviewed_at` DATETIME(3) NULL AFTER `failed_at`,
  ADD COLUMN `expires_at` DATETIME(3) NULL AFTER `reviewed_at`,
  ADD COLUMN `approved_by_user_id` INTEGER NULL AFTER `expires_at`;

CREATE UNIQUE INDEX `payment_transactions_idempotency_key_key` ON `payment_transactions`(`idempotency_key`);
CREATE INDEX `payment_transactions_invoice_status_idx` ON `payment_transactions`(`invoice_id`, `status`);
CREATE INDEX `payment_transactions_provider_external_idx` ON `payment_transactions`(`provider`, `external_reference`);
CREATE INDEX `payment_transactions_method_config_idx` ON `payment_transactions`(`payment_method_config_id`);
CREATE INDEX `payment_transactions_approved_by_idx` ON `payment_transactions`(`approved_by_user_id`);

CREATE TABLE `payment_attempts` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `payment_id` INTEGER NOT NULL,
  `attempt_number` INTEGER NOT NULL DEFAULT 1,
  `provider` ENUM('MANUAL','CASH','BANK_TRANSFER','WALLET','LOCAL_WALLET','EXTERNAL','PAYMENT_GATEWAY') NOT NULL DEFAULT 'MANUAL',
  `status` ENUM('CREATED','SENT_TO_PROVIDER','PENDING','SUCCEEDED','FAILED','CANCELLED') NOT NULL DEFAULT 'CREATED',
  `provider_reference` VARCHAR(140) NULL,
  `request_payload` JSON NULL,
  `response_payload` JSON NULL,
  `error_message` VARCHAR(500) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `payment_attempts_publicId_key`(`publicId`),
  UNIQUE INDEX `payment_attempts_payment_attempt_uq`(`payment_id`, `attempt_number`),
  INDEX `payment_attempts_provider_reference_idx`(`provider`, `provider_reference`),
  INDEX `payment_attempts_status_created_idx`(`status`, `created_at`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `payment_proofs` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `payment_id` INTEGER NOT NULL,
  `uploaded_by_user_id` INTEGER NOT NULL,
  `file_url` VARCHAR(500) NOT NULL,
  `file_name` VARCHAR(255) NULL,
  `file_type` VARCHAR(80) NULL,
  `amount` DECIMAL(12,2) NULL,
  `reference_number` VARCHAR(120) NULL,
  `status` ENUM('PENDING_REVIEW','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING_REVIEW',
  `reviewed_by_user_id` INTEGER NULL,
  `review_notes` VARCHAR(500) NULL,
  `reviewed_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `payment_proofs_publicId_key`(`publicId`),
  INDEX `payment_proofs_payment_status_idx`(`payment_id`, `status`),
  INDEX `payment_proofs_uploaded_created_idx`(`uploaded_by_user_id`, `created_at`),
  INDEX `payment_proofs_status_created_idx`(`status`, `created_at`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `payment_webhooks` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `provider_code` VARCHAR(80) NOT NULL,
  `event_type` VARCHAR(100) NOT NULL,
  `provider_reference` VARCHAR(140) NULL,
  `idempotency_key` VARCHAR(180) NOT NULL,
  `signature` VARCHAR(500) NULL,
  `payload` JSON NOT NULL,
  `is_verified` BOOLEAN NOT NULL DEFAULT false,
  `status` ENUM('RECEIVED','VERIFIED','REJECTED','PROCESSED','FAILED') NOT NULL DEFAULT 'RECEIVED',
  `error_message` VARCHAR(500) NULL,
  `processed_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `payment_webhooks_publicId_key`(`publicId`),
  UNIQUE INDEX `payment_webhooks_idempotency_key_key`(`idempotency_key`),
  INDEX `payment_webhooks_provider_reference_idx`(`provider_code`, `provider_reference`),
  INDEX `payment_webhooks_status_created_idx`(`status`, `created_at`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `refunds` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `refund_number` VARCHAR(60) NOT NULL,
  `payment_id` INTEGER NULL,
  `invoice_id` INTEGER NULL,
  `order_id` INTEGER NULL,
  `service_order_id` INTEGER NULL,
  `amount` DECIMAL(12,2) NOT NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `reason` VARCHAR(500) NOT NULL,
  `status` ENUM('REQUESTED','APPROVED','REJECTED','PROCESSING','REFUNDED','FAILED') NOT NULL DEFAULT 'REQUESTED',
  `requested_by_user_id` INTEGER NOT NULL,
  `approved_by_user_id` INTEGER NULL,
  `provider_reference` VARCHAR(140) NULL,
  `processed_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `refunds_publicId_key`(`publicId`),
  UNIQUE INDEX `refunds_refund_number_key`(`refund_number`),
  INDEX `refunds_payment_status_idx`(`payment_id`, `status`),
  INDEX `refunds_order_status_idx`(`order_id`, `status`),
  INDEX `refunds_service_order_status_idx`(`service_order_id`, `status`),
  INDEX `refunds_status_created_idx`(`status`, `created_at`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `settlements` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `settlement_number` VARCHAR(60) NOT NULL,
  `organization_id` INTEGER NOT NULL,
  `amount` DECIMAL(12,2) NOT NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `period_start` DATE NOT NULL,
  `period_end` DATE NOT NULL,
  `status` ENUM('PENDING','APPROVED','PAID','CANCELLED') NOT NULL DEFAULT 'PENDING',
  `notes` VARCHAR(500) NULL,
  `approved_by_user_id` INTEGER NULL,
  `paid_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `settlements_publicId_key`(`publicId`),
  UNIQUE INDEX `settlements_settlement_number_key`(`settlement_number`),
  INDEX `settlements_org_status_idx`(`organization_id`, `status`),
  INDEX `settlements_status_period_idx`(`status`, `period_start`, `period_end`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `commerce_invoices` ADD CONSTRAINT `commerce_invoices_service_order_fk` FOREIGN KEY (`service_order_id`) REFERENCES `workshop_service_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `commerce_invoices` ADD CONSTRAINT `commerce_invoices_customer_fk` FOREIGN KEY (`customer_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `payment_transactions` ADD CONSTRAINT `payment_transactions_invoice_fk` FOREIGN KEY (`invoice_id`) REFERENCES `commerce_invoices`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `payment_transactions` ADD CONSTRAINT `payment_transactions_method_config_fk` FOREIGN KEY (`payment_method_config_id`) REFERENCES `payment_methods`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `payment_transactions` ADD CONSTRAINT `payment_transactions_approved_by_fk` FOREIGN KEY (`approved_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `payment_attempts` ADD CONSTRAINT `payment_attempts_payment_fk` FOREIGN KEY (`payment_id`) REFERENCES `payment_transactions`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `payment_proofs` ADD CONSTRAINT `payment_proofs_payment_fk` FOREIGN KEY (`payment_id`) REFERENCES `payment_transactions`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `payment_proofs` ADD CONSTRAINT `payment_proofs_uploaded_by_fk` FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `payment_proofs` ADD CONSTRAINT `payment_proofs_reviewed_by_fk` FOREIGN KEY (`reviewed_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `refunds` ADD CONSTRAINT `refunds_payment_fk` FOREIGN KEY (`payment_id`) REFERENCES `payment_transactions`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `refunds` ADD CONSTRAINT `refunds_invoice_fk` FOREIGN KEY (`invoice_id`) REFERENCES `commerce_invoices`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `refunds` ADD CONSTRAINT `refunds_order_fk` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `refunds` ADD CONSTRAINT `refunds_service_order_fk` FOREIGN KEY (`service_order_id`) REFERENCES `workshop_service_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `refunds` ADD CONSTRAINT `refunds_requested_by_fk` FOREIGN KEY (`requested_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `refunds` ADD CONSTRAINT `refunds_approved_by_fk` FOREIGN KEY (`approved_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `settlements` ADD CONSTRAINT `settlements_org_fk` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `settlements` ADD CONSTRAINT `settlements_approved_by_fk` FOREIGN KEY (`approved_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

INSERT INTO `payment_methods` (`publicId`, `code`, `name_ar`, `name_en`, `kind`, `provider_code`, `instructions_ar`, `requires_proof`, `requires_webhook`, `sort_order`, `created_at`, `updated_at`) VALUES
(CONCAT('pm_', REPLACE(UUID(), '-', '')), 'CASH_ON_PICKUP', 'الدفع عند الاستلام من الفرع', 'Cash on Pickup', 'COD', 'CASH', 'يدفع العميل عند استلام الطلب من الفرع.', false, false, 1, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(CONCAT('pm_', REPLACE(UUID(), '-', '')), 'CASH_ON_DELIVERY', 'الدفع عند التوصيل', 'Cash on Delivery', 'COD', 'CASH', 'يتم تأكيد الدفع بعد التسليم الناجح.', false, false, 2, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(CONCAT('pm_', REPLACE(UUID(), '-', '')), 'BANK_TRANSFER', 'تحويل بنكي', 'Bank Transfer', 'BANK_TRANSFER', 'BANK_TRANSFER', 'حوّل المبلغ إلى الحساب البنكي ثم ارفع إثبات التحويل للمراجعة المالية.', true, false, 3, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(CONCAT('pm_', REPLACE(UUID(), '-', '')), 'LOCAL_WALLET', 'محفظة محلية', 'Local Wallet', 'LOCAL_WALLET', 'LOCAL_WALLET', 'استخدم محفظة محلية وارفع مرجع العملية للمراجعة.', true, false, 4, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(CONCAT('pm_', REPLACE(UUID(), '-', '')), 'PAYMENT_GATEWAY', 'بوابة دفع مستقبلية', 'Payment Gateway', 'PAYMENT_GATEWAY', 'PAYMENT_GATEWAY', 'جاهزة للربط مع بوابات دفع مستقبلية عبر Webhook موثق.', false, true, 5, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3))
ON DUPLICATE KEY UPDATE `name_ar` = VALUES(`name_ar`), `name_en` = VALUES(`name_en`), `kind` = VALUES(`kind`), `provider_code` = VALUES(`provider_code`), `instructions_ar` = VALUES(`instructions_ar`), `requires_proof` = VALUES(`requires_proof`), `requires_webhook` = VALUES(`requires_webhook`), `sort_order` = VALUES(`sort_order`), `updated_at` = CURRENT_TIMESTAMP(3);
