-- Production hardening foundation: optimized read views for high-frequency app screens.
-- These views reduce repeated backend joins and keep frontend/API responses consistent.

DROP VIEW IF EXISTS `view_marketplace_listing_cards`;
CREATE VIEW `view_marketplace_listing_cards` AS
SELECT
  l.id AS listing_id,
  l.publicId AS listing_public_id,
  l.title AS listing_title,
  l.description AS listing_description,
  l.status AS listing_status,
  l.approval_status AS approval_status,
  l.condition AS product_condition,
  l.unit_price AS unit_price,
  l.sale_price AS sale_price,
  COALESCE(l.sale_price, l.unit_price) AS effective_price,
  l.currency AS currency,
  l.available_quantity AS available_quantity,
  l.reserved_quantity AS reserved_quantity,
  (l.available_quantity - l.reserved_quantity) AS available_to_sell,
  l.min_order_quantity AS min_order_quantity,
  l.supports_pickup AS supports_pickup,
  l.supports_delivery AS supports_delivery,
  l.published_at AS published_at,
  p.id AS product_id,
  p.publicId AS product_public_id,
  p.name_ar AS product_name_ar,
  p.name_en AS product_name_en,
  p.slug AS product_slug,
  p.sku AS product_sku,
  p.oem_number AS oem_number,
  c.id AS category_id,
  c.name_ar AS category_name_ar,
  c.name_en AS category_name_en,
  b.id AS brand_id,
  b.name_ar AS brand_name_ar,
  b.name_en AS brand_name_en,
  org.id AS organization_id,
  org.publicId AS organization_public_id,
  org.display_name AS organization_name,
  org.is_verified AS organization_verified,
  br.id AS branch_id,
  br.branch_name AS branch_name,
  city.id AS city_id,
  city.name_ar AS city_name_ar,
  city.name_en AS city_name_en,
  (
    SELECT pm.media_url
    FROM catalog_product_media pm
    WHERE pm.product_id = p.id AND pm.media_type = 'image'
    ORDER BY pm.sort_order ASC, pm.id ASC
    LIMIT 1
  ) AS primary_image_url
FROM market_listings l
JOIN catalog_products p ON p.id = l.product_id
JOIN catalog_categories c ON c.id = p.category_id
LEFT JOIN catalog_part_brands b ON b.id = p.part_brand_id
JOIN org_organizations org ON org.id = l.organization_id
LEFT JOIN org_organization_branches br ON br.id = l.branch_id
LEFT JOIN geo_cities city ON city.id = COALESCE(l.city_id, br.city_id)
WHERE p.is_active = TRUE;

DROP VIEW IF EXISTS `view_order_summaries`;
CREATE VIEW `view_order_summaries` AS
SELECT
  o.id AS order_id,
  o.publicId AS order_public_id,
  o.order_number AS order_number,
  o.user_id AS user_id,
  o.organization_id AS organization_id,
  org.display_name AS organization_name,
  o.branch_id AS branch_id,
  br.branch_name AS branch_name,
  o.city_id AS city_id,
  city.name_ar AS city_name_ar,
  city.name_en AS city_name_en,
  o.status AS order_status,
  o.fulfillment_method AS fulfillment_method,
  o.payment_method AS payment_method,
  o.payment_status AS payment_status,
  o.subtotal_amount AS subtotal_amount,
  o.delivery_fee AS delivery_fee,
  o.discount_amount AS discount_amount,
  o.total_amount AS total_amount,
  o.currency AS currency,
  COUNT(oi.id) AS items_count,
  SUM(oi.quantity) AS total_quantity,
  o.created_at AS created_at,
  o.updated_at AS updated_at
FROM commerce_orders o
JOIN org_organizations org ON org.id = o.organization_id
LEFT JOIN org_organization_branches br ON br.id = o.branch_id
LEFT JOIN geo_cities city ON city.id = o.city_id
LEFT JOIN commerce_order_items oi ON oi.order_id = o.id
GROUP BY
  o.id, o.publicId, o.order_number, o.user_id, o.organization_id, org.display_name,
  o.branch_id, br.branch_name, o.city_id, city.name_ar, city.name_en,
  o.status, o.fulfillment_method, o.payment_method, o.payment_status,
  o.subtotal_amount, o.delivery_fee, o.discount_amount, o.total_amount,
  o.currency, o.created_at, o.updated_at;

DROP VIEW IF EXISTS `view_workshop_booking_summaries`;
CREATE VIEW `view_workshop_booking_summaries` AS
SELECT
  b.id AS booking_id,
  b.publicId AS booking_public_id,
  b.user_id AS user_id,
  b.organization_id AS organization_id,
  org.display_name AS organization_name,
  b.branch_id AS branch_id,
  br.branch_name AS branch_name,
  b.workshop_service_id AS workshop_service_id,
  ws.name_ar AS service_title,
  ws.name_ar AS service_name_ar,
  ws.name_en AS service_name_en,
  b.status AS booking_status,
  b.preferred_date AS preferred_date,
  b.preferred_time_window AS preferred_time_window,
  b.estimated_amount AS estimated_amount,
  b.currency AS currency,
  b.created_at AS created_at,
  b.updated_at AS updated_at
FROM workshop_bookings b
JOIN org_organizations org ON org.id = b.organization_id
LEFT JOIN org_organization_branches br ON br.id = b.branch_id
JOIN workshop_services ws ON ws.id = b.workshop_service_id;

DROP VIEW IF EXISTS `view_wallet_summaries`;
CREATE VIEW `view_wallet_summaries` AS
SELECT
  w.id AS wallet_id,
  w.publicId AS wallet_public_id,
  w.owner_type AS owner_type,
  w.user_id AS user_id,
  w.organization_id AS organization_id,
  w.currency AS currency,
  w.balance AS balance,
  w.locked_balance AS locked_balance,
  (w.balance - w.locked_balance) AS available_balance,
  w.status AS wallet_status,
  w.updated_at AS updated_at,
  COUNT(le.id) AS ledger_entries_count,
  MAX(le.created_at) AS last_entry_at
FROM wallet_accounts w
LEFT JOIN wallet_ledger_entries le ON le.wallet_account_id = w.id
GROUP BY
  w.id, w.publicId, w.owner_type, w.user_id, w.organization_id,
  w.currency, w.balance, w.locked_balance, w.status, w.updated_at;
