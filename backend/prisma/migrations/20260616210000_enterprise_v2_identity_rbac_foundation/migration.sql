-- Ghiyarak Enterprise v2.0 identity/RBAC foundation additions.
-- Supports email/SMS OTP targets, warehouse organization type, and organization employees.

ALTER TABLE `iam_otp_requests`
  MODIFY `target_value` VARCHAR(255) NOT NULL,
  MODIFY `purpose` ENUM('LOGIN','REGISTER','EMPLOYEE_INVITE','PASSWORD_RESET') NOT NULL;

ALTER TABLE `org_organizations`
  MODIFY `organization_type` ENUM('MERCHANT','WORKSHOP','WAREHOUSE') NOT NULL;

ALTER TABLE `org_organization_members`
  ADD COLUMN `status` ENUM('INVITED','ACTIVE','SUSPENDED','REMOVED') NOT NULL DEFAULT 'ACTIVE',
  ADD COLUMN `created_by_user_id` INTEGER NULL,
  ADD COLUMN `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3);

CREATE TABLE `org_employee_invitations` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `organization_id` INTEGER NOT NULL,
  `invited_email` VARCHAR(255) NULL,
  `invited_phone` VARCHAR(20) NULL,
  `display_name` VARCHAR(140) NULL,
  `member_role` VARCHAR(40) NOT NULL,
  `status` ENUM('PENDING','ACCEPTED','EXPIRED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  `invited_by_user_id` INTEGER NOT NULL,
  `accepted_by_user_id` INTEGER NULL,
  `expires_at` DATETIME(3) NOT NULL,
  `accepted_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `org_employee_invitations_publicId_key`(`publicId`),
  INDEX `org_employee_invitations_organization_id_status_idx`(`organization_id`, `status`),
  INDEX `org_employee_invitations_invited_email_idx`(`invited_email`),
  INDEX `org_employee_invitations_invited_phone_idx`(`invited_phone`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `org_member_permissions` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `organization_member_id` INTEGER NOT NULL,
  `permission_code` VARCHAR(100) NOT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `omp_member_perm_uq`(`organization_member_id`, `permission_code`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `org_member_branch_access` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `organization_member_id` INTEGER NOT NULL,
  `branch_id` INTEGER NOT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `omba_member_branch_uq`(`organization_member_id`, `branch_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `org_employee_invitations`
  ADD CONSTRAINT `oei_org_fk`
  FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `org_member_permissions`
  ADD CONSTRAINT `omp_member_fk`
  FOREIGN KEY (`organization_member_id`) REFERENCES `org_organization_members`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `org_member_branch_access`
  ADD CONSTRAINT `omba_member_fk`
  FOREIGN KEY (`organization_member_id`) REFERENCES `org_organization_members`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `org_member_branch_access`
  ADD CONSTRAINT `omba_branch_fk`
  FOREIGN KEY (`branch_id`) REFERENCES `org_organization_branches`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
