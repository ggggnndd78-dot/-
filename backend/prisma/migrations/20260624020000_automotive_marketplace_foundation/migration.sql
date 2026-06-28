-- Automotive catalog and marketplace foundation.
-- Keeps the existing production-safe schema and adds missing marketplace support tables.

ALTER TABLE `market_listings`
  ADD COLUMN `quality_type` varchar(30) NOT NULL DEFAULT 'AFTERMARKET';

CREATE TABLE IF NOT EXISTS `catalog_product_specs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `spec_key` varchar(120) NOT NULL,
  `spec_value` varchar(255) NOT NULL,
  `sort_order` int NOT NULL DEFAULT 0,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `catalog_product_specs_product_id_idx` (`product_id`),
  CONSTRAINT `catalog_product_specs_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `catalog_products`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `listing_inventory` (
  `id` int NOT NULL AUTO_INCREMENT,
  `listing_id` int NOT NULL,
  `available_quantity` int NOT NULL DEFAULT 0,
  `reserved_quantity` int NOT NULL DEFAULT 0,
  `low_stock_threshold` int NULL,
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `listing_inventory_listing_id_key` (`listing_id`),
  CONSTRAINT `listing_inventory_listing_id_fkey` FOREIGN KEY (`listing_id`) REFERENCES `market_listings`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `listing_prices` (
  `id` int NOT NULL AUTO_INCREMENT,
  `listing_id` int NOT NULL,
  `unit_price` decimal(12,2) NOT NULL,
  `sale_price` decimal(12,2) NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'YER',
  `starts_at` datetime(3) NULL,
  `ends_at` datetime(3) NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `listing_prices_listing_id_is_active_idx` (`listing_id`, `is_active`),
  CONSTRAINT `listing_prices_listing_id_fkey` FOREIGN KEY (`listing_id`) REFERENCES `market_listings`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `stock_movements` (
  `id` int NOT NULL AUTO_INCREMENT,
  `listing_id` int NOT NULL,
  `movement_type` varchar(40) NOT NULL,
  `quantity` int NOT NULL,
  `quantity_before` int NULL,
  `quantity_after` int NULL,
  `reason` varchar(255) NULL,
  `reference_type` varchar(80) NULL,
  `reference_id` varchar(120) NULL,
  `created_by_user_id` int NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `stock_movements_listing_id_created_at_idx` (`listing_id`, `created_at`),
  CONSTRAINT `stock_movements_listing_id_fkey` FOREIGN KEY (`listing_id`) REFERENCES `market_listings`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Professional compatibility aliases for the current schema naming.
-- These views are read-only convenience names for reports and DB inspection.
CREATE OR REPLACE VIEW `vehicle_brands` AS SELECT * FROM `vehicle_makes`;
CREATE OR REPLACE VIEW `user_vehicles` AS SELECT * FROM `vehicle_customer_vehicles`;
CREATE OR REPLACE VIEW `part_compatibilities` AS SELECT * FROM `catalog_product_compatibilities`;
CREATE OR REPLACE VIEW `categories` AS SELECT * FROM `catalog_categories`;
CREATE OR REPLACE VIEW `product_brands` AS SELECT * FROM `catalog_part_brands`;
CREATE OR REPLACE VIEW `products` AS SELECT * FROM `catalog_products`;
