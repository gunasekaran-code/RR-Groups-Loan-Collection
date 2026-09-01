-- ============================================================
--  RRGroups / FinCollect  —  MySQL (MariaDB) schema
--  Import in phpMyAdmin or MySQL Workbench:
--  Select your database (e.g. cwhycofr_RRgroups) > Import > Choose schema.sql > Go
-- ============================================================

-- Store every text column as utf8mb4 so Tamil / Unicode is never replaced by '?'.
ALTER DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Drop in dependency order (safe re-run during development)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS promo_popups;
DROP TABLE IF EXISTS account_ledger;
DROP TABLE IF EXISTS biometric_credentials;
DROP TABLE IF EXISTS push_subscriptions;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS handovers;
DROP TABLE IF EXISTS fund_payments;
DROP TABLE IF EXISTS funds;
DROP TABLE IF EXISTS chit_passbook;
DROP TABLE IF EXISTS chit_payments;
DROP TABLE IF EXISTS chit_schedules;
DROP TABLE IF EXISTS chit_members;
DROP TABLE IF EXISTS chit_groups;
DROP TABLE IF EXISTS collections;
DROP TABLE IF EXISTS repayment_schedule;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS settings;
DROP TABLE IF EXISTS profiles;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------- profiles (users) ----------
CREATE TABLE profiles (
  id            CHAR(36)     NOT NULL PRIMARY KEY,
  email         VARCHAR(191) NULL UNIQUE,
  password_hash VARCHAR(255) NULL,
  full_name     VARCHAR(191) NOT NULL,
  mobile        VARCHAR(32)  NULL,
  role          ENUM('admin','agent','customer') NOT NULL DEFAULT 'agent',
  user_code     VARCHAR(32)  NULL,
  customer_id   CHAR(36)     NULL,   -- links a customer login to its customers row
  address       TEXT         NULL,
  aadhaar       VARCHAR(32)  NULL,
  pan           VARCHAR(32)  NULL,
  occupation    VARCHAR(128) NULL,
  status        ENUM('active','inactive') NOT NULL DEFAULT 'active',
  avatar_url    LONGTEXT     NULL,
  reset_otp_hash    VARCHAR(255) NULL,
  reset_otp_expires DATETIME     NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_profiles_role (role),
  INDEX idx_profiles_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- customers ----------
CREATE TABLE customers (
  id             CHAR(36)     NOT NULL PRIMARY KEY,
  customer_id    VARCHAR(64)  NOT NULL,
  full_name      VARCHAR(191) NOT NULL,
  mobile         VARCHAR(32)  NULL,
  address        TEXT         NULL,
  aadhaar        VARCHAR(32)  NULL,
  pan            VARCHAR(32)  NULL,
  occupation     VARCHAR(128) NULL,
  photo_url      LONGTEXT     NULL,
  aadhaar_front_url LONGTEXT  NULL,
  aadhaar_back_url  LONGTEXT  NULL,
  pan_url        LONGTEXT     NULL,
  signature_url  LONGTEXT     NULL,
  latitude       DECIMAL(10,7) NULL,
  longitude      DECIMAL(10,7) NULL,
  loan_status    ENUM('none','active','overdue','closed') NOT NULL DEFAULT 'none',
  assigned_agent CHAR(36)     NULL,
  -- Soft delete: 0 = active, 1 = deleted. Customers are never removed
  -- outright because loans, collections and chit membership reference
  -- them, and that history has to stay readable.
  delflag        TINYINT(1)   NOT NULL DEFAULT 0,
  deleted_at     DATETIME     NULL,
  deleted_by     CHAR(36)     NULL,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_customers_agent (assigned_agent),
  INDEX idx_customers_delflag (delflag),
  CONSTRAINT fk_customers_agent FOREIGN KEY (assigned_agent)
    REFERENCES profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- loans ----------
CREATE TABLE loans (
  id                  CHAR(36)     NOT NULL PRIMARY KEY,
  loan_number         VARCHAR(64)  NOT NULL,
  customer_id         CHAR(36)     NULL,
  customer_name       VARCHAR(191) NULL,
  loan_amount         DECIMAL(14,2) NOT NULL DEFAULT 0,
  interest_percentage DECIMAL(8,2)  NOT NULL DEFAULT 0,
  loan_duration       INT           NOT NULL DEFAULT 0,
  loan_type           VARCHAR(32)   NOT NULL DEFAULT 'monthly',
  start_date          DATE          NULL,
  assigned_agent      CHAR(36)      NULL,
  agent_name          VARCHAR(191)  NULL,
  processing_fee      DECIMAL(14,2) NOT NULL DEFAULT 0,
  emi                 DECIMAL(14,2) NOT NULL DEFAULT 0,
  total_interest      DECIMAL(14,2) NOT NULL DEFAULT 0,
  total_repayment     DECIMAL(14,2) NOT NULL DEFAULT 0,
  outstanding_balance DECIMAL(14,2) NOT NULL DEFAULT 0,
  penalty_amount      DECIMAL(14,2) NOT NULL DEFAULT 0,
  penalty_enabled     TINYINT(1)   NOT NULL DEFAULT 0,
  penalty_rate_per_day DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  penalty_per_week    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  status              ENUM('active','overdue','closed','pending') NOT NULL DEFAULT 'pending',
  notes               TEXT          NULL,
  created_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_loans_customer (customer_id),
  INDEX idx_loans_agent (assigned_agent),
  INDEX idx_loans_status (status),
  CONSTRAINT fk_loans_customer FOREIGN KEY (customer_id)
    REFERENCES customers(id) ON DELETE SET NULL,
  CONSTRAINT fk_loans_agent FOREIGN KEY (assigned_agent)
    REFERENCES profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- repayment_schedule ----------
CREATE TABLE repayment_schedule (
  id             CHAR(36)     NOT NULL PRIMARY KEY,
  loan_id        CHAR(36)     NOT NULL,
  installment_no INT          NOT NULL,
  due_date       DATE         NULL,
  emi_amount     DECIMAL(14,2) NOT NULL DEFAULT 0,
  paid_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
  balance        DECIMAL(14,2) NOT NULL DEFAULT 0,
  penalty_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  status         ENUM('paid','partial','overdue','pending') NOT NULL DEFAULT 'pending',
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_sched_loan (loan_id),
  CONSTRAINT fk_sched_loan FOREIGN KEY (loan_id)
    REFERENCES loans(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- collections ----------
CREATE TABLE collections (
  id               CHAR(36)     NOT NULL PRIMARY KEY,
  receipt_number   VARCHAR(64)  NOT NULL,
  loan_id          CHAR(36)     NULL,
  customer_id      CHAR(36)     NULL,
  customer_name    VARCHAR(191) NULL,
  loan_number      VARCHAR(64)  NULL,
  collection_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  payment_method   ENUM('cash','upi','card','bank','cheque') NOT NULL DEFAULT 'cash',
  collection_date  DATE         NULL,
  agent_id         CHAR(36)     NULL,
  agent_name       VARCHAR(191) NULL,
  notes            TEXT         NULL,
  proof_url        LONGTEXT     NULL,
  signature_url    LONGTEXT     NULL,
  created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_collections_loan (loan_id),
  INDEX idx_collections_agent (agent_id),
  INDEX idx_collections_date (collection_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- chit_groups ----------
CREATE TABLE chit_groups (
  id                   CHAR(36)     NOT NULL PRIMARY KEY,
  group_name           VARCHAR(191) NOT NULL,
  group_number         VARCHAR(64)  NOT NULL,
  total_members        INT          NOT NULL DEFAULT 0,
  group_value          DECIMAL(14,2) NOT NULL DEFAULT 0,
  monthly_contribution DECIMAL(14,2) NOT NULL DEFAULT 0,
  duration             INT          NOT NULL DEFAULT 0,
  start_date           DATE         NULL,
  collected_amount     DECIMAL(14,2) NOT NULL DEFAULT 0,
  pending_amount       DECIMAL(14,2) NOT NULL DEFAULT 0,
  status               ENUM('active','closed','pending') NOT NULL DEFAULT 'pending',
  draw_frequency       ENUM('monthly_1', 'monthly_2', 'monthly_3', 'custom', 'every_5_days', 'every_10_days', 'interval_days') NOT NULL DEFAULT 'monthly_1',
  draw_days            VARCHAR(191) NULL DEFAULT '1',
  draw_dates           TEXT         NULL,
  created_at           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- chit_members ----------
CREATE TABLE chit_members (
  id                  CHAR(36)     NOT NULL PRIMARY KEY,
  group_id            CHAR(36)     NOT NULL,
  customer_id         CHAR(36)     NULL,
  member_name         VARCHAR(191) NULL,
  contribution_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  due_date            DATE         NULL,
  payment_status      ENUM('paid','partial','overdue','pending') NOT NULL DEFAULT 'pending',
  created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_members_group (group_id),
  CONSTRAINT fk_members_group FOREIGN KEY (group_id)
    REFERENCES chit_groups(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- chit_schedules ----------
CREATE TABLE chit_schedules (
  id             CHAR(36)     NOT NULL PRIMARY KEY,
  group_id       CHAR(36)     NOT NULL,
  installment_no INT          NOT NULL,
  due_date       DATE         NOT NULL,
  payable_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  pool_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
  is_overridden  TINYINT(1)   NOT NULL DEFAULT 0,
  notes          VARCHAR(255) NULL,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- Two copies of a draw would ask every member to pay it twice.
  UNIQUE KEY uniq_chit_schedule_draw (group_id, installment_no),
  INDEX idx_chit_sched_group (group_id),
  CONSTRAINT fk_chit_sched_group FOREIGN KEY (group_id)
    REFERENCES chit_groups(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Per-contribution chit passbook ledger. One row per payment a member makes,
-- linked by real foreign keys instead of matching names inside ledger text.
CREATE TABLE chit_payments (
  id             CHAR(36)     NOT NULL PRIMARY KEY,
  group_id       CHAR(36)     NOT NULL,
  member_id      CHAR(36)     NULL,
  group_number   VARCHAR(64)  NULL,
  group_name     VARCHAR(191) NULL,
  customer_id    CHAR(36)     NULL,
  customer_name  VARCHAR(191) NULL,
  installment_no INT          NOT NULL DEFAULT 0,   -- which draw this payment settles (0 = unallocated)
  amount         DECIMAL(14,2) NOT NULL DEFAULT 0,
  balance_after  DECIMAL(14,2) NOT NULL DEFAULT 0,  -- member's total paid after this entry
  payment_method ENUM('cash','upi','card','bank','cheque') NOT NULL DEFAULT 'cash',
  payment_date   DATE         NULL,
  agent_id       CHAR(36)     NULL,
  agent_name     VARCHAR(191) NULL,
  ledger_id      CHAR(36)     NULL,                 -- the account_ledger receipt this came from
  notes          TEXT         NULL,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_chit_payments_group (group_id),
  INDEX idx_chit_payments_member (member_id),
  INDEX idx_chit_payments_customer (customer_id),
  INDEX idx_chit_payments_ledger (ledger_id),
  CONSTRAINT fk_chit_payments_group FOREIGN KEY (group_id)
    REFERENCES chit_groups(id) ON DELETE CASCADE,
  -- SET NULL, not CASCADE: removing someone from the group must not erase the
  -- money they already paid.
  CONSTRAINT fk_chit_payments_member FOREIGN KEY (member_id)
    REFERENCES chit_members(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Per-member chit passbook statement: one row per (group, member, draw).
-- chit_schedules says what a draw costs; this says whether THIS member has
-- settled it. The status used to be computed in the browser each time the
-- passbook modal opened, so it was never stored and never reportable.
CREATE TABLE chit_passbook (
  id             CHAR(36)      NOT NULL PRIMARY KEY,
  group_id       CHAR(36)      NOT NULL,
  member_id      CHAR(36)      NOT NULL,
  customer_id    CHAR(36)      NULL,
  schedule_id    CHAR(36)      NULL,   -- the chit_schedules draw it mirrors
  group_number   VARCHAR(64)   NULL,
  group_name     VARCHAR(191)  NULL,
  member_name    VARCHAR(191)  NULL,
  installment_no INT           NOT NULL,
  due_date       DATE          NULL,
  payable_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  pool_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
  paid_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
  balance        DECIMAL(14,2) NOT NULL DEFAULT 0,
  payment_status ENUM('paid','partial','overdue','pending') NOT NULL DEFAULT 'pending',
  is_overdue     TINYINT(1)    NOT NULL DEFAULT 0,
  paid_date      DATE          NULL,
  is_overridden  TINYINT(1)    NOT NULL DEFAULT 0,
  notes          VARCHAR(255)  NULL,
  synced_at      DATETIME      NULL,
  delflag        TINYINT(1)    NOT NULL DEFAULT 0,
  deleted_at     DATETIME      NULL,
  deleted_by     CHAR(36)      NULL,
  created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- One row per member per draw, so a repeated rebuild can never stack copies.
  UNIQUE KEY uniq_passbook_member_draw (member_id, installment_no),
  INDEX idx_passbook_group (group_id),
  INDEX idx_passbook_customer (customer_id),
  INDEX idx_passbook_status (payment_status),
  INDEX idx_passbook_delflag (delflag),
  CONSTRAINT fk_passbook_group FOREIGN KEY (group_id)
    REFERENCES chit_groups(id) ON DELETE CASCADE,
  CONSTRAINT fk_passbook_member FOREIGN KEY (member_id)
    REFERENCES chit_members(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- funds (daily-deposit savings scheme) ----------
CREATE TABLE funds (
  id               CHAR(36)     NOT NULL PRIMARY KEY,
  fund_number      VARCHAR(64)  NOT NULL,
  customer_id      CHAR(36)     NULL,
  customer_name    VARCHAR(191) NULL,
  weekly_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
  weeks            INT           NOT NULL DEFAULT 0,
  bonus            DECIMAL(14,2) NOT NULL DEFAULT 0,
  deposit_amount   DECIMAL(14,2) NOT NULL DEFAULT 0,   -- weekly_amount × weeks
  total_amount     DECIMAL(14,2) NOT NULL DEFAULT 0,   -- deposit_amount + bonus
  collected_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  start_date       DATE          NULL,
  maturity_date    DATE          NULL,
  status           ENUM('active','matured','closed') NOT NULL DEFAULT 'active',
  assigned_agent   CHAR(36)      NULL,
  agent_name       VARCHAR(191)  NULL,
  units            DECIMAL(10,2) NOT NULL DEFAULT 1.00,
  created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_funds_customer (customer_id),
  INDEX idx_funds_agent (assigned_agent),
  CONSTRAINT fk_funds_agent FOREIGN KEY (assigned_agent)
    REFERENCES profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- fund_payments (passbook — one row per collection) ----------
CREATE TABLE fund_payments (
  id             CHAR(36)     NOT NULL PRIMARY KEY,
  fund_id        CHAR(36)     NOT NULL,
  fund_number    VARCHAR(64)  NULL,
  customer_id    CHAR(36)     NULL,
  customer_name  VARCHAR(191) NULL,
  week_no        INT          NOT NULL DEFAULT 0,   -- which weekly instalment this covers
  amount         DECIMAL(14,2) NOT NULL DEFAULT 0,
  balance_after  DECIMAL(14,2) NOT NULL DEFAULT 0,  -- total collected after this entry
  payment_method ENUM('cash','upi','card','bank','cheque') NOT NULL DEFAULT 'cash',
  payment_date   DATE         NULL,
  agent_id       CHAR(36)     NULL,
  agent_name     VARCHAR(191) NULL,
  notes          TEXT         NULL,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_fund_payments_fund (fund_id),
  INDEX idx_fund_payments_customer (customer_id),
  CONSTRAINT fk_fund_payments_fund FOREIGN KEY (fund_id)
    REFERENCES funds(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- handovers (agent cash/UPI settlement to office) ----------
CREATE TABLE handovers (
  id            CHAR(36)     NOT NULL PRIMARY KEY,
  agent_id      CHAR(36)     NULL,
  agent_name    VARCHAR(191) NULL,
  cash_amount   DECIMAL(14,2) NOT NULL DEFAULT 0,
  upi_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
  total_amount  DECIMAL(14,2) NOT NULL DEFAULT 0,   -- cash + upi
  handover_date DATE         NULL,
  notes         TEXT         NULL,
  status        ENUM('pending','verified') NOT NULL DEFAULT 'pending',
  received_by   CHAR(36)     NULL,   -- admin who verified receipt
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_handovers_agent (agent_id),
  INDEX idx_handovers_date (handover_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- notifications ----------
CREATE TABLE notifications (
  id         CHAR(36)     NOT NULL PRIMARY KEY,
  user_id    CHAR(36)     NULL,
  title      VARCHAR(191) NOT NULL,
  message    TEXT         NULL,
  type       ENUM('emi_due','overdue','approval','reminder','info') NOT NULL DEFAULT 'info',
  `read`     TINYINT(1)   NOT NULL DEFAULT 0,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_notifications_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- settings ----------
CREATE TABLE settings (
  id                       CHAR(36)     NOT NULL PRIMARY KEY,
  company_name             VARCHAR(191) NOT NULL DEFAULT '',
  logo_url                 LONGTEXT     NULL,
  address                  TEXT         NULL,
  gst_number               VARCHAR(64)  NULL,
  contact_number           VARCHAR(32)  NULL,
  interest_config          DECIMAL(8,2) NOT NULL DEFAULT 0,
  emi_formula              TEXT         NULL,
  sms_enabled              TINYINT(1)   NOT NULL DEFAULT 0,
  whatsapp_enabled         TINYINT(1)   NOT NULL DEFAULT 0,
  reminder_days            INT          NOT NULL DEFAULT 3,
  reminder_time            VARCHAR(10)  NOT NULL DEFAULT '09:00',
  auto_reminders_enabled   TINYINT(1)   NOT NULL DEFAULT 1,
  reminder_template        TEXT         NULL,
  group_updates_enabled    TINYINT(1)   NOT NULL DEFAULT 1,
  group_auction_alerts     TINYINT(1)   NOT NULL DEFAULT 1,
  group_payment_alerts     TINYINT(1)   NOT NULL DEFAULT 1,
  biometric_enabled        TINYINT(1)   NOT NULL DEFAULT 0,
  biometric_required_roles VARCHAR(191) NOT NULL DEFAULT 'admin,agent',
  language                 VARCHAR(10)  NOT NULL DEFAULT 'en',
  popup_enabled            TINYINT(1)   NOT NULL DEFAULT 0,
  popup_image_url          LONGTEXT     NULL,
  popup_target_url         TEXT         NULL,
  monthly_penalty_enabled  TINYINT(1)   NOT NULL DEFAULT 0,
  monthly_penalty_per_day  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  updated_at               DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- push_subscriptions ----------
CREATE TABLE push_subscriptions (
  id         CHAR(36)     NOT NULL PRIMARY KEY,
  user_id    CHAR(36)     NULL,
  endpoint   TEXT         NOT NULL,
  p256dh     TEXT         NULL,
  auth       TEXT         NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_push_endpoint (endpoint(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- biometric_credentials (WebAuthn / passkeys) ----------
CREATE TABLE biometric_credentials (
  id            CHAR(36)     NOT NULL PRIMARY KEY,
  user_id       CHAR(36)     NOT NULL,
  credential_id VARCHAR(255) NOT NULL,
  public_key    TEXT         NULL,
  label         VARCHAR(191) NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_used_at  DATETIME     NULL,
  INDEX idx_biocred_user (user_id),
  UNIQUE KEY uniq_biocred (credential_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- account_ledger (custom ledger entries / adjustments) ----------
-- Soft-delete archive. Deliberately carries NO foreign keys: it has to
-- outlive whatever was deleted, including the parent rows it references.
CREATE TABLE recycle_bin (
  id              CHAR(36)     NOT NULL PRIMARY KEY,
  table_name      VARCHAR(64)  NOT NULL,
  record_id       VARCHAR(64)  NULL,
  label           VARCHAR(255) NULL,          -- human-readable name of the record
  payload         LONGTEXT     NOT NULL,      -- {table, row, children{table:[rows]}}
  child_count     INT          NOT NULL DEFAULT 0,
  deleted_by      CHAR(36)     NULL,
  deleted_by_name VARCHAR(191) NULL,
  deleted_by_role VARCHAR(32)  NULL,
  deleted_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  restored_at     DATETIME     NULL,
  INDEX idx_recycle_table (table_name),
  INDEX idx_recycle_deleted_at (deleted_at),
  INDEX idx_recycle_actor (deleted_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE account_ledger (
  id           CHAR(36)     NOT NULL PRIMARY KEY,
  entry_type   VARCHAR(64)  NOT NULL DEFAULT 'cash_in',
  title        VARCHAR(191) NOT NULL,
  amount       DECIMAL(14,2) NOT NULL DEFAULT 0,
  category     VARCHAR(128) NOT NULL DEFAULT 'General',
  entry_date   DATE         NULL,
  notes        TEXT         NULL,
  agent_id     CHAR(36)     NULL,
  agent_name   VARCHAR(191) NULL,
  payment_method VARCHAR(32) NULL,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_account_ledger_type (entry_type),
  INDEX idx_account_ledger_date (entry_date),
  INDEX idx_account_ledger_agent (agent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- promo_popups ----------
CREATE TABLE promo_popups (
  id           CHAR(36)     NOT NULL PRIMARY KEY,
  title        VARCHAR(191) NOT NULL DEFAULT 'Promotional Banner',
  image_url    LONGTEXT     NOT NULL,
  target_url   TEXT         NULL,
  is_active    TINYINT(1)   NOT NULL DEFAULT 1,
  created_by   VARCHAR(191) NULL,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  Seed accounts
--  All passwords below are bcrypt hashes.
--    admin@fincollect.in / admin123   (admin)
--    agent@fincollect.in / agent123   (agent)
--    customer@fincollect.in / customer123 (customer)
--  Hashes are generated by seed.php; this block is a fallback.
-- ============================================================
INSERT INTO profiles (id, email, password_hash, full_name, mobile, role, user_code, status)
VALUES
  ('f46ac1bf-6f72-49a3-aadc-dc7583c5cd77', 'admin@fincollect.in',
   '$2y$10$8K1p/a0dL1LXMIgoEDFrwOe6g7hqz9nB3T8vY1t6iQ0Yy5kqk9Zqu', 'Priya Sharma', '9876543211', 'admin', 'RRG-ADM-0001', 'active'),
  ('c834ac54-bcb6-442e-a99f-9b7c144dee24', 'agent@fincollect.in',
   '$2y$10$8K1p/a0dL1LXMIgoEDFrwOe6g7hqz9nB3T8vY1t6iQ0Yy5kqk9Zqu', 'Arjun Mehta', '9876543212', 'agent', 'RRG-STF-0001', 'active')
ON DUPLICATE KEY UPDATE email = VALUES(email);

-- ---------- initial company settings ----------
INSERT INTO settings (id, company_name, interest_config, emi_formula, reminder_days, reminder_time, auto_reminders_enabled, group_updates_enabled, group_auction_alerts, group_payment_alerts, language)
VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'RR Groups', 12.00, 'P × r × (1 + r)ⁿ / ( (1 + r)ⁿ − 1 )', 3, '09:00', 1, 1, 1, 1, 'en')
ON DUPLICATE KEY UPDATE company_name = VALUES(company_name);

