-- Enterprise Authentication, Trusted Devices, Approval Documents and Access Control
ALTER TABLE iam_users
  ADD COLUMN failed_login_count INT NOT NULL DEFAULT 0 AFTER locale,
  ADD COLUMN locked_until DATETIME(3) NULL AFTER failed_login_count,
  ADD COLUMN last_login_at DATETIME(3) NULL AFTER locked_until;

ALTER TABLE iam_otp_requests
  ADD COLUMN ip_address VARCHAR(80) NULL AFTER status,
  ADD COLUMN user_agent VARCHAR(500) NULL AFTER ip_address;

CREATE INDEX iam_otp_requests_target_lookup_idx
  ON iam_otp_requests(target_type, target_value, purpose, status, created_at);
CREATE INDEX iam_otp_requests_user_idx
  ON iam_otp_requests(user_id, created_at);

CREATE TABLE auth_trusted_devices (
  id INT NOT NULL AUTO_INCREMENT,
  publicId VARCHAR(191) NOT NULL,
  user_id INT NOT NULL,
  device_fingerprint VARCHAR(191) NOT NULL,
  device_token_hash VARCHAR(255) NOT NULL,
  device_name VARCHAR(160) NULL,
  platform VARCHAR(40) NOT NULL DEFAULT 'UNKNOWN',
  ip_address VARCHAR(80) NULL,
  user_agent VARCHAR(500) NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'TRUSTED',
  trusted_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  last_used_at DATETIME(3) NULL,
  revoked_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY auth_trusted_devices_publicId_key (publicId),
  UNIQUE KEY auth_trusted_devices_user_fingerprint_uq (user_id, device_fingerprint),
  INDEX auth_trusted_devices_user_status_idx (user_id, status, revoked_at),
  INDEX auth_trusted_devices_fingerprint_idx (device_fingerprint),
  CONSTRAINT auth_trusted_devices_user_fk FOREIGN KEY (user_id) REFERENCES iam_users(id) ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE auth_sessions (
  id INT NOT NULL AUTO_INCREMENT,
  publicId VARCHAR(191) NOT NULL,
  user_id INT NOT NULL,
  device_id INT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
  ip_address VARCHAR(80) NULL,
  user_agent VARCHAR(500) NULL,
  permissions_hash VARCHAR(128) NULL,
  expires_at DATETIME(3) NULL,
  revoked_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  last_seen_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY auth_sessions_publicId_key (publicId),
  INDEX auth_sessions_user_status_idx (user_id, status, created_at),
  INDEX auth_sessions_device_status_idx (device_id, status),
  CONSTRAINT auth_sessions_user_fk FOREIGN KEY (user_id) REFERENCES iam_users(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT auth_sessions_device_fk FOREIGN KEY (device_id) REFERENCES auth_trusted_devices(id) ON DELETE SET NULL ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE iam_refresh_tokens
  ADD COLUMN device_id INT NULL AFTER revoked_at,
  ADD COLUMN session_id INT NULL AFTER device_id,
  ADD COLUMN ip_address VARCHAR(80) NULL AFTER session_id,
  ADD COLUMN user_agent VARCHAR(500) NULL AFTER ip_address,
  ADD INDEX iam_refresh_tokens_user_active_idx (user_id, revoked_at, expires_at),
  ADD INDEX iam_refresh_tokens_device_idx (device_id),
  ADD CONSTRAINT iam_refresh_tokens_device_fk FOREIGN KEY (device_id) REFERENCES auth_trusted_devices(id) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT iam_refresh_tokens_session_fk FOREIGN KEY (session_id) REFERENCES auth_sessions(id) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE org_verification_documents
  ADD COLUMN file_size_bytes INT NULL AFTER mime_type,
  ADD COLUMN file_content_base64 LONGTEXT NULL AFTER file_size_bytes,
  ADD COLUMN storage_provider VARCHAR(40) NOT NULL DEFAULT 'DATABASE' AFTER file_content_base64,
  ADD COLUMN storage_key VARCHAR(255) NULL AFTER storage_provider,
  ADD COLUMN upload_status VARCHAR(40) NOT NULL DEFAULT 'UPLOADED' AFTER storage_key,
  ADD COLUMN side VARCHAR(20) NULL AFTER upload_status,
  ADD INDEX org_verification_documents_request_type_idx (verification_request_id, document_type);

ALTER TABLE org_verification_documents MODIFY COLUMN file_url VARCHAR(500) NOT NULL DEFAULT '';

ALTER TABLE org_verification_documents MODIFY COLUMN document_type ENUM('COMMERCIAL_REGISTRATION','SHOP_GUARANTEE','NATIONAL_ID','STORE_FRONT','BANK_PROOF','PASSPORT','BANK_STATEMENT','OTHER') NOT NULL;

INSERT IGNORE INTO iam_permissions (code, name, module_code) VALUES
  ('auth.sessions.manage', 'Manage own authentication sessions', 'auth'),
  ('auth.devices.manage', 'Manage own trusted devices', 'auth'),
  ('memberships.apply', 'Submit membership applications', 'organizations'),
  ('memberships.review', 'Review membership applications', 'admin'),
  ('memberships.documents.view', 'View membership documents', 'admin');

INSERT IGNORE INTO iam_role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM iam_roles r JOIN iam_permissions p ON p.code IN ('auth.sessions.manage','auth.devices.manage')
WHERE r.code IN ('customer','merchant_owner','merchant_employee','workshop_owner','workshop_employee','warehouse_owner','warehouse_employee','driver','support_agent','finance_manager','admin_operations','admin_super');

INSERT IGNORE INTO iam_role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM iam_roles r JOIN iam_permissions p ON p.code = 'memberships.apply'
WHERE r.code IN ('customer','merchant_owner','workshop_owner','warehouse_owner');

INSERT IGNORE INTO iam_role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM iam_roles r JOIN iam_permissions p ON p.code IN ('memberships.review','memberships.documents.view')
WHERE r.code IN ('admin_operations','admin_super');
