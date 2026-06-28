-- Cart and order workflow hardening.
-- This migration keeps the current marketplace tables and completes checkout/invoice/order-fee support.

UPDATE `commerce_orders` SET `status` = 'PROCESSING' WHERE `status` = 'PREPARING';
UPDATE `commerce_orders` SET `status` = 'DELIVERED' WHERE `status` = 'COMPLETED';
UPDATE `commerce_orders` SET `status` = 'CANCELLED' WHERE `status` = 'REJECTED';

UPDATE `commerce_order_status_history` SET `status` = 'PROCESSING' WHERE `status` = 'PREPARING';
UPDATE `commerce_order_status_history` SET `status` = 'DELIVERED' WHERE `status` = 'COMPLETED';
UPDATE `commerce_order_status_history` SET `status` = 'CANCELLED' WHERE `status` = 'REJECTED';

ALTER TABLE `commerce_orders`
  MODIFY `status` ENUM('PENDING','CONFIRMED','PROCESSING','READY_FOR_PICKUP','OUT_FOR_DELIVERY','DELIVERED','CANCELLED','RETURN_REQUESTED','REFUNDED') NOT NULL DEFAULT 'PENDING';

ALTER TABLE `commerce_order_status_history`
  MODIFY `status` ENUM('PENDING','CONFIRMED','PROCESSING','READY_FOR_PICKUP','OUT_FOR_DELIVERY','DELIVERED','CANCELLED','RETURN_REQUESTED','REFUNDED') NOT NULL DEFAULT 'PENDING';

CREATE TABLE IF NOT EXISTS `commerce_invoices` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `public_id` VARCHAR(191) NOT NULL,
  `order_id` INT NOT NULL,
  `invoice_number` VARCHAR(60) NOT NULL,
  `subtotal_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `delivery_fee` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `discount_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `issued_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `commerce_invoices_public_id_key` (`public_id`),
  UNIQUE INDEX `commerce_invoices_invoice_number_key` (`invoice_number`),
  INDEX `commerce_invoices_order_id_idx` (`order_id`),
  CONSTRAINT `commerce_invoices_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `commerce_order_fees` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `order_id` INT NOT NULL,
  `fee_type` VARCHAR(40) NOT NULL,
  `label` VARCHAR(120) NOT NULL,
  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'YER',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  INDEX `commerce_order_fees_order_id_idx` (`order_id`),
  CONSTRAINT `commerce_order_fees_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `commerce_orders`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE OR REPLACE VIEW `carts` AS SELECT * FROM `commerce_carts`;
CREATE OR REPLACE VIEW `cart_items` AS SELECT * FROM `commerce_cart_items`;
CREATE OR REPLACE VIEW `orders` AS SELECT * FROM `commerce_orders`;
CREATE OR REPLACE VIEW `order_items` AS SELECT * FROM `commerce_order_items`;
CREATE OR REPLACE VIEW `order_status_history` AS SELECT * FROM `commerce_order_status_history`;
CREATE OR REPLACE VIEW `invoices` AS SELECT * FROM `commerce_invoices`;
CREATE OR REPLACE VIEW `order_fees` AS SELECT * FROM `commerce_order_fees`;
CREATE OR REPLACE VIEW `coupons` AS SELECT * FROM `loyalty_coupons`;
