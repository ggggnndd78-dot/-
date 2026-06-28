-- Phase 16: Accounting Ledger & Financial Integrity
-- Production-safe accounting foundation: double-entry journal, immutable ledger lines,
-- merchant balances, refund accounting, and financial transaction traceability.

CREATE TABLE `ledger_accounts` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `code` VARCHAR(40) NOT NULL,
  `name_ar` VARCHAR(160) NOT NULL,
  `name_en` VARCHAR(160) NULL,
  `account_type` ENUM('ASSET','LIABILITY','EQUITY','REVENUE','EXPENSE') NOT NULL,
  `normal_balance` ENUM('DEBIT','CREDIT') NOT NULL,
  `parent_id` INTEGER NULL,
  `organization_id` INTEGER NULL,
  `currency` VARCHAR(3) NULL,
  `is_system` BOOLEAN NOT NULL DEFAULT true,
  `is_active` BOOLEAN NOT NULL DEFAULT true,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `ledger_accounts_publicId_key`(`publicId`),
  UNIQUE INDEX `ledger_accounts_code_key`(`code`),
  INDEX `ledger_accounts_account_type_is_active_idx`(`account_type`, `is_active`),
  INDEX `ledger_accounts_organization_id_idx`(`organization_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `journal_entries` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `entry_number` VARCHAR(60) NOT NULL,
  `status` ENUM('POSTED','REVERSED') NOT NULL DEFAULT 'POSTED',
  `entry_date` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `source_type` ENUM('ORDER_CONFIRMED','PAYMENT_CONFIRMED','COD_DELIVERED','REFUND_COMPLETED','SETTLEMENT_PAID','WALLET_CREDIT','WALLET_DEBIT','MANUAL') NOT NULL,
  `source_id` INTEGER NULL,
  `source_public_id` VARCHAR(120) NULL,
  `idempotency_key` VARCHAR(180) NOT NULL,
  `description` VARCHAR(500) NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `total_debit` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `total_credit` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `posted_by_user_id` INTEGER NULL,
  `posted_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `journal_entries_publicId_key`(`publicId`),
  UNIQUE INDEX `journal_entries_entry_number_key`(`entry_number`),
  UNIQUE INDEX `journal_entries_idempotency_key_key`(`idempotency_key`),
  INDEX `journal_entries_source_type_source_id_idx`(`source_type`, `source_id`),
  INDEX `journal_entries_entry_date_idx`(`entry_date`),
  INDEX `journal_entries_status_entry_date_idx`(`status`, `entry_date`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `journal_entry_lines` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `entry_id` INTEGER NOT NULL,
  `account_id` INTEGER NOT NULL,
  `organization_id` INTEGER NULL,
  `order_id` INTEGER NULL,
  `invoice_id` INTEGER NULL,
  `payment_id` INTEGER NULL,
  `refund_id` INTEGER NULL,
  `settlement_id` INTEGER NULL,
  `debit_amount` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `credit_amount` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `memo` VARCHAR(500) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX `journal_entry_lines_entry_id_idx`(`entry_id`),
  INDEX `journal_entry_lines_account_id_idx`(`account_id`),
  INDEX `journal_entry_lines_organization_id_idx`(`organization_id`),
  INDEX `journal_entry_lines_order_id_idx`(`order_id`),
  INDEX `journal_entry_lines_invoice_id_idx`(`invoice_id`),
  INDEX `journal_entry_lines_payment_id_idx`(`payment_id`),
  INDEX `journal_entry_lines_refund_id_idx`(`refund_id`),
  INDEX `journal_entry_lines_settlement_id_idx`(`settlement_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `financial_transactions` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `transaction_number` VARCHAR(60) NOT NULL,
  `source_type` ENUM('ORDER_CONFIRMED','PAYMENT_CONFIRMED','COD_DELIVERED','REFUND_COMPLETED','SETTLEMENT_PAID','WALLET_CREDIT','WALLET_DEBIT','MANUAL') NOT NULL,
  `source_id` INTEGER NULL,
  `idempotency_key` VARCHAR(180) NOT NULL,
  `direction` ENUM('INFLOW','OUTFLOW','INTERNAL') NOT NULL,
  `status` ENUM('POSTED','REVERSED') NOT NULL DEFAULT 'POSTED',
  `amount` DECIMAL(14,2) NOT NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `journal_entry_id` INTEGER NOT NULL,
  `organization_id` INTEGER NULL,
  `customer_id` INTEGER NULL,
  `order_id` INTEGER NULL,
  `invoice_id` INTEGER NULL,
  `payment_id` INTEGER NULL,
  `refund_id` INTEGER NULL,
  `settlement_id` INTEGER NULL,
  `description` VARCHAR(500) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `financial_transactions_publicId_key`(`publicId`),
  UNIQUE INDEX `financial_transactions_transaction_number_key`(`transaction_number`),
  UNIQUE INDEX `financial_transactions_idempotency_key_key`(`idempotency_key`),
  INDEX `financial_transactions_source_type_source_id_idx`(`source_type`, `source_id`),
  INDEX `financial_transactions_organization_id_created_at_idx`(`organization_id`, `created_at`),
  INDEX `financial_transactions_customer_id_created_at_idx`(`customer_id`, `created_at`),
  INDEX `financial_transactions_payment_id_idx`(`payment_id`),
  INDEX `financial_transactions_settlement_id_idx`(`settlement_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `merchant_balances` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `organization_id` INTEGER NOT NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `pending_balance` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `available_balance` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `settled_balance` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `lifetime_gross` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `lifetime_refunded` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `lifetime_settled` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `version` INTEGER NOT NULL DEFAULT 1,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  UNIQUE INDEX `merchant_balances_publicId_key`(`publicId`),
  UNIQUE INDEX `merchant_balances_organization_id_key`(`organization_id`),
  INDEX `merchant_balances_currency_idx`(`currency`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `refund_entries` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `publicId` VARCHAR(191) NOT NULL,
  `refund_id` INTEGER NOT NULL,
  `journal_entry_id` INTEGER NOT NULL,
  `amount` DECIMAL(14,2) NOT NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `refund_entries_publicId_key`(`publicId`),
  UNIQUE INDEX `refund_entries_refund_id_journal_entry_id_key`(`refund_id`, `journal_entry_id`),
  INDEX `refund_entries_refund_id_idx`(`refund_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `ledger_accounts` ADD CONSTRAINT `ledger_accounts_parent_id_fkey` FOREIGN KEY (`parent_id`) REFERENCES `ledger_accounts`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `ledger_accounts` ADD CONSTRAINT `ledger_accounts_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `journal_entries` ADD CONSTRAINT `journal_entries_posted_by_user_id_fkey` FOREIGN KEY (`posted_by_user_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `journal_entry_lines` ADD CONSTRAINT `journal_entry_lines_entry_id_fkey` FOREIGN KEY (`entry_id`) REFERENCES `journal_entries`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `journal_entry_lines` ADD CONSTRAINT `journal_entry_lines_account_id_fkey` FOREIGN KEY (`account_id`) REFERENCES `ledger_accounts`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `journal_entry_lines` ADD CONSTRAINT `journal_entry_lines_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `journal_entry_lines` ADD CONSTRAINT `journal_entry_lines_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `journal_entry_lines` ADD CONSTRAINT `journal_entry_lines_invoice_id_fkey` FOREIGN KEY (`invoice_id`) REFERENCES `commerce_invoices`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `journal_entry_lines` ADD CONSTRAINT `journal_entry_lines_payment_id_fkey` FOREIGN KEY (`payment_id`) REFERENCES `payment_transactions`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `journal_entry_lines` ADD CONSTRAINT `journal_entry_lines_refund_id_fkey` FOREIGN KEY (`refund_id`) REFERENCES `refunds`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `journal_entry_lines` ADD CONSTRAINT `journal_entry_lines_settlement_id_fkey` FOREIGN KEY (`settlement_id`) REFERENCES `settlements`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `financial_transactions` ADD CONSTRAINT `financial_transactions_journal_entry_id_fkey` FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `financial_transactions` ADD CONSTRAINT `financial_transactions_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `financial_transactions` ADD CONSTRAINT `financial_transactions_customer_id_fkey` FOREIGN KEY (`customer_id`) REFERENCES `iam_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `financial_transactions` ADD CONSTRAINT `financial_transactions_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `financial_transactions` ADD CONSTRAINT `financial_transactions_invoice_id_fkey` FOREIGN KEY (`invoice_id`) REFERENCES `commerce_invoices`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `financial_transactions` ADD CONSTRAINT `financial_transactions_payment_id_fkey` FOREIGN KEY (`payment_id`) REFERENCES `payment_transactions`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `financial_transactions` ADD CONSTRAINT `financial_transactions_refund_id_fkey` FOREIGN KEY (`refund_id`) REFERENCES `refunds`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `financial_transactions` ADD CONSTRAINT `financial_transactions_settlement_id_fkey` FOREIGN KEY (`settlement_id`) REFERENCES `settlements`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `merchant_balances` ADD CONSTRAINT `merchant_balances_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `org_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `refund_entries` ADD CONSTRAINT `refund_entries_refund_id_fkey` FOREIGN KEY (`refund_id`) REFERENCES `refunds`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `refund_entries` ADD CONSTRAINT `refund_entries_journal_entry_id_fkey` FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

INSERT INTO `ledger_accounts` (`publicId`, `code`, `name_ar`, `name_en`, `account_type`, `normal_balance`, `is_system`, `is_active`, `created_at`, `updated_at`) VALUES
(CONCAT('acc_', UUID()), '1000', 'النقدية', 'Cash', 'ASSET', 'DEBIT', true, true, NOW(3), NOW(3)),
(CONCAT('acc_', UUID()), '1010', 'الحسابات البنكية', 'Bank Accounts', 'ASSET', 'DEBIT', true, true, NOW(3), NOW(3)),
(CONCAT('acc_', UUID()), '1100', 'الذمم المدينة', 'Accounts Receivable', 'ASSET', 'DEBIT', true, true, NOW(3), NOW(3)),
(CONCAT('acc_', UUID()), '1200', 'أصول المحافظ', 'Wallet Assets', 'ASSET', 'DEBIT', true, true, NOW(3), NOW(3)),
(CONCAT('acc_', UUID()), '2000', 'مستحقات التجار والورش', 'Merchant and Workshop Payables', 'LIABILITY', 'CREDIT', true, true, NOW(3), NOW(3)),
(CONCAT('acc_', UUID()), '2100', 'التزامات محافظ العملاء', 'Customer Wallet Liabilities', 'LIABILITY', 'CREDIT', true, true, NOW(3), NOW(3)),
(CONCAT('acc_', UUID()), '2200', 'التزامات الاسترداد', 'Refunds Payable', 'LIABILITY', 'CREDIT', true, true, NOW(3), NOW(3)),
(CONCAT('acc_', UUID()), '4000', 'إيرادات السوق', 'Marketplace Revenue', 'REVENUE', 'CREDIT', true, true, NOW(3), NOW(3)),
(CONCAT('acc_', UUID()), '4100', 'إيرادات الخدمات', 'Service Revenue', 'REVENUE', 'CREDIT', true, true, NOW(3), NOW(3)),
(CONCAT('acc_', UUID()), '4200', 'إيرادات التوصيل', 'Delivery Revenue', 'REVENUE', 'CREDIT', true, true, NOW(3), NOW(3)),
(CONCAT('acc_', UUID()), '5000', 'مصروفات الاسترداد', 'Refund Expenses', 'EXPENSE', 'DEBIT', true, true, NOW(3), NOW(3)),
(CONCAT('acc_', UUID()), '5100', 'مصروفات تشغيلية', 'Operational Expenses', 'EXPENSE', 'DEBIT', true, true, NOW(3), NOW(3));
