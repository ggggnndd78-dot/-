-- Phase 6: Minimal domain events foundation.
-- Scope: persist domain events, outbox records, and event logs only.
-- No async worker, accounting, payment, or future-phase logic is introduced here.

CREATE TABLE `domain_events` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `aggregate_type` VARCHAR(80) NULL,
  `aggregate_id` VARCHAR(120) NULL,
  `actor_user_id` INTEGER NULL,
  `source` VARCHAR(80) NULL,
  `idempotency_key` VARCHAR(160) NULL,
  `payload_json` JSON NULL,
  `occurred_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `domain_events_publicId_key` (`publicId`),
  UNIQUE INDEX `domain_events_idempotency_key_key` (`idempotency_key`),
  INDEX `domain_events_name_created_at_idx` (`name`, `created_at`),
  INDEX `domain_events_aggregate_idx` (`aggregate_type`, `aggregate_id`),
  INDEX `domain_events_actor_created_at_idx` (`actor_user_id`, `created_at`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `event_outbox` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `domain_event_id` INTEGER NOT NULL,
  `event_name` VARCHAR(120) NOT NULL,
  `aggregate_type` VARCHAR(80) NULL,
  `aggregate_id` VARCHAR(120) NULL,
  `destination` VARCHAR(80) NOT NULL DEFAULT 'internal',
  `payload_json` JSON NULL,
  `status` ENUM('PENDING', 'PROCESSING', 'DISPATCHED', 'FAILED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
  `attempts` INTEGER NOT NULL DEFAULT 0,
  `last_error` TEXT NULL,
  `available_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `processed_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `event_outbox_publicId_key` (`publicId`),
  INDEX `event_outbox_status_available_at_idx` (`status`, `available_at`),
  INDEX `event_outbox_event_name_created_at_idx` (`event_name`, `created_at`),
  INDEX `event_outbox_aggregate_idx` (`aggregate_type`, `aggregate_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `event_logs` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `domain_event_id` INTEGER NOT NULL,
  `event_name` VARCHAR(120) NOT NULL,
  `status` VARCHAR(40) NOT NULL DEFAULT 'RECORDED',
  `message` TEXT NULL,
  `metadata_json` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `event_logs_publicId_key` (`publicId`),
  INDEX `event_logs_domain_event_id_created_at_idx` (`domain_event_id`, `created_at`),
  INDEX `event_logs_event_name_created_at_idx` (`event_name`, `created_at`),
  INDEX `event_logs_status_created_at_idx` (`status`, `created_at`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `event_outbox`
  ADD CONSTRAINT `event_outbox_domain_event_id_fkey`
  FOREIGN KEY (`domain_event_id`) REFERENCES `domain_events`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `event_logs`
  ADD CONSTRAINT `event_logs_domain_event_id_fkey`
  FOREIGN KEY (`domain_event_id`) REFERENCES `domain_events`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
