-- Ghiyarak Phase 4 Marketplace Core
-- Catalog, listings, cart, checkout, orders, and merchant operations.

CREATE TABLE IF NOT EXISTS `catalog_categories` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `parent_id` INT NULL,
  `name_ar` VARCHAR(160) NOT NULL,
  `name_en` VARCHAR(160) NULL,
  `slug` VARCHAR(180) NOT NULL,
  `description` TEXT NULL,
  `icon_url` VARCHAR(500) NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `is_active` BOOLEAN NOT NULL DEFAULT true,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `catalog_categories_publicId_key` (`publicId`),
  UNIQUE KEY `catalog_categories_slug_key` (`slug`),
  KEY `catalog_categories_parent_id_idx` (`parent_id`),
  CONSTRAINT `catalog_categories_parent_id_fkey` FOREIGN KEY (`parent_id`) REFERENCES `catalog_categories`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `catalog_part_brands` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `name_ar` VARCHAR(160) NOT NULL,
  `name_en` VARCHAR(160) NULL,
  `slug` VARCHAR(180) NOT NULL,
  `country_code` VARCHAR(3) NULL,
  `logo_url` VARCHAR(500) NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT true,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `catalog_part_brands_publicId_key` (`publicId`),
  UNIQUE KEY `catalog_part_brands_slug_key` (`slug`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `catalog_products` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `category_id` INT NOT NULL,
  `part_brand_id` INT NULL,
  `name_ar` VARCHAR(220) NOT NULL,
  `name_en` VARCHAR(220) NULL,
  `slug` VARCHAR(240) NOT NULL,
  `sku` VARCHAR(80) NULL,
  `oem_number` VARCHAR(100) NULL,
  `aftermarket_code` VARCHAR(100) NULL,
  `description` TEXT NULL,
  `specifications` JSON NULL,
  `is_universal` BOOLEAN NOT NULL DEFAULT false,
  `is_active` BOOLEAN NOT NULL DEFAULT true,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `catalog_products_publicId_key` (`publicId`),
  UNIQUE KEY `catalog_products_slug_key` (`slug`),
  UNIQUE KEY `catalog_products_sku_key` (`sku`),
  KEY `catalog_products_category_id_idx` (`category_id`),
  KEY `catalog_products_part_brand_id_idx` (`part_brand_id`),
  KEY `catalog_products_name_ar_idx` (`name_ar`),
  CONSTRAINT `catalog_products_category_id_fkey` FOREIGN KEY (`category_id`) REFERENCES `catalog_categories`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `catalog_products_part_brand_id_fkey` FOREIGN KEY (`part_brand_id`) REFERENCES `catalog_part_brands`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `catalog_product_media` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `product_id` INT NOT NULL,
  `media_url` VARCHAR(500) NOT NULL,
  `media_type` VARCHAR(30) NOT NULL DEFAULT 'image',
  `alt_text` VARCHAR(160) NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `catalog_product_media_product_id_idx` (`product_id`),
  CONSTRAINT `catalog_product_media_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `catalog_products`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `catalog_product_compatibilities` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `product_id` INT NOT NULL,
  `make_id` INT NOT NULL,
  `model_id` INT NULL,
  `variant_id` INT NULL,
  `year_from` INT NULL,
  `year_to` INT NULL,
  `engine_code` VARCHAR(80) NULL,
  `notes` VARCHAR(255) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `catalog_product_compatibilities_product_id_idx` (`product_id`),
  KEY `catalog_product_compatibilities_make_model_variant_idx` (`make_id`,`model_id`,`variant_id`),
  CONSTRAINT `catalog_product_compatibilities_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `catalog_products`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `catalog_product_compatibilities_make_id_fkey` FOREIGN KEY (`make_id`) REFERENCES `vehicle_makes`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `catalog_product_compatibilities_model_id_fkey` FOREIGN KEY (`model_id`) REFERENCES `vehicle_models`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `catalog_product_compatibilities_variant_id_fkey` FOREIGN KEY (`variant_id`) REFERENCES `vehicle_variants`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `market_listings` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `product_id` INT NOT NULL,
  `organization_id` INT NOT NULL,
  `branch_id` INT NULL,
  `city_id` INT NULL,
  `created_by_user_id` INT NOT NULL,
  `title` VARCHAR(240) NOT NULL,
  `description` TEXT NULL,
  `condition` ENUM('NEW','USED','REFURBISHED') NOT NULL DEFAULT 'NEW',
  `status` ENUM('DRAFT','ACTIVE','PAUSED','OUT_OF_STOCK','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
  `approval_status` ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'APPROVED',
  `unit_price` DECIMAL(12,2) NOT NULL,
  `sale_price` DECIMAL(12,2) NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `available_quantity` INT NOT NULL DEFAULT 0,
  `reserved_quantity` INT NOT NULL DEFAULT 0,
  `min_order_quantity` INT NOT NULL DEFAULT 1,
  `warranty_days` INT NULL,
  `supports_pickup` BOOLEAN NOT NULL DEFAULT true,
  `supports_delivery` BOOLEAN NOT NULL DEFAULT false,
  `published_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `market_listings_publicId_key` (`publicId`),
  KEY `market_listings_product_id_idx` (`product_id`),
  KEY `market_listings_organization_id_idx` (`organization_id`),
  KEY `market_listings_status_approval_idx` (`status`,`approval_status`),
  KEY `market_listings_city_id_idx` (`city_id`),
  CONSTRAINT `market_listings_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `catalog_products`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `market_listings_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `market_listings_branch_id_fkey` FOREIGN KEY (`branch_id`) REFERENCES `org_organization_branches`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `market_listings_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `market_listings_created_by_user_id_fkey` FOREIGN KEY (`created_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `commerce_carts` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `user_id` INT NOT NULL,
  `status` ENUM('ACTIVE','CHECKED_OUT','ABANDONED') NOT NULL DEFAULT 'ACTIVE',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `commerce_carts_publicId_key` (`publicId`),
  KEY `commerce_carts_user_status_idx` (`user_id`,`status`),
  CONSTRAINT `commerce_carts_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `commerce_cart_items` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `cart_id` INT NOT NULL,
  `listing_id` INT NOT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `commerce_cart_items_cart_listing_key` (`cart_id`,`listing_id`),
  CONSTRAINT `commerce_cart_items_cart_id_fkey` FOREIGN KEY (`cart_id`) REFERENCES `commerce_carts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `commerce_cart_items_listing_id_fkey` FOREIGN KEY (`listing_id`) REFERENCES `market_listings`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `commerce_orders` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `order_number` VARCHAR(40) NOT NULL,
  `user_id` INT NOT NULL,
  `organization_id` INT NOT NULL,
  `branch_id` INT NULL,
  `city_id` INT NULL,
  `status` ENUM('PENDING','CONFIRMED','PREPARING','READY_FOR_PICKUP','OUT_FOR_DELIVERY','COMPLETED','CANCELLED','REJECTED') NOT NULL DEFAULT 'PENDING',
  `fulfillment_method` ENUM('PICKUP','DELIVERY') NOT NULL DEFAULT 'PICKUP',
  `payment_method` ENUM('CASH_ON_DELIVERY','CASH_ON_PICKUP','BANK_TRANSFER','WALLET') NOT NULL DEFAULT 'CASH_ON_PICKUP',
  `payment_status` ENUM('UNPAID','PENDING_REVIEW','PAID','FAILED','REFUNDED') NOT NULL DEFAULT 'UNPAID',
  `subtotal_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `delivery_fee` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `discount_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `customer_note` VARCHAR(500) NULL,
  `cancellation_reason` VARCHAR(500) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `commerce_orders_publicId_key` (`publicId`),
  UNIQUE KEY `commerce_orders_order_number_key` (`order_number`),
  KEY `commerce_orders_user_id_idx` (`user_id`),
  KEY `commerce_orders_organization_status_idx` (`organization_id`,`status`),
  KEY `commerce_orders_order_number_idx` (`order_number`),
  CONSTRAINT `commerce_orders_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `commerce_orders_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `commerce_orders_branch_id_fkey` FOREIGN KEY (`branch_id`) REFERENCES `org_organization_branches`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `commerce_orders_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `commerce_order_items` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `order_id` INT NOT NULL,
  `listing_id` INT NOT NULL,
  `product_name` VARCHAR(240) NOT NULL,
  `unit_price` DECIMAL(12,2) NOT NULL,
  `quantity` INT NOT NULL,
  `total_amount` DECIMAL(12,2) NOT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  CONSTRAINT `commerce_order_items_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `commerce_order_items_listing_id_fkey` FOREIGN KEY (`listing_id`) REFERENCES `market_listings`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `commerce_order_status_history` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `order_id` INT NOT NULL,
  `status` ENUM('PENDING','CONFIRMED','PREPARING','READY_FOR_PICKUP','OUT_FOR_DELIVERY','COMPLETED','CANCELLED','REJECTED') NOT NULL,
  `changed_by_user_id` INT NULL,
  `note` VARCHAR(500) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `commerce_order_status_history_order_id_idx` (`order_id`),
  CONSTRAINT `commerce_order_status_history_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `commerce_order_status_history_changed_by_user_id_fkey` FOREIGN KEY (`changed_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT IGNORE INTO `catalog_categories` (`publicId`, `name_ar`, `name_en`, `slug`, `sort_order`) VALUES
('seed-cat-filters', 'فلاتر', 'Filters', 'filters', 1),
('seed-cat-oils', 'زيوت وسوائل', 'Oils and Fluids', 'oils-fluids', 2),
('seed-cat-brakes', 'فرامل', 'Brakes', 'brakes', 3),
('seed-cat-batteries', 'بطاريات', 'Batteries', 'batteries', 4),
('seed-cat-engine', 'قطع المحرك', 'Engine Parts', 'engine-parts', 5);

INSERT IGNORE INTO `catalog_part_brands` (`publicId`, `name_ar`, `name_en`, `slug`, `country_code`) VALUES
('seed-brand-toyota-genuine', 'تويوتا أصلي', 'Toyota Genuine', 'toyota-genuine', 'JPN'),
('seed-brand-acdelco', 'ACDelco', 'ACDelco', 'acdelco', 'USA'),
('seed-brand-bosch', 'Bosch', 'Bosch', 'bosch', 'DEU'),
('seed-brand-mobil', 'Mobil', 'Mobil', 'mobil', 'USA');
