-- Phase 3: Provider onboarding, profiles, banking, business hours, and verification workflow

ALTER TABLE `org_organizations`
  MODIFY `status` ENUM('DRAFT','PENDING_REVIEW','DOCUMENTS_REQUIRED','APPROVED','REJECTED','SUSPENDED') NOT NULL DEFAULT 'DRAFT',
  ADD COLUMN `submitted_at` DATETIME(3) NULL,
  ADD COLUMN `approved_at` DATETIME(3) NULL,
  ADD COLUMN `rejected_at` DATETIME(3) NULL,
  ADD COLUMN `rejection_reason` VARCHAR(500) NULL,
  ADD COLUMN `is_verified` BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE `org_organization_branches`
  ADD COLUMN `email` VARCHAR(255) NULL,
  ADD COLUMN `latitude` DECIMAL(10,7) NULL,
  ADD COLUMN `longitude` DECIMAL(10,7) NULL,
  ADD COLUMN `is_head_office` BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN `supports_installation` BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN `supports_mobile_service` BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE `org_merchant_profiles` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `organization_id` INTEGER NOT NULL,
  `business_category_code` VARCHAR(50) NULL,
  `average_preparation_minutes` INTEGER NULL,
  `warranty_policy_text` TEXT NULL,
  `return_policy_text` TEXT NULL,
  `delivery_policy_text` TEXT NULL,
  `min_order_amount` DECIMAL(12,2) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `org_merchant_profiles_organization_id_key`(`organization_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `org_workshop_profiles` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `organization_id` INTEGER NOT NULL,
  `service_mode_code` VARCHAR(50) NULL,
  `accepts_diagnosis` BOOLEAN NOT NULL DEFAULT true,
  `accepts_installation` BOOLEAN NOT NULL DEFAULT true,
  `capacity_per_day` INTEGER NULL,
  `supports_emergency_service` BOOLEAN NOT NULL DEFAULT false,
  `default_diagnosis_fee` DECIMAL(12,2) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `org_workshop_profiles_organization_id_key`(`organization_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `org_branch_business_hours` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `branch_id` INTEGER NOT NULL,
  `day_of_week` INTEGER NOT NULL,
  `open_time` VARCHAR(5) NULL,
  `close_time` VARCHAR(5) NULL,
  `is_closed` BOOLEAN NOT NULL DEFAULT false,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `org_branch_business_hours_branch_id_day_of_week_key`(`branch_id`, `day_of_week`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `org_bank_accounts` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `organization_id` INTEGER NOT NULL,
  `bank_name` VARCHAR(120) NOT NULL,
  `account_name` VARCHAR(120) NOT NULL,
  `account_number` VARCHAR(50) NOT NULL,
  `iban` VARCHAR(64) NULL,
  `is_primary` BOOLEAN NOT NULL DEFAULT false,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `org_verification_requests` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `organization_id` INTEGER NOT NULL,
  `submitted_by_user_id` INTEGER NOT NULL,
  `status` ENUM('DRAFT','SUBMITTED','UNDER_REVIEW','DOCUMENTS_REQUIRED','APPROVED','REJECTED','WITHDRAWN') NOT NULL DEFAULT 'DRAFT',
  `notes` TEXT NULL,
  `review_notes` TEXT NULL,
  `submitted_at` DATETIME(3) NULL,
  `reviewed_at` DATETIME(3) NULL,
  `reviewed_by_user_id` INTEGER NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `org_verification_requests_publicId_key`(`publicId`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `org_verification_documents` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `verification_request_id` INTEGER NOT NULL,
  `document_type` ENUM('COMMERCIAL_REGISTRATION','SHOP_GUARANTEE','NATIONAL_ID','STORE_FRONT','BANK_PROOF','OTHER') NOT NULL,
  `file_name` VARCHAR(255) NOT NULL,
  `file_url` VARCHAR(500) NOT NULL,
  `mime_type` VARCHAR(120) NULL,
  `notes` VARCHAR(500) NULL,
  `uploaded_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `admin_approval_actions` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `organization_id` INTEGER NOT NULL,
  `verification_request_id` INTEGER NULL,
  `acted_by_user_id` INTEGER NOT NULL,
  `action_code` VARCHAR(60) NOT NULL,
  `notes` TEXT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `org_merchant_profiles` ADD CONSTRAINT `org_merchant_profiles_organization_id_fkey`
  FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `org_workshop_profiles` ADD CONSTRAINT `org_workshop_profiles_organization_id_fkey`
  FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `org_branch_business_hours` ADD CONSTRAINT `org_branch_business_hours_branch_id_fkey`
  FOREIGN KEY (`branch_id`) REFERENCES `org_organization_branches`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `org_bank_accounts` ADD CONSTRAINT `org_bank_accounts_organization_id_fkey`
  FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `org_verification_requests` ADD CONSTRAINT `org_verification_requests_organization_id_fkey`
  FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `org_verification_requests` ADD CONSTRAINT `org_verification_requests_submitted_by_user_id_fkey`
  FOREIGN KEY (`submitted_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `org_verification_requests` ADD CONSTRAINT `org_verification_requests_reviewed_by_user_id_fkey`
  FOREIGN KEY (`reviewed_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `org_verification_documents` ADD CONSTRAINT `org_verification_documents_verification_request_id_fkey`
  FOREIGN KEY (`verification_request_id`) REFERENCES `org_verification_requests`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `admin_approval_actions` ADD CONSTRAINT `admin_approval_actions_organization_id_fkey`
  FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `admin_approval_actions` ADD CONSTRAINT `admin_approval_actions_verification_request_id_fkey`
  FOREIGN KEY (`verification_request_id`) REFERENCES `org_verification_requests`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `admin_approval_actions` ADD CONSTRAINT `admin_approval_actions_acted_by_user_id_fkey`
  FOREIGN KEY (`acted_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
