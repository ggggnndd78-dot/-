CREATE TABLE IF NOT EXISTS `audit_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `actor_user_id` INT NULL,
  `action` VARCHAR(100) NOT NULL,
  `entity_type` VARCHAR(80) NULL,
  `entity_id` VARCHAR(120) NULL,
  `method` VARCHAR(12) NULL,
  `path` VARCHAR(500) NULL,
  `ip_address` VARCHAR(80) NULL,
  `user_agent` VARCHAR(500) NULL,
  `request_id` VARCHAR(120) NULL,
  `locale` VARCHAR(10) NULL,
  `metadata_json` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `audit_logs_publicId_key` (`publicId`),
  KEY `audit_logs_actor_user_id_created_at_idx` (`actor_user_id`, `created_at`),
  KEY `audit_logs_action_created_at_idx` (`action`, `created_at`),
  KEY `audit_logs_entity_type_entity_id_idx` (`entity_type`, `entity_id`),
  KEY `audit_logs_request_id_idx` (`request_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `system_settings` (
  `key` VARCHAR(120) NOT NULL,
  `value_json` JSON NULL,
  `value_text` TEXT NULL,
  `description` VARCHAR(500) NULL,
  `is_public` BOOLEAN NOT NULL DEFAULT false,
  `updated_by_user_id` INT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`key`),
  KEY `system_settings_is_public_idx` (`is_public`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE OR REPLACE VIEW `view_admin_dashboard_summary` AS
SELECT
  (SELECT COUNT(*) FROM `iam_users`) AS `total_users`,
  (SELECT COUNT(*) FROM `org_organizations`) AS `total_organizations`,
  (SELECT COUNT(*) FROM `org_organizations` WHERE `status` = 'PENDING_REVIEW') AS `pending_organizations`,
  (SELECT COUNT(*) FROM `catalog_products`) AS `total_products`,
  (SELECT COUNT(*) FROM `market_listings` WHERE `status` = 'ACTIVE') AS `active_listings`,
  (SELECT COUNT(*) FROM `commerce_orders`) AS `total_orders`,
  (SELECT COUNT(*) FROM `commerce_orders` WHERE `status` IN ('PENDING','CONFIRMED','PREPARING','OUT_FOR_DELIVERY')) AS `open_orders`,
  (SELECT COALESCE(SUM(`total_amount`),0) FROM `commerce_orders` WHERE `payment_status` = 'PAID') AS `paid_revenue`,
  (SELECT COUNT(*) FROM `support_tickets` WHERE `status` IN ('OPEN','WAITING_CUSTOMER','WAITING_SUPPORT','ESCALATED')) AS `open_tickets`,
  (SELECT COUNT(*) FROM `support_complaints` WHERE `status` IN ('SUBMITTED','UNDER_REVIEW')) AS `open_complaints`;

CREATE OR REPLACE VIEW `view_order_status_metrics` AS
SELECT
  `status`,
  COUNT(*) AS `orders_count`,
  COALESCE(SUM(`total_amount`),0) AS `total_amount`,
  COALESCE(SUM(`discount_amount`),0) AS `discount_amount`,
  COALESCE(SUM(`delivery_fee`),0) AS `delivery_fee`
FROM `commerce_orders`
GROUP BY `status`;

CREATE OR REPLACE VIEW `view_revenue_daily` AS
SELECT
  DATE(`created_at`) AS `revenue_date`,
  COUNT(*) AS `orders_count`,
  COALESCE(SUM(CASE WHEN `payment_status` = 'PAID' THEN `total_amount` ELSE 0 END),0) AS `paid_revenue`,
  COALESCE(SUM(`total_amount`),0) AS `gross_order_value`
FROM `commerce_orders`
GROUP BY DATE(`created_at`);

CREATE OR REPLACE VIEW `view_support_status_metrics` AS
SELECT 'ticket' AS `record_type`, `status`, COUNT(*) AS `records_count`
FROM `support_tickets`
GROUP BY `status`
UNION ALL
SELECT 'complaint' AS `record_type`, `status`, COUNT(*) AS `records_count`
FROM `support_complaints`
GROUP BY `status`;

CREATE OR REPLACE VIEW `view_merchant_performance` AS
SELECT
  o.`id` AS `organization_id`,
  o.`display_name` AS `merchant_name`,
  COUNT(DISTINCT l.`id`) AS `listings_count`,
  COUNT(DISTINCT co.`id`) AS `orders_count`,
  COALESCE(SUM(co.`total_amount`),0) AS `gross_sales`,
  COALESCE(AVG(mr.`rating`),0) AS `avg_rating`
FROM `org_organizations` o
LEFT JOIN `market_listings` l ON l.`organization_id` = o.`id`
LEFT JOIN `commerce_orders` co ON co.`organization_id` = o.`id`
LEFT JOIN `review_merchant_reviews` mr ON mr.`organization_id` = o.`id` AND mr.`status` = 'PUBLISHED'
WHERE o.`organization_type` = 'MERCHANT'
GROUP BY o.`id`, o.`display_name`;
