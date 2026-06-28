CREATE TABLE IF NOT EXISTS `addresses` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `public_id` VARCHAR(191) NOT NULL,
  `user_id` INTEGER NOT NULL,
  `label` VARCHAR(60) NOT NULL,
  `recipient_name` VARCHAR(120) NOT NULL,
  `phone` VARCHAR(20) NOT NULL,
  `city_id` INTEGER NOT NULL,
  `district_id` INTEGER NULL,
  `area_id` INTEGER NULL,
  `address_line_1` VARCHAR(255) NOT NULL,
  `address_line_2` VARCHAR(255) NULL,
  `latitude` DECIMAL(10,7) NULL,
  `longitude` DECIMAL(10,7) NULL,
  `is_default` BOOLEAN NOT NULL DEFAULT false,
  `is_active` BOOLEAN NOT NULL DEFAULT true,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `addresses_public_id_key`(`public_id`),
  INDEX `addresses_user_id_idx`(`user_id`),
  INDEX `addresses_city_id_idx`(`city_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `delivery_zones` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `public_id` VARCHAR(191) NOT NULL,
  `city_id` INTEGER NOT NULL,
  `district_id` INTEGER NULL,
  `name_ar` VARCHAR(120) NOT NULL,
  `name_en` VARCHAR(120) NULL,
  `code` VARCHAR(40) NULL,
  `delivery_fee` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `estimated_min_days` INTEGER NULL,
  `estimated_max_days` INTEGER NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT true,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `delivery_zones_public_id_key`(`public_id`),
  INDEX `delivery_zones_city_id_idx`(`city_id`),
  INDEX `delivery_zones_district_id_idx`(`district_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `city_delivery_fees` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `city_id` INTEGER NOT NULL,
  `delivery_fee` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `is_delivery_available` BOOLEAN NOT NULL DEFAULT true,
  `estimated_min_days` INTEGER NULL,
  `estimated_max_days` INTEGER NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `city_delivery_fees_city_id_key`(`city_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `addresses`
  ADD CONSTRAINT `addresses_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `addresses_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `addresses_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `geo_districts`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `addresses_area_id_fkey` FOREIGN KEY (`area_id`) REFERENCES `geo_areas`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `delivery_zones`
  ADD CONSTRAINT `delivery_zones_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `delivery_zones_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `geo_districts`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `city_delivery_fees`
  ADD CONSTRAINT `city_delivery_fees_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
