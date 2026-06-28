-- Phase 20: Loyalty, wallet, coupons, and referral production hardening.

ALTER TABLE wallet_ledger_entries
  ADD COLUMN idempotency_key VARCHAR(180) NULL,
  ADD UNIQUE INDEX wallet_ledger_entries_idempotency_key_key (idempotency_key);

ALTER TABLE loyalty_point_transactions
  ADD COLUMN idempotency_key VARCHAR(180) NULL,
  ADD UNIQUE INDEX loyalty_point_transactions_idempotency_key_key (idempotency_key);

ALTER TABLE loyalty_coupon_redemptions
  ADD COLUMN idempotency_key VARCHAR(180) NULL,
  ADD UNIQUE INDEX loyalty_coupon_redemptions_idempotency_key_key (idempotency_key),
  ADD INDEX loyalty_coupon_redemptions_redeemed_at_idx (redeemed_at);

ALTER TABLE loyalty_coupons
  MODIFY COLUMN discount_type ENUM('PERCENTAGE','FIXED_AMOUNT','FREE_DELIVERY') NOT NULL,
  ADD COLUMN stackable BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN eligible_category_ids_json JSON NULL,
  ADD COLUMN eligible_service_ids_json JSON NULL,
  ADD COLUMN eligible_merchant_ids_json JSON NULL,
  ADD COLUMN eligible_workshop_ids_json JSON NULL;

CREATE TABLE referral_codes (
  id INT NOT NULL AUTO_INCREMENT,
  publicId VARCHAR(191) NOT NULL,
  user_id INT NOT NULL,
  code VARCHAR(40) NOT NULL,
  status ENUM('ACTIVE','PAUSED','DISABLED') NOT NULL DEFAULT 'ACTIVE',
  uses_count INT NOT NULL DEFAULT 0,
  rewards_count INT NOT NULL DEFAULT 0,
  expires_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE INDEX referral_codes_publicId_key (publicId),
  UNIQUE INDEX referral_codes_code_key (code),
  INDEX referral_codes_user_id_status_idx (user_id, status),
  INDEX referral_codes_status_expires_at_idx (status, expires_at),
  CONSTRAINT referral_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES iam_users(id) ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE referral_relationships (
  id INT NOT NULL AUTO_INCREMENT,
  publicId VARCHAR(191) NOT NULL,
  referral_code_id INT NOT NULL,
  referrer_user_id INT NOT NULL,
  referred_user_id INT NOT NULL,
  qualifying_order_id INT NULL,
  status ENUM('PENDING','QUALIFIED','REWARDED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  qualified_at DATETIME(3) NULL,
  rewarded_at DATETIME(3) NULL,
  cancelled_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE INDEX referral_relationships_publicId_key (publicId),
  UNIQUE INDEX referral_relationships_referred_user_id_key (referred_user_id),
  INDEX referral_relationships_referrer_user_id_status_idx (referrer_user_id, status),
  INDEX referral_relationships_referral_code_id_status_idx (referral_code_id, status),
  INDEX referral_relationships_qualifying_order_id_idx (qualifying_order_id),
  CONSTRAINT referral_relationships_referral_code_id_fkey FOREIGN KEY (referral_code_id) REFERENCES referral_codes(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT referral_relationships_referrer_user_id_fkey FOREIGN KEY (referrer_user_id) REFERENCES iam_users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT referral_relationships_referred_user_id_fkey FOREIGN KEY (referred_user_id) REFERENCES iam_users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT referral_relationships_qualifying_order_id_fkey FOREIGN KEY (qualifying_order_id) REFERENCES commerce_orders(id) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE referral_rewards (
  id INT NOT NULL AUTO_INCREMENT,
  publicId VARCHAR(191) NOT NULL,
  relationship_id INT NOT NULL,
  user_id INT NOT NULL,
  reward_type ENUM('LOYALTY_POINTS','WALLET_CREDIT') NOT NULL,
  status ENUM('PENDING','GRANTED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  points INT NULL,
  wallet_amount DECIMAL(14,2) NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'YER',
  order_id INT NULL,
  service_order_id INT NULL,
  wallet_ledger_entry_id INT NULL,
  loyalty_point_transaction_id INT NULL,
  idempotency_key VARCHAR(180) NOT NULL,
  created_by_user_id INT NULL,
  granted_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE INDEX referral_rewards_publicId_key (publicId),
  UNIQUE INDEX referral_rewards_idempotency_key_key (idempotency_key),
  INDEX referral_rewards_relationship_id_status_idx (relationship_id, status),
  INDEX referral_rewards_user_id_created_at_idx (user_id, created_at),
  INDEX referral_rewards_order_id_idx (order_id),
  INDEX referral_rewards_service_order_id_idx (service_order_id),
  CONSTRAINT referral_rewards_relationship_id_fkey FOREIGN KEY (relationship_id) REFERENCES referral_relationships(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT referral_rewards_user_id_fkey FOREIGN KEY (user_id) REFERENCES iam_users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT referral_rewards_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES iam_users(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT referral_rewards_order_id_fkey FOREIGN KEY (order_id) REFERENCES commerce_orders(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT referral_rewards_service_order_id_fkey FOREIGN KEY (service_order_id) REFERENCES workshop_service_orders(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT referral_rewards_wallet_ledger_entry_id_fkey FOREIGN KEY (wallet_ledger_entry_id) REFERENCES wallet_ledger_entries(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT referral_rewards_loyalty_point_transaction_id_fkey FOREIGN KEY (loyalty_point_transaction_id) REFERENCES loyalty_point_transactions(id) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
