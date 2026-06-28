-- Phase 14: Workshop Services & Booking System stabilization

CREATE TABLE IF NOT EXISTS `service_categories` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `organization_id` INT NULL,
  `city_id` INT NULL,
  `created_by_user_id` INT NULL,
  `code` VARCHAR(80) NOT NULL,
  `name_ar` VARCHAR(160) NOT NULL,
  `name_en` VARCHAR(160) NULL,
  `description` TEXT NULL,
  `icon` VARCHAR(80) NULL,
  `status` ENUM('ACTIVE','PAUSED','ARCHIVED') NOT NULL DEFAULT 'ACTIVE',
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `service_categories_publicId_key` (`publicId`),
  UNIQUE INDEX `service_categories_org_code_key` (`organization_id`, `code`),
  INDEX `service_categories_status_sort_idx` (`status`, `sort_order`),
  INDEX `service_categories_city_idx` (`city_id`),
  CONSTRAINT `service_categories_org_fk` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `service_categories_city_fk` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `service_categories_created_by_fk` FOREIGN KEY (`created_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `services` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `category_id` INT NOT NULL,
  `organization_id` INT NULL,
  `city_id` INT NULL,
  `created_by_user_id` INT NULL,
  `code` VARCHAR(90) NOT NULL,
  `name_ar` VARCHAR(180) NOT NULL,
  `name_en` VARCHAR(180) NULL,
  `description` TEXT NULL,
  `estimated_duration_minutes` INT NULL,
  `base_price` DECIMAL(12,2) NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `status` ENUM('ACTIVE','PAUSED','ARCHIVED') NOT NULL DEFAULT 'ACTIVE',
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `services_publicId_key` (`publicId`),
  UNIQUE INDEX `services_org_code_key` (`organization_id`, `code`),
  INDEX `services_category_status_idx` (`category_id`, `status`),
  INDEX `services_city_status_idx` (`city_id`, `status`),
  CONSTRAINT `services_category_fk` FOREIGN KEY (`category_id`) REFERENCES `service_categories`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `services_org_fk` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `services_city_fk` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `services_created_by_fk` FOREIGN KEY (`created_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `workshop_branches` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `organization_id` INT NOT NULL,
  `organization_branch_id` INT NOT NULL,
  `is_booking_enabled` BOOLEAN NOT NULL DEFAULT true,
  `default_slot_capacity` INT NOT NULL DEFAULT 1,
  `slot_duration_minutes` INT NOT NULL DEFAULT 60,
  `notes` VARCHAR(500) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `workshop_branches_publicId_key` (`publicId`),
  UNIQUE INDEX `workshop_branches_org_branch_key` (`organization_branch_id`),
  INDEX `workshop_branches_org_enabled_idx` (`organization_id`, `is_booking_enabled`),
  CONSTRAINT `workshop_branches_org_fk` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `workshop_branches_org_branch_fk` FOREIGN KEY (`organization_branch_id`) REFERENCES `org_organization_branches`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `booking_slots` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `organization_id` INT NOT NULL,
  `branch_id` INT NOT NULL,
  `workshop_service_id` INT NOT NULL,
  `technician_id` INT NULL,
  `slot_date` DATE NOT NULL,
  `start_at` DATETIME(3) NOT NULL,
  `end_at` DATETIME(3) NOT NULL,
  `capacity` INT NOT NULL DEFAULT 1,
  `booked_count` INT NOT NULL DEFAULT 0,
  `status` ENUM('AVAILABLE','FULL','CLOSED') NOT NULL DEFAULT 'AVAILABLE',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `booking_slots_publicId_key` (`publicId`),
  UNIQUE INDEX `booking_slots_service_branch_start_key` (`workshop_service_id`, `branch_id`, `start_at`),
  INDEX `booking_slots_org_branch_date_status_idx` (`organization_id`, `branch_id`, `slot_date`, `status`),
  INDEX `booking_slots_service_date_status_idx` (`workshop_service_id`, `slot_date`, `status`),
  INDEX `booking_slots_technician_idx` (`technician_id`),
  CONSTRAINT `booking_slots_org_fk` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `booking_slots_branch_fk` FOREIGN KEY (`branch_id`) REFERENCES `org_organization_branches`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `booking_slots_service_fk` FOREIGN KEY (`workshop_service_id`) REFERENCES `workshop_services`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `booking_slots_technician_fk` FOREIGN KEY (`technician_id`) REFERENCES `workshop_technicians`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `workshop_services`
  ADD COLUMN `service_id` INT NULL,
  ADD INDEX `workshop_services_service_id_idx` (`service_id`),
  ADD CONSTRAINT `workshop_services_service_fk` FOREIGN KEY (`service_id`) REFERENCES `services`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `workshop_bookings`
  ADD COLUMN `booking_slot_id` INT NULL,
  ADD INDEX `workshop_bookings_booking_slot_id_idx` (`booking_slot_id`),
  ADD CONSTRAINT `workshop_bookings_booking_slot_fk` FOREIGN KEY (`booking_slot_id`) REFERENCES `booking_slots`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
