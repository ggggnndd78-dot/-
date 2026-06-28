CREATE TABLE IF NOT EXISTS `qa_test_runs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `run_key` VARCHAR(80) NOT NULL,
  `title` VARCHAR(180) NOT NULL,
  `status` ENUM('CREATED','RUNNING','PASSED','FAILED','BLOCKED') NOT NULL DEFAULT 'CREATED',
  `scope` VARCHAR(80) NOT NULL DEFAULT 'FULL_SYSTEM',
  `environment` ENUM('LOCAL','STAGING','PRODUCTION') NOT NULL DEFAULT 'LOCAL',
  `started_by_user_id` INT NULL,
  `started_at` DATETIME(3) NULL,
  `finished_at` DATETIME(3) NULL,
  `summary_json` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `qa_test_runs_run_key_key` (`run_key`),
  KEY `qa_test_runs_status_created_at_idx` (`status`, `created_at`),
  KEY `qa_test_runs_environment_created_at_idx` (`environment`, `created_at`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qa_test_results` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `run_id` INT NOT NULL,
  `suite` VARCHAR(120) NOT NULL,
  `case_key` VARCHAR(160) NOT NULL,
  `case_title` VARCHAR(240) NOT NULL,
  `status` ENUM('PASSED','FAILED','SKIPPED','BLOCKED') NOT NULL,
  `duration_ms` INT NULL,
  `error_message` TEXT NULL,
  `evidence_json` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `qa_test_results_run_suite_case_key` (`run_id`, `suite`, `case_key`),
  KEY `qa_test_results_suite_status_idx` (`suite`, `status`),
  KEY `qa_test_results_status_created_at_idx` (`status`, `created_at`),
  CONSTRAINT `qa_test_results_run_id_fkey` FOREIGN KEY (`run_id`) REFERENCES `qa_test_runs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `release_checklist_items` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `item_key` VARCHAR(120) NOT NULL,
  `module_code` VARCHAR(80) NOT NULL,
  `title_ar` VARCHAR(220) NOT NULL,
  `title_en` VARCHAR(220) NOT NULL,
  `description` TEXT NULL,
  `status` ENUM('PENDING','PASSED','FAILED','WAIVED') NOT NULL DEFAULT 'PENDING',
  `is_required` BOOLEAN NOT NULL DEFAULT TRUE,
  `evidence_url` VARCHAR(500) NULL,
  `verified_by_user_id` INT NULL,
  `verified_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `release_checklist_items_item_key_key` (`item_key`),
  KEY `release_checklist_items_module_code_status_idx` (`module_code`, `status`),
  KEY `release_checklist_items_required_status_idx` (`is_required`, `status`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `deployment_runs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `deployment_key` VARCHAR(100) NOT NULL,
  `environment` ENUM('LOCAL','STAGING','PRODUCTION') NOT NULL,
  `version` VARCHAR(80) NOT NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'CREATED',
  `commit_sha` VARCHAR(80) NULL,
  `release_notes` TEXT NULL,
  `started_by_user_id` INT NULL,
  `started_at` DATETIME(3) NULL,
  `completed_at` DATETIME(3) NULL,
  `metadata_json` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `deployment_runs_deployment_key_key` (`deployment_key`),
  KEY `deployment_runs_environment_status_idx` (`environment`, `status`),
  KEY `deployment_runs_created_at_idx` (`created_at`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
