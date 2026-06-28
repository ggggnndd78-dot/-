-- Phase 5: Administrative verification approvals and review audit trail.
-- Adds the missing review notes/status history tables required by the Ghiyarak Enterprise plan.

ALTER TABLE `org_verification_requests`
  MODIFY `status` enum('DRAFT','SUBMITTED','PENDING_REVIEW','UNDER_REVIEW','DOCUMENTS_REQUIRED','APPROVED','REJECTED','SUSPENDED','WITHDRAWN') NOT NULL DEFAULT 'DRAFT';

CREATE TABLE IF NOT EXISTS `verification_review_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `verification_request_id` int(11) NOT NULL,
  `organization_id` int(11) NOT NULL,
  `actor_user_id` int(11) NOT NULL,
  `note_type` varchar(40) NOT NULL DEFAULT 'REVIEW',
  `note` text NOT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  PRIMARY KEY (`id`),
  KEY `verification_review_notes_request_created_idx` (`verification_request_id`,`created_at`),
  KEY `verification_review_notes_org_created_idx` (`organization_id`,`created_at`),
  KEY `verification_review_notes_actor_idx` (`actor_user_id`),
  CONSTRAINT `verification_review_notes_request_fk` FOREIGN KEY (`verification_request_id`) REFERENCES `org_verification_requests` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `verification_review_notes_org_fk` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `verification_review_notes_actor_fk` FOREIGN KEY (`actor_user_id`) REFERENCES `iam_users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `verification_status_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `verification_request_id` int(11) NOT NULL,
  `organization_id` int(11) NOT NULL,
  `from_status` varchar(40) DEFAULT NULL,
  `to_status` varchar(40) NOT NULL,
  `changed_by_user_id` int(11) NOT NULL,
  `reason` text DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  PRIMARY KEY (`id`),
  KEY `verification_status_history_request_created_idx` (`verification_request_id`,`created_at`),
  KEY `verification_status_history_org_created_idx` (`organization_id`,`created_at`),
  KEY `verification_status_history_changed_by_idx` (`changed_by_user_id`),
  CONSTRAINT `verification_status_history_request_fk` FOREIGN KEY (`verification_request_id`) REFERENCES `org_verification_requests` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `verification_status_history_org_fk` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `verification_status_history_changed_by_fk` FOREIGN KEY (`changed_by_user_id`) REFERENCES `iam_users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
