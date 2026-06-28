-- Ghiyarak Phase 17 Delivery & Logistics Management
-- Adds driver management, local shipping companies, delivery fee rules, shipment assignment, and stronger tracking references.

ALTER TABLE `delivery_methods`
  ADD COLUMN `method_kind` ENUM('STORE_PICKUP','DRIVER_DELIVERY','LOCAL_SHIPPING_COMPANY') NOT NULL DEFAULT 'DRIVER_DELIVERY';

CREATE INDEX `delivery_methods_kind_status_idx` ON `delivery_methods`(`method_kind`, `status`);

CREATE TABLE `delivery_drivers` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `user_id` INT NULL,
  `organization_id` INT NULL,
  `branch_id` INT NULL,
  `full_name` VARCHAR(140) NOT NULL,
  `phone` VARCHAR(30) NULL,
  `driver_type` ENUM('INTERNAL','EXTERNAL') NOT NULL DEFAULT 'INTERNAL',
  `status` ENUM('ACTIVE','INACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
  `is_available` BOOLEAN NOT NULL DEFAULT true,
  `vehicle_type` VARCHAR(80) NULL,
  `vehicle_plate` VARCHAR(40) NULL,
  `current_city_id` INT NULL,
  `completed_shipments` INT NOT NULL DEFAULT 0,
  `rating_average` DECIMAL(3,2) NOT NULL DEFAULT 0,
  `created_by_user_id` INT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `delivery_drivers_publicId_key` (`publicId`),
  UNIQUE KEY `delivery_drivers_user_id_key` (`user_id`),
  KEY `delivery_drivers_org_status_available_idx` (`organization_id`, `status`, `is_available`),
  KEY `delivery_drivers_branch_status_idx` (`branch_id`, `status`),
  KEY `delivery_drivers_city_status_idx` (`current_city_id`, `status`),
  CONSTRAINT `delivery_drivers_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `delivery_drivers_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `delivery_drivers_branch_id_fkey` FOREIGN KEY (`branch_id`) REFERENCES `org_organization_branches`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `delivery_drivers_current_city_id_fkey` FOREIGN KEY (`current_city_id`) REFERENCES `geo_cities`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `delivery_local_shipping_companies` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `organization_id` INT NULL,
  `city_id` INT NULL,
  `code` VARCHAR(60) NULL,
  `name_ar` VARCHAR(160) NOT NULL,
  `name_en` VARCHAR(160) NULL,
  `phone` VARCHAR(30) NULL,
  `tracking_url_template` VARCHAR(500) NULL,
  `integration_code` VARCHAR(80) NULL,
  `supports_cod` BOOLEAN NOT NULL DEFAULT false,
  `status` ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  `created_by_user_id` INT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `delivery_local_shipping_companies_publicId_key` (`publicId`),
  UNIQUE KEY `delivery_local_shipping_companies_code_key` (`code`),
  KEY `delivery_local_shipping_companies_org_status_idx` (`organization_id`, `status`),
  KEY `delivery_local_shipping_companies_city_status_idx` (`city_id`, `status`),
  CONSTRAINT `delivery_lsc_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `delivery_lsc_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `delivery_fees` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `scope` ENUM('CITY','BRANCH','METHOD') NOT NULL DEFAULT 'CITY',
  `organization_id` INT NULL,
  `branch_id` INT NULL,
  `city_id` INT NULL,
  `delivery_method_id` INT NULL,
  `label` VARCHAR(140) NULL,
  `base_fee` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `min_fee` DECIMAL(12,2) NULL,
  `max_fee` DECIMAL(12,2) NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `estimated_min_days` INT NULL,
  `estimated_max_days` INT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT true,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `delivery_fees_publicId_key` (`publicId`),
  KEY `delivery_fees_city_method_active_idx` (`city_id`, `delivery_method_id`, `is_active`),
  KEY `delivery_fees_branch_method_active_idx` (`branch_id`, `delivery_method_id`, `is_active`),
  KEY `delivery_fees_org_active_idx` (`organization_id`, `is_active`),
  CONSTRAINT `delivery_fees_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `delivery_fees_branch_id_fkey` FOREIGN KEY (`branch_id`) REFERENCES `org_organization_branches`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `delivery_fees_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `delivery_fees_method_id_fkey` FOREIGN KEY (`delivery_method_id`) REFERENCES `delivery_methods`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `delivery_shipments`
  ADD COLUMN `delivery_fee_id` INT NULL,
  ADD COLUMN `driver_id` INT NULL,
  ADD COLUMN `shipping_company_id` INT NULL,
  ADD COLUMN `external_shipment_number` VARCHAR(120) NULL,
  ADD COLUMN `external_tracking_url` VARCHAR(500) NULL,
  ADD COLUMN `assigned_at` DATETIME(3) NULL,
  ADD COLUMN `accepted_at` DATETIME(3) NULL,
  ADD COLUMN `prepared_at` DATETIME(3) NULL,
  ADD COLUMN `completed_at` DATETIME(3) NULL,
  ADD COLUMN `cancelled_at` DATETIME(3) NULL;

CREATE INDEX `delivery_shipments_driver_status_idx` ON `delivery_shipments`(`driver_id`, `status`);
CREATE INDEX `delivery_shipments_company_status_idx` ON `delivery_shipments`(`shipping_company_id`, `status`);

ALTER TABLE `delivery_shipments`
  ADD CONSTRAINT `delivery_shipments_delivery_fee_id_fkey` FOREIGN KEY (`delivery_fee_id`) REFERENCES `delivery_fees`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `delivery_shipments_driver_id_fkey` FOREIGN KEY (`driver_id`) REFERENCES `delivery_drivers`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `delivery_shipments_shipping_company_id_fkey` FOREIGN KEY (`shipping_company_id`) REFERENCES `delivery_local_shipping_companies`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `delivery_shipment_tracking_events`
  ADD COLUMN `driver_id` INT NULL;

CREATE INDEX `delivery_events_driver_created_idx` ON `delivery_shipment_tracking_events`(`driver_id`, `created_at`);

ALTER TABLE `delivery_shipment_tracking_events`
  ADD CONSTRAINT `delivery_events_driver_id_fkey` FOREIGN KEY (`driver_id`) REFERENCES `delivery_drivers`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
