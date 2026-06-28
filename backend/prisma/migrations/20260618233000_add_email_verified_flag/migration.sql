ALTER TABLE `iam_users`
  ADD COLUMN `is_email_verified` BOOLEAN NOT NULL DEFAULT false AFTER `is_phone_verified`;
