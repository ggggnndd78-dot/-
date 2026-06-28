ALTER TABLE `org_organization_branches`
  ADD COLUMN `map_url` VARCHAR(500) NULL AFTER `longitude`,
  ADD COLUMN `map_provider` VARCHAR(40) NOT NULL DEFAULT 'GOOGLE_MAPS' AFTER `map_url`,
  ADD COLUMN `location_selected_at` DATETIME(3) NULL AFTER `map_provider`;

CREATE INDEX `org_branches_location_idx` ON `org_organization_branches`(`city_id`, `district_id`, `latitude`, `longitude`);
