-- Phase 19 - Reviews and reputation management.
-- Adds service reviews, review media, replies, moderation history, and reputation summaries.

ALTER TABLE `review_product_reviews`
  ADD UNIQUE KEY `review_product_once_per_order_item` (`user_id`, `product_id`, `order_id`);

ALTER TABLE `review_merchant_reviews`
  ADD UNIQUE KEY `review_merchant_once_per_order` (`user_id`, `organization_id`, `order_id`);

ALTER TABLE `review_workshop_reviews`
  ADD UNIQUE KEY `review_workshop_once_per_service_order` (`user_id`, `organization_id`, `service_order_id`);

CREATE TABLE `review_service_reviews` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `user_id` INT NOT NULL,
  `organization_id` INT NOT NULL,
  `workshop_service_id` INT NULL,
  `service_order_id` INT NOT NULL,
  `rating` INT NOT NULL,
  `title` VARCHAR(160) NULL,
  `body` TEXT NULL,
  `status` ENUM('PENDING','PUBLISHED','HIDDEN','REJECTED') NOT NULL DEFAULT 'PUBLISHED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `review_service_reviews_publicId_key` (`publicId`),
  UNIQUE KEY `review_service_once_per_order` (`user_id`, `service_order_id`),
  KEY `review_service_reviews_org_status_idx` (`organization_id`, `status`),
  KEY `review_service_reviews_service_status_idx` (`workshop_service_id`, `status`),
  KEY `review_service_reviews_user_idx` (`user_id`),
  CONSTRAINT `review_service_reviews_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_service_reviews_org_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_service_reviews_workshop_service_id_fkey` FOREIGN KEY (`workshop_service_id`) REFERENCES `workshop_services`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `review_service_reviews_service_order_id_fkey` FOREIGN KEY (`service_order_id`) REFERENCES `workshop_service_orders`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE `review_media` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `target_type` ENUM('PRODUCT','MERCHANT','WORKSHOP','SERVICE') NOT NULL,
  `product_review_id` INT NULL,
  `merchant_review_id` INT NULL,
  `workshop_review_id` INT NULL,
  `service_review_id` INT NULL,
  `uploaded_by_user_id` INT NULL,
  `media_url` VARCHAR(500) NOT NULL,
  `media_type` VARCHAR(30) NOT NULL DEFAULT 'image',
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `review_media_publicId_key` (`publicId`),
  KEY `review_media_target_created_idx` (`target_type`, `created_at`),
  KEY `review_media_product_review_id_idx` (`product_review_id`),
  KEY `review_media_merchant_review_id_idx` (`merchant_review_id`),
  KEY `review_media_workshop_review_id_idx` (`workshop_review_id`),
  KEY `review_media_service_review_id_idx` (`service_review_id`),
  CONSTRAINT `review_media_product_review_id_fkey` FOREIGN KEY (`product_review_id`) REFERENCES `review_product_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_media_merchant_review_id_fkey` FOREIGN KEY (`merchant_review_id`) REFERENCES `review_merchant_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_media_workshop_review_id_fkey` FOREIGN KEY (`workshop_review_id`) REFERENCES `review_workshop_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_media_service_review_id_fkey` FOREIGN KEY (`service_review_id`) REFERENCES `review_service_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_media_uploaded_by_user_id_fkey` FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE `review_replies` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `target_type` ENUM('PRODUCT','MERCHANT','WORKSHOP','SERVICE') NOT NULL,
  `product_review_id` INT NULL,
  `merchant_review_id` INT NULL,
  `workshop_review_id` INT NULL,
  `service_review_id` INT NULL,
  `organization_id` INT NOT NULL,
  `author_user_id` INT NOT NULL,
  `body` TEXT NOT NULL,
  `status` ENUM('PUBLISHED','HIDDEN') NOT NULL DEFAULT 'PUBLISHED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `review_replies_publicId_key` (`publicId`),
  KEY `review_replies_org_created_idx` (`organization_id`, `created_at`),
  KEY `review_replies_target_type_idx` (`target_type`),
  KEY `review_replies_product_review_id_idx` (`product_review_id`),
  KEY `review_replies_merchant_review_id_idx` (`merchant_review_id`),
  KEY `review_replies_workshop_review_id_idx` (`workshop_review_id`),
  KEY `review_replies_service_review_id_idx` (`service_review_id`),
  CONSTRAINT `review_replies_product_review_id_fkey` FOREIGN KEY (`product_review_id`) REFERENCES `review_product_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_replies_merchant_review_id_fkey` FOREIGN KEY (`merchant_review_id`) REFERENCES `review_merchant_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_replies_workshop_review_id_fkey` FOREIGN KEY (`workshop_review_id`) REFERENCES `review_workshop_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_replies_service_review_id_fkey` FOREIGN KEY (`service_review_id`) REFERENCES `review_service_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_replies_org_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_replies_author_user_id_fkey` FOREIGN KEY (`author_user_id`) REFERENCES `iam_users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE `review_moderation_actions` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `target_type` ENUM('PRODUCT','MERCHANT','WORKSHOP','SERVICE') NOT NULL,
  `product_review_id` INT NULL,
  `merchant_review_id` INT NULL,
  `workshop_review_id` INT NULL,
  `service_review_id` INT NULL,
  `actor_user_id` INT NOT NULL,
  `action_type` ENUM('REPORTED','HIDDEN','RESTORED','REJECTED') NOT NULL,
  `reason` VARCHAR(500) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `review_moderation_actions_publicId_key` (`publicId`),
  KEY `review_moderation_target_created_idx` (`target_type`, `created_at`),
  KEY `review_moderation_actor_created_idx` (`actor_user_id`, `created_at`),
  KEY `review_moderation_product_review_id_idx` (`product_review_id`),
  KEY `review_moderation_merchant_review_id_idx` (`merchant_review_id`),
  KEY `review_moderation_workshop_review_id_idx` (`workshop_review_id`),
  KEY `review_moderation_service_review_id_idx` (`service_review_id`),
  CONSTRAINT `review_moderation_product_review_id_fkey` FOREIGN KEY (`product_review_id`) REFERENCES `review_product_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_moderation_merchant_review_id_fkey` FOREIGN KEY (`merchant_review_id`) REFERENCES `review_merchant_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_moderation_workshop_review_id_fkey` FOREIGN KEY (`workshop_review_id`) REFERENCES `review_workshop_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_moderation_service_review_id_fkey` FOREIGN KEY (`service_review_id`) REFERENCES `review_service_reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `review_moderation_actor_user_id_fkey` FOREIGN KEY (`actor_user_id`) REFERENCES `iam_users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE `review_reputation_summaries` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `target_type` ENUM('PRODUCT','MERCHANT','WORKSHOP','SERVICE') NOT NULL,
  `target_id` INT NOT NULL,
  `organization_id` INT NULL,
  `average_rating` DECIMAL(4,2) NOT NULL DEFAULT 0,
  `total_reviews` INT NOT NULL DEFAULT 0,
  `rating_1_count` INT NOT NULL DEFAULT 0,
  `rating_2_count` INT NOT NULL DEFAULT 0,
  `rating_3_count` INT NOT NULL DEFAULT 0,
  `rating_4_count` INT NOT NULL DEFAULT 0,
  `rating_5_count` INT NOT NULL DEFAULT 0,
  `reputation_score` DECIMAL(6,2) NOT NULL DEFAULT 0,
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `review_reputation_summaries_publicId_key` (`publicId`),
  UNIQUE KEY `review_reputation_target_key` (`target_type`, `target_id`),
  KEY `review_reputation_org_type_idx` (`organization_id`, `target_type`),
  KEY `review_reputation_score_idx` (`target_type`, `reputation_score`),
  CONSTRAINT `review_reputation_org_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
);

INSERT INTO `iam_permissions` (`code`, `name`, `module_code`, `created_at`)
VALUES
  ('reviews.create', 'Create verified reviews', 'reviews', CURRENT_TIMESTAMP(3)),
  ('reviews.reply.manage', 'Manage organization review replies', 'reviews', CURRENT_TIMESTAMP(3)),
  ('reviews.moderate', 'Moderate reviews', 'reviews', CURRENT_TIMESTAMP(3)),
  ('reviews.analytics.view', 'View review and reputation analytics', 'reviews', CURRENT_TIMESTAMP(3))
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `module_code` = VALUES(`module_code`);

-- Minimal role grants for review permissions, idempotent for existing deployments.
INSERT IGNORE INTO `iam_role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `iam_roles` r JOIN `iam_permissions` p ON p.code = 'reviews.create'
WHERE r.code IN ('customer', 'admin_super');

INSERT IGNORE INTO `iam_role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `iam_roles` r JOIN `iam_permissions` p ON p.code = 'reviews.reply.manage'
WHERE r.code IN ('merchant_owner', 'merchant_employee', 'workshop_owner', 'workshop_employee', 'admin_super');

INSERT IGNORE INTO `iam_role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `iam_roles` r JOIN `iam_permissions` p ON p.code = 'reviews.moderate'
WHERE r.code IN ('support_agent', 'admin_operations', 'admin_super');

INSERT IGNORE INTO `iam_role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `iam_roles` r JOIN `iam_permissions` p ON p.code = 'reviews.analytics.view'
WHERE r.code IN ('support_agent', 'merchant_owner', 'workshop_owner', 'admin_operations', 'admin_super');
