
-- Phase 8: Support, complaints and review systems.
CREATE TABLE IF NOT EXISTS `support_tickets` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `ticket_number` VARCHAR(40) NOT NULL,
  `requester_user_id` INTEGER NOT NULL,
  `assigned_user_id` INTEGER NULL,
  `organization_id` INTEGER NULL,
  `order_id` INTEGER NULL,
  `service_order_id` INTEGER NULL,
  `category` ENUM('GENERAL','ORDER','PAYMENT','DELIVERY','WORKSHOP','MERCHANT','TECHNICAL','COMPLAINT') NOT NULL DEFAULT 'GENERAL',
  `status` ENUM('OPEN','WAITING_SUPPORT','WAITING_CUSTOMER','RESOLVED','CLOSED','ESCALATED') NOT NULL DEFAULT 'OPEN',
  `priority` ENUM('LOW','NORMAL','HIGH','URGENT') NOT NULL DEFAULT 'NORMAL',
  `subject` VARCHAR(180) NOT NULL,
  `description` TEXT NOT NULL,
  `last_message_at` DATETIME(3) NULL,
  `resolved_at` DATETIME(3) NULL,
  `closed_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `support_tickets_publicId_key`(`publicId`),
  UNIQUE INDEX `support_tickets_ticket_number_key`(`ticket_number`),
  INDEX `support_tickets_requester_user_id_status_idx`(`requester_user_id`, `status`),
  INDEX `support_tickets_organization_id_status_idx`(`organization_id`, `status`),
  INDEX `support_tickets_assigned_user_id_status_idx`(`assigned_user_id`, `status`),
  INDEX `support_tickets_category_status_idx`(`category`, `status`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `support_ticket_messages` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `ticket_id` INTEGER NOT NULL,
  `author_user_id` INTEGER NULL,
  `message_type` ENUM('CUSTOMER_MESSAGE','SUPPORT_MESSAGE','MERCHANT_MESSAGE','SYSTEM_NOTE') NOT NULL DEFAULT 'CUSTOMER_MESSAGE',
  `body` TEXT NOT NULL,
  `attachments` JSON NULL,
  `is_internal` BOOLEAN NOT NULL DEFAULT false,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `support_ticket_messages_publicId_key`(`publicId`),
  INDEX `support_ticket_messages_ticket_id_created_at_idx`(`ticket_id`, `created_at`),
  INDEX `support_ticket_messages_author_user_id_idx`(`author_user_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `support_complaints` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `complaint_number` VARCHAR(40) NOT NULL,
  `requester_user_id` INTEGER NOT NULL,
  `organization_id` INTEGER NULL,
  `order_id` INTEGER NULL,
  `service_order_id` INTEGER NULL,
  `ticket_id` INTEGER NULL,
  `status` ENUM('SUBMITTED','UNDER_REVIEW','WAITING_CUSTOMER','WAITING_PROVIDER','RESOLVED','REJECTED','CLOSED') NOT NULL DEFAULT 'SUBMITTED',
  `severity` ENUM('LOW','NORMAL','HIGH','CRITICAL') NOT NULL DEFAULT 'NORMAL',
  `subject` VARCHAR(180) NOT NULL,
  `description` TEXT NOT NULL,
  `resolution_note` TEXT NULL,
  `resolved_by_user_id` INTEGER NULL,
  `resolved_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `support_complaints_publicId_key`(`publicId`),
  UNIQUE INDEX `support_complaints_complaint_number_key`(`complaint_number`),
  UNIQUE INDEX `support_complaints_ticket_id_key`(`ticket_id`),
  INDEX `support_complaints_requester_user_id_status_idx`(`requester_user_id`, `status`),
  INDEX `support_complaints_organization_id_status_idx`(`organization_id`, `status`),
  INDEX `support_complaints_severity_status_idx`(`severity`, `status`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `review_product_reviews` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `user_id` INTEGER NOT NULL,
  `product_id` INTEGER NOT NULL,
  `order_id` INTEGER NULL,
  `rating` INTEGER NOT NULL,
  `title` VARCHAR(160) NULL,
  `body` TEXT NULL,
  `status` ENUM('PENDING','PUBLISHED','HIDDEN','REJECTED') NOT NULL DEFAULT 'PUBLISHED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `review_product_reviews_publicId_key`(`publicId`),
  INDEX `review_product_reviews_user_id_product_id_order_id_idx`(`user_id`, `product_id`, `order_id`),
  INDEX `review_product_reviews_product_id_status_idx`(`product_id`, `status`),
  INDEX `review_product_reviews_user_id_idx`(`user_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `review_merchant_reviews` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `user_id` INTEGER NOT NULL,
  `organization_id` INTEGER NOT NULL,
  `order_id` INTEGER NULL,
  `rating` INTEGER NOT NULL,
  `title` VARCHAR(160) NULL,
  `body` TEXT NULL,
  `status` ENUM('PENDING','PUBLISHED','HIDDEN','REJECTED') NOT NULL DEFAULT 'PUBLISHED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `review_merchant_reviews_publicId_key`(`publicId`),
  INDEX `review_merchant_reviews_user_id_organization_id_order_id_idx`(`user_id`, `organization_id`, `order_id`),
  INDEX `review_merchant_reviews_organization_id_status_idx`(`organization_id`, `status`),
  INDEX `review_merchant_reviews_user_id_idx`(`user_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `review_workshop_reviews` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `user_id` INTEGER NOT NULL,
  `organization_id` INTEGER NOT NULL,
  `service_order_id` INTEGER NULL,
  `rating` INTEGER NOT NULL,
  `title` VARCHAR(160) NULL,
  `body` TEXT NULL,
  `status` ENUM('PENDING','PUBLISHED','HIDDEN','REJECTED') NOT NULL DEFAULT 'PUBLISHED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `review_workshop_reviews_publicId_key`(`publicId`),
  INDEX `idx_wshop_reviews_user_org_so`(`user_id`, `organization_id`, `service_order_id`),
  INDEX `review_workshop_reviews_organization_id_status_idx`(`organization_id`, `status`),
  INDEX `review_workshop_reviews_user_id_idx`(`user_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `support_tickets` ADD CONSTRAINT `support_tickets_requester_user_id_fkey` FOREIGN KEY (`requester_user_id`) REFERENCES `iam_users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `support_tickets` ADD CONSTRAINT `support_tickets_assigned_user_id_fkey` FOREIGN KEY (`assigned_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_tickets` ADD CONSTRAINT `support_tickets_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_tickets` ADD CONSTRAINT `support_tickets_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_tickets` ADD CONSTRAINT `support_tickets_service_order_id_fkey` FOREIGN KEY (`service_order_id`) REFERENCES `workshop_service_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_ticket_messages` ADD CONSTRAINT `support_ticket_messages_ticket_id_fkey` FOREIGN KEY (`ticket_id`) REFERENCES `support_tickets`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `support_ticket_messages` ADD CONSTRAINT `support_ticket_messages_author_user_id_fkey` FOREIGN KEY (`author_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_complaints` ADD CONSTRAINT `support_complaints_requester_user_id_fkey` FOREIGN KEY (`requester_user_id`) REFERENCES `iam_users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `support_complaints` ADD CONSTRAINT `support_complaints_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_complaints` ADD CONSTRAINT `support_complaints_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_complaints` ADD CONSTRAINT `support_complaints_service_order_id_fkey` FOREIGN KEY (`service_order_id`) REFERENCES `workshop_service_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_complaints` ADD CONSTRAINT `support_complaints_ticket_id_fkey` FOREIGN KEY (`ticket_id`) REFERENCES `support_tickets`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `support_complaints` ADD CONSTRAINT `support_complaints_resolved_by_user_id_fkey` FOREIGN KEY (`resolved_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `review_product_reviews` ADD CONSTRAINT `review_product_reviews_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `review_product_reviews` ADD CONSTRAINT `review_product_reviews_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `catalog_products`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `review_product_reviews` ADD CONSTRAINT `review_product_reviews_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `review_merchant_reviews` ADD CONSTRAINT `review_merchant_reviews_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `review_merchant_reviews` ADD CONSTRAINT `review_merchant_reviews_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `review_merchant_reviews` ADD CONSTRAINT `review_merchant_reviews_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `review_workshop_reviews` ADD CONSTRAINT `review_workshop_reviews_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `review_workshop_reviews` ADD CONSTRAINT `review_workshop_reviews_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `review_workshop_reviews` ADD CONSTRAINT `review_workshop_reviews_service_order_id_fkey` FOREIGN KEY (`service_order_id`) REFERENCES `workshop_service_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
