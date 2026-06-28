
-- Phase 9: Wallet, loyalty, coupons and retention systems.
CREATE TABLE IF NOT EXISTS `wallet_accounts` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `owner_type` ENUM('USER','ORGANIZATION') NOT NULL,
  `user_id` INTEGER NULL,
  `organization_id` INTEGER NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `balance` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `locked_balance` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `status` ENUM('ACTIVE','SUSPENDED','CLOSED') NOT NULL DEFAULT 'ACTIVE',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `wallet_accounts_publicId_key`(`publicId`),
  INDEX `wallet_accounts_user_id_currency_idx`(`user_id`, `currency`),
  INDEX `wallet_accounts_organization_id_currency_idx`(`organization_id`, `currency`),
  INDEX `wallet_accounts_owner_type_status_idx`(`owner_type`, `status`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `wallet_ledger_entries` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `wallet_account_id` INTEGER NOT NULL,
  `direction` ENUM('CREDIT','DEBIT') NOT NULL,
  `entry_type` ENUM('TOP_UP','ORDER_PAYMENT','SERVICE_ORDER_PAYMENT','REFUND','LOYALTY_REDEMPTION','ADMIN_ADJUSTMENT','CAMPAIGN_REWARD') NOT NULL,
  `amount` DECIMAL(14,2) NOT NULL,
  `balance_before` DECIMAL(14,2) NOT NULL,
  `balance_after` DECIMAL(14,2) NOT NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `order_id` INTEGER NULL,
  `service_order_id` INTEGER NULL,
  `reference_type` VARCHAR(60) NULL,
  `reference_id` VARCHAR(120) NULL,
  `description` VARCHAR(500) NULL,
  `metadata_json` JSON NULL,
  `created_by_user_id` INTEGER NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `wallet_ledger_entries_publicId_key`(`publicId`),
  INDEX `wallet_ledger_entries_wallet_account_id_created_at_idx`(`wallet_account_id`, `created_at`),
  INDEX `wallet_ledger_entries_order_id_idx`(`order_id`),
  INDEX `wallet_ledger_entries_service_order_id_idx`(`service_order_id`),
  INDEX `wallet_ledger_entries_entry_type_created_at_idx`(`entry_type`, `created_at`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `loyalty_accounts` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `user_id` INTEGER NOT NULL,
  `points_balance` INTEGER NOT NULL DEFAULT 0,
  `lifetime_earned` INTEGER NOT NULL DEFAULT 0,
  `lifetime_redeemed` INTEGER NOT NULL DEFAULT 0,
  `tier` ENUM('BRONZE','SILVER','GOLD','PLATINUM') NOT NULL DEFAULT 'BRONZE',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `loyalty_accounts_publicId_key`(`publicId`),
  UNIQUE INDEX `loyalty_accounts_user_id_key`(`user_id`),
  INDEX `loyalty_accounts_tier_idx`(`tier`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `loyalty_point_transactions` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `account_id` INTEGER NOT NULL,
  `user_id` INTEGER NOT NULL,
  `direction` ENUM('EARN','REDEEM','ADJUST','EXPIRE') NOT NULL,
  `source` ENUM('ORDER_REWARD','SERVICE_REWARD','COUPON_REWARD','WALLET_REDEMPTION','ADMIN_ADJUSTMENT','CAMPAIGN_REWARD') NOT NULL,
  `points` INTEGER NOT NULL,
  `balance_after` INTEGER NOT NULL,
  `order_id` INTEGER NULL,
  `service_order_id` INTEGER NULL,
  `reference_type` VARCHAR(60) NULL,
  `reference_id` VARCHAR(120) NULL,
  `description` VARCHAR(500) NULL,
  `expires_at` DATETIME(3) NULL,
  `created_by_user_id` INTEGER NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `loyalty_point_transactions_publicId_key`(`publicId`),
  INDEX `loyalty_point_transactions_account_id_created_at_idx`(`account_id`, `created_at`),
  INDEX `loyalty_point_transactions_user_id_created_at_idx`(`user_id`, `created_at`),
  INDEX `loyalty_point_transactions_order_id_idx`(`order_id`),
  INDEX `loyalty_point_transactions_service_order_id_idx`(`service_order_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `loyalty_coupons` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `code` VARCHAR(40) NOT NULL,
  `title_ar` VARCHAR(160) NOT NULL,
  `title_en` VARCHAR(160) NULL,
  `description` VARCHAR(500) NULL,
  `discount_type` ENUM('PERCENTAGE','FIXED_AMOUNT') NOT NULL,
  `discount_value` DECIMAL(12,2) NOT NULL,
  `max_discount_amount` DECIMAL(12,2) NULL,
  `min_order_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `scope` ENUM('MARKETPLACE','WORKSHOP','ALL') NOT NULL DEFAULT 'ALL',
  `usage_limit` INTEGER NULL,
  `per_user_limit` INTEGER NOT NULL DEFAULT 1,
  `used_count` INTEGER NOT NULL DEFAULT 0,
  `starts_at` DATETIME(3) NULL,
  `ends_at` DATETIME(3) NULL,
  `status` ENUM('DRAFT','ACTIVE','PAUSED','EXPIRED') NOT NULL DEFAULT 'DRAFT',
  `created_by_user_id` INTEGER NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `loyalty_coupons_publicId_key`(`publicId`),
  UNIQUE INDEX `loyalty_coupons_code_key`(`code`),
  INDEX `loyalty_coupons_status_scope_idx`(`status`, `scope`),
  INDEX `loyalty_coupons_starts_at_ends_at_idx`(`starts_at`, `ends_at`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `loyalty_coupon_redemptions` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `coupon_id` INTEGER NOT NULL,
  `user_id` INTEGER NOT NULL,
  `order_id` INTEGER NULL,
  `service_order_id` INTEGER NULL,
  `discount_amount` DECIMAL(12,2) NOT NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `redeemed_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `metadata_json` JSON NULL,
  UNIQUE INDEX `loyalty_coupon_redemptions_publicId_key`(`publicId`),
  INDEX `loyalty_coupon_redemptions_coupon_id_user_id_idx`(`coupon_id`, `user_id`),
  INDEX `loyalty_coupon_redemptions_order_id_idx`(`order_id`),
  INDEX `loyalty_coupon_redemptions_service_order_id_idx`(`service_order_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `retention_campaigns` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `title` VARCHAR(180) NOT NULL,
  `channel` ENUM('IN_APP','FCM') NOT NULL DEFAULT 'IN_APP',
  `audience_type` ENUM('ALL_CUSTOMERS','BRONZE_CUSTOMERS','SILVER_CUSTOMERS','GOLD_CUSTOMERS','PLATINUM_CUSTOMERS','INACTIVE_CUSTOMERS') NOT NULL DEFAULT 'ALL_CUSTOMERS',
  `status` ENUM('DRAFT','SCHEDULED','SENT','PAUSED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
  `message_title` VARCHAR(160) NOT NULL,
  `message_body` VARCHAR(500) NOT NULL,
  `coupon_id` INTEGER NULL,
  `starts_at` DATETIME(3) NULL,
  `ends_at` DATETIME(3) NULL,
  `sent_at` DATETIME(3) NULL,
  `created_by_user_id` INTEGER NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `retention_campaigns_publicId_key`(`publicId`),
  INDEX `retention_campaigns_status_audience_type_idx`(`status`, `audience_type`),
  INDEX `retention_campaigns_starts_at_ends_at_idx`(`starts_at`, `ends_at`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `retention_campaign_events` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `campaign_id` INTEGER NOT NULL,
  `user_id` INTEGER NOT NULL,
  `status` ENUM('QUEUED','SENT','FAILED','OPENED') NOT NULL DEFAULT 'QUEUED',
  `delivered_at` DATETIME(3) NULL,
  `opened_at` DATETIME(3) NULL,
  `failed_reason` VARCHAR(500) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `retention_campaign_events_campaign_id_user_id_key`(`campaign_id`, `user_id`),
  INDEX `retention_campaign_events_user_id_status_idx`(`user_id`, `status`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `wallet_accounts` ADD CONSTRAINT `wallet_accounts_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `wallet_accounts` ADD CONSTRAINT `wallet_accounts_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `wallet_ledger_entries` ADD CONSTRAINT `wallet_ledger_entries_wallet_account_id_fkey` FOREIGN KEY (`wallet_account_id`) REFERENCES `wallet_accounts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `wallet_ledger_entries` ADD CONSTRAINT `wallet_ledger_entries_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `wallet_ledger_entries` ADD CONSTRAINT `wallet_ledger_entries_service_order_id_fkey` FOREIGN KEY (`service_order_id`) REFERENCES `workshop_service_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `wallet_ledger_entries` ADD CONSTRAINT `wallet_ledger_entries_created_by_user_id_fkey` FOREIGN KEY (`created_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `loyalty_accounts` ADD CONSTRAINT `loyalty_accounts_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `loyalty_point_transactions` ADD CONSTRAINT `loyalty_point_transactions_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `loyalty_point_transactions` ADD CONSTRAINT `loyalty_point_transactions_account_id_fkey` FOREIGN KEY (`account_id`) REFERENCES `loyalty_accounts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `loyalty_point_transactions` ADD CONSTRAINT `loyalty_point_transactions_created_by_user_id_fkey` FOREIGN KEY (`created_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `loyalty_point_transactions` ADD CONSTRAINT `loyalty_point_transactions_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `loyalty_point_transactions` ADD CONSTRAINT `loyalty_point_transactions_service_order_id_fkey` FOREIGN KEY (`service_order_id`) REFERENCES `workshop_service_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `loyalty_coupons` ADD CONSTRAINT `loyalty_coupons_created_by_user_id_fkey` FOREIGN KEY (`created_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `loyalty_coupon_redemptions` ADD CONSTRAINT `loyalty_coupon_redemptions_coupon_id_fkey` FOREIGN KEY (`coupon_id`) REFERENCES `loyalty_coupons`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `loyalty_coupon_redemptions` ADD CONSTRAINT `loyalty_coupon_redemptions_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `loyalty_coupon_redemptions` ADD CONSTRAINT `loyalty_coupon_redemptions_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `loyalty_coupon_redemptions` ADD CONSTRAINT `loyalty_coupon_redemptions_service_order_id_fkey` FOREIGN KEY (`service_order_id`) REFERENCES `workshop_service_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `retention_campaigns` ADD CONSTRAINT `retention_campaigns_coupon_id_fkey` FOREIGN KEY (`coupon_id`) REFERENCES `loyalty_coupons`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `retention_campaigns` ADD CONSTRAINT `retention_campaigns_created_by_user_id_fkey` FOREIGN KEY (`created_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `retention_campaign_events` ADD CONSTRAINT `retention_campaign_events_campaign_id_fkey` FOREIGN KEY (`campaign_id`) REFERENCES `retention_campaigns`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `retention_campaign_events` ADD CONSTRAINT `retention_campaign_events_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
