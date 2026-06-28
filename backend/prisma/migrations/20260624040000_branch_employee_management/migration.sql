-- Branch and employee management hardening.

ALTER TABLE `org_organization_members`
  ADD COLUMN `all_branches` BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE `org_organization_branches`
  ADD COLUMN `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN `temporarily_closed` BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN `closed_until` DATETIME(3) NULL,
  ADD COLUMN `closed_reason` VARCHAR(500) NULL;

CREATE INDEX `org_branch_status_idx` ON `org_organization_branches` (`organization_id`, `is_active`, `temporarily_closed`);
