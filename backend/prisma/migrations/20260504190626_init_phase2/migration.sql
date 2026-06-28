-- CreateTable
CREATE TABLE `iam_users` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `publicId` VARCHAR(191) NOT NULL,
    `phone_e164` VARCHAR(20) NULL,
    `phone_normalized` VARCHAR(20) NULL,
    `email` VARCHAR(255) NULL,
    `display_name` VARCHAR(120) NULL,
    `status` ENUM('ACTIVE', 'BLOCKED') NOT NULL DEFAULT 'ACTIVE',
    `is_phone_verified` BOOLEAN NOT NULL DEFAULT false,
    `locale` VARCHAR(10) NOT NULL DEFAULT 'ar',
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `iam_users_publicId_key`(`publicId`),
    UNIQUE INDEX `iam_users_phone_normalized_key`(`phone_normalized`),
    UNIQUE INDEX `iam_users_email_key`(`email`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `iam_oauth_accounts` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER NOT NULL,
    `provider_code` VARCHAR(30) NOT NULL,
    `provider_user_id` VARCHAR(120) NOT NULL,
    `provider_email` VARCHAR(255) NULL,
    `linked_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `iam_oauth_accounts_provider_code_provider_user_id_key`(`provider_code`, `provider_user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `iam_otp_requests` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `publicId` VARCHAR(191) NOT NULL,
    `user_id` INTEGER NULL,
    `target_type` VARCHAR(20) NOT NULL,
    `target_value` VARCHAR(30) NOT NULL,
    `purpose` ENUM('LOGIN') NOT NULL,
    `otp_hash` VARCHAR(255) NOT NULL,
    `expires_at` DATETIME(3) NOT NULL,
    `consumed_at` DATETIME(3) NULL,
    `attempts` INTEGER NOT NULL DEFAULT 0,
    `max_attempts` INTEGER NOT NULL DEFAULT 5,
    `status` ENUM('PENDING', 'CONSUMED', 'EXPIRED') NOT NULL DEFAULT 'PENDING',
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `iam_otp_requests_publicId_key`(`publicId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `iam_refresh_tokens` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER NOT NULL,
    `token_hash` VARCHAR(255) NOT NULL,
    `expires_at` DATETIME(3) NOT NULL,
    `revoked_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `iam_guest_sessions` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `publicId` VARCHAR(191) NOT NULL,
    `guest_token_hash` VARCHAR(255) NOT NULL,
    `city_id` INTEGER NULL,
    `district_id` INTEGER NULL,
    `area_id` INTEGER NULL,
    `consumed_by_user_id` INTEGER NULL,
    `expires_at` DATETIME(3) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `iam_guest_sessions_publicId_key`(`publicId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `iam_roles` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `iam_roles_code_key`(`code`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `iam_permissions` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(80) NOT NULL,
    `name` VARCHAR(120) NOT NULL,
    `module_code` VARCHAR(50) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `iam_permissions_code_key`(`code`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `iam_role_permissions` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `role_id` INTEGER NOT NULL,
    `permission_id` INTEGER NOT NULL,

    UNIQUE INDEX `iam_role_permissions_role_id_permission_id_key`(`role_id`, `permission_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `iam_user_roles` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER NOT NULL,
    `role_id` INTEGER NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `iam_user_roles_user_id_role_id_key`(`user_id`, `role_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `crm_customer_profiles` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER NOT NULL,
    `display_name` VARCHAR(120) NULL,
    `city_id` INTEGER NULL,
    `district_id` INTEGER NULL,
    `area_id` INTEGER NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `crm_customer_profiles_user_id_key`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `crm_customer_addresses` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `customer_profile_id` INTEGER NOT NULL,
    `label` VARCHAR(60) NOT NULL,
    `recipient_name` VARCHAR(120) NOT NULL,
    `phone` VARCHAR(20) NOT NULL,
    `city_id` INTEGER NOT NULL,
    `district_id` INTEGER NULL,
    `area_id` INTEGER NULL,
    `address_line_1` VARCHAR(255) NOT NULL,
    `is_default` BOOLEAN NOT NULL DEFAULT false,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `geo_countries` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `iso_code` VARCHAR(3) NOT NULL,
    `name_ar` VARCHAR(120) NOT NULL,
    `name_en` VARCHAR(120) NULL,
    `phone_code` VARCHAR(10) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `geo_countries_iso_code_key`(`iso_code`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `geo_states` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `country_id` INTEGER NOT NULL,
    `name_ar` VARCHAR(120) NOT NULL,
    `name_en` VARCHAR(120) NULL,
    `code` VARCHAR(20) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `geo_cities` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `state_id` INTEGER NOT NULL,
    `name_ar` VARCHAR(120) NOT NULL,
    `name_en` VARCHAR(120) NULL,
    `code` VARCHAR(20) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `geo_districts` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `city_id` INTEGER NOT NULL,
    `name_ar` VARCHAR(120) NOT NULL,
    `name_en` VARCHAR(120) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `geo_areas` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `district_id` INTEGER NOT NULL,
    `name_ar` VARCHAR(120) NOT NULL,
    `name_en` VARCHAR(120) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `vehicle_makes` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `name_ar` VARCHAR(120) NOT NULL,
    `name_en` VARCHAR(120) NULL,
    `slug` VARCHAR(140) NOT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,

    UNIQUE INDEX `vehicle_makes_slug_key`(`slug`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `vehicle_models` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `make_id` INTEGER NOT NULL,
    `name_ar` VARCHAR(120) NOT NULL,
    `name_en` VARCHAR(120) NULL,
    `slug` VARCHAR(140) NOT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `vehicle_generations` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `model_id` INTEGER NOT NULL,
    `generation_name` VARCHAR(120) NOT NULL,
    `year_from` INTEGER NOT NULL,
    `year_to` INTEGER NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `vehicle_variants` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `model_id` INTEGER NOT NULL,
    `generation_id` INTEGER NULL,
    `trim_name` VARCHAR(120) NOT NULL,
    `year_from` INTEGER NOT NULL,
    `year_to` INTEGER NULL,
    `transmission_type` VARCHAR(30) NULL,
    `fuel_type` VARCHAR(30) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `vehicle_customer_vehicles` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `publicId` VARCHAR(191) NOT NULL,
    `user_id` INTEGER NOT NULL,
    `nickname` VARCHAR(80) NULL,
    `make_id` INTEGER NOT NULL,
    `model_id` INTEGER NOT NULL,
    `variant_id` INTEGER NULL,
    `year_value` INTEGER NOT NULL,
    `is_default` BOOLEAN NOT NULL DEFAULT false,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `vehicle_customer_vehicles_publicId_key`(`publicId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `org_organizations` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `publicId` VARCHAR(191) NOT NULL,
    `organization_type` ENUM('MERCHANT', 'WORKSHOP') NOT NULL,
    `display_name` VARCHAR(150) NOT NULL,
    `legal_name` VARCHAR(150) NULL,
    `primary_phone` VARCHAR(20) NULL,
    `status` ENUM('DRAFT', 'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'SUSPENDED') NOT NULL DEFAULT 'DRAFT',
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `org_organizations_publicId_key`(`publicId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `org_organization_members` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `organization_id` INTEGER NOT NULL,
    `user_id` INTEGER NOT NULL,
    `member_role` VARCHAR(40) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `org_organization_members_organization_id_user_id_key`(`organization_id`, `user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `org_organization_branches` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `publicId` VARCHAR(191) NOT NULL,
    `organization_id` INTEGER NOT NULL,
    `branch_name` VARCHAR(150) NOT NULL,
    `phone` VARCHAR(20) NULL,
    `city_id` INTEGER NOT NULL,
    `district_id` INTEGER NULL,
    `area_id` INTEGER NULL,
    `address_line_1` VARCHAR(255) NULL,
    `supports_pickup` BOOLEAN NOT NULL DEFAULT true,
    `supports_delivery` BOOLEAN NOT NULL DEFAULT false,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `org_organization_branches_publicId_key`(`publicId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `iam_oauth_accounts` ADD CONSTRAINT `iam_oauth_accounts_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `iam_otp_requests` ADD CONSTRAINT `iam_otp_requests_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `iam_refresh_tokens` ADD CONSTRAINT `iam_refresh_tokens_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `iam_guest_sessions` ADD CONSTRAINT `iam_guest_sessions_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `iam_guest_sessions` ADD CONSTRAINT `iam_guest_sessions_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `geo_districts`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `iam_guest_sessions` ADD CONSTRAINT `iam_guest_sessions_area_id_fkey` FOREIGN KEY (`area_id`) REFERENCES `geo_areas`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `iam_role_permissions` ADD CONSTRAINT `iam_role_permissions_role_id_fkey` FOREIGN KEY (`role_id`) REFERENCES `iam_roles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `iam_role_permissions` ADD CONSTRAINT `iam_role_permissions_permission_id_fkey` FOREIGN KEY (`permission_id`) REFERENCES `iam_permissions`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `iam_user_roles` ADD CONSTRAINT `iam_user_roles_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `iam_user_roles` ADD CONSTRAINT `iam_user_roles_role_id_fkey` FOREIGN KEY (`role_id`) REFERENCES `iam_roles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `crm_customer_profiles` ADD CONSTRAINT `crm_customer_profiles_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `crm_customer_profiles` ADD CONSTRAINT `crm_customer_profiles_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `crm_customer_profiles` ADD CONSTRAINT `crm_customer_profiles_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `geo_districts`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `crm_customer_profiles` ADD CONSTRAINT `crm_customer_profiles_area_id_fkey` FOREIGN KEY (`area_id`) REFERENCES `geo_areas`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `crm_customer_addresses` ADD CONSTRAINT `crm_customer_addresses_customer_profile_id_fkey` FOREIGN KEY (`customer_profile_id`) REFERENCES `crm_customer_profiles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `crm_customer_addresses` ADD CONSTRAINT `crm_customer_addresses_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `crm_customer_addresses` ADD CONSTRAINT `crm_customer_addresses_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `geo_districts`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `crm_customer_addresses` ADD CONSTRAINT `crm_customer_addresses_area_id_fkey` FOREIGN KEY (`area_id`) REFERENCES `geo_areas`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `geo_states` ADD CONSTRAINT `geo_states_country_id_fkey` FOREIGN KEY (`country_id`) REFERENCES `geo_countries`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `geo_cities` ADD CONSTRAINT `geo_cities_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `geo_states`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `geo_districts` ADD CONSTRAINT `geo_districts_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `geo_areas` ADD CONSTRAINT `geo_areas_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `geo_districts`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `vehicle_models` ADD CONSTRAINT `vehicle_models_make_id_fkey` FOREIGN KEY (`make_id`) REFERENCES `vehicle_makes`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `vehicle_generations` ADD CONSTRAINT `vehicle_generations_model_id_fkey` FOREIGN KEY (`model_id`) REFERENCES `vehicle_models`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `vehicle_variants` ADD CONSTRAINT `vehicle_variants_model_id_fkey` FOREIGN KEY (`model_id`) REFERENCES `vehicle_models`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `vehicle_variants` ADD CONSTRAINT `vehicle_variants_generation_id_fkey` FOREIGN KEY (`generation_id`) REFERENCES `vehicle_generations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `vehicle_customer_vehicles` ADD CONSTRAINT `vehicle_customer_vehicles_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `vehicle_customer_vehicles` ADD CONSTRAINT `vehicle_customer_vehicles_make_id_fkey` FOREIGN KEY (`make_id`) REFERENCES `vehicle_makes`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `vehicle_customer_vehicles` ADD CONSTRAINT `vehicle_customer_vehicles_model_id_fkey` FOREIGN KEY (`model_id`) REFERENCES `vehicle_models`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `vehicle_customer_vehicles` ADD CONSTRAINT `vehicle_customer_vehicles_variant_id_fkey` FOREIGN KEY (`variant_id`) REFERENCES `vehicle_variants`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `org_organization_members` ADD CONSTRAINT `org_organization_members_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `org_organization_members` ADD CONSTRAINT `org_organization_members_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `iam_users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `org_organization_branches` ADD CONSTRAINT `org_organization_branches_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `org_organization_branches` ADD CONSTRAINT `org_organization_branches_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `geo_cities`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `org_organization_branches` ADD CONSTRAINT `org_organization_branches_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `geo_districts`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `org_organization_branches` ADD CONSTRAINT `org_organization_branches_area_id_fkey` FOREIGN KEY (`area_id`) REFERENCES `geo_areas`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
