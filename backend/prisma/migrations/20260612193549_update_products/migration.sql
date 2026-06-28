-- AlterTable
ALTER TABLE `catalog_categories` ALTER COLUMN `updated_at` DROP DEFAULT;

-- AlterTable
ALTER TABLE `catalog_part_brands` ALTER COLUMN `updated_at` DROP DEFAULT;

-- AlterTable
ALTER TABLE `catalog_products` ALTER COLUMN `updated_at` DROP DEFAULT;

-- AlterTable
ALTER TABLE `commerce_cart_items` ALTER COLUMN `updated_at` DROP DEFAULT;

-- AlterTable
ALTER TABLE `commerce_carts` ALTER COLUMN `updated_at` DROP DEFAULT;

-- AlterTable
ALTER TABLE `commerce_orders` ALTER COLUMN `updated_at` DROP DEFAULT;

-- AlterTable
ALTER TABLE `market_listings` ALTER COLUMN `updated_at` DROP DEFAULT;

-- RedefineIndex
CREATE INDEX `catalog_product_compatibilities_make_id_model_id_variant_id_idx` ON `catalog_product_compatibilities`(`make_id`, `model_id`, `variant_id`);
DROP INDEX `catalog_product_compatibilities_make_model_variant_idx` ON `catalog_product_compatibilities`;

-- RedefineIndex
CREATE UNIQUE INDEX `commerce_cart_items_cart_id_listing_id_key` ON `commerce_cart_items`(`cart_id`, `listing_id`);
DROP INDEX `commerce_cart_items_cart_listing_key` ON `commerce_cart_items`;

-- RedefineIndex
CREATE INDEX `commerce_carts_user_id_status_idx` ON `commerce_carts`(`user_id`, `status`);
DROP INDEX `commerce_carts_user_status_idx` ON `commerce_carts`;

-- RedefineIndex
CREATE INDEX `commerce_orders_organization_id_status_idx` ON `commerce_orders`(`organization_id`, `status`);
DROP INDEX `commerce_orders_organization_status_idx` ON `commerce_orders`;

-- RedefineIndex
CREATE INDEX `market_listings_status_approval_status_idx` ON `market_listings`(`status`, `approval_status`);
DROP INDEX `market_listings_status_approval_idx` ON `market_listings`;
