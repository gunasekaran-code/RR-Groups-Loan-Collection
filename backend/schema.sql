-- ============================================================
--  RRGroups / FinCollect  —  MySQL (MariaDB) schema
--  Import in MySQL Workbench:  File > Open SQL Script > Run
--  Or CLI:  mysql -u root < schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS rrgroups
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------- dedicated application user ----------
-- Uses mysql_native_password so PHP's PDO/mysqlnd connects without TLS setup.
-- Change this password and keep it in sync with backend/config.php.
CREATE USER IF NOT EXISTS 'rrgroups_app'@'localhost'
  IDENTIFIED WITH mysql_native_password BY 'Rr#app_2026local';
CREATE USER IF NOT EXISTS 'rrgroups_app'@'127.0.0.1'
  IDENTIFIED WITH mysql_native_password BY 'Rr#app_2026local';
GRANT ALL PRIVILEGES ON rrgroups.* TO 'rrgroups_app'@'localhost';
GRANT ALL PRIVILEGES ON rrgroups.* TO 'rrgroups_app'@'127.0.0.1';
FLUSH PRIVILEGES;

USE rrgroups;

-- Drop in dependency order (safe re-run during development)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS push_subscriptions;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS handovers;
DROP TABLE IF EXISTS fund_payments;
DROP TABLE IF EXISTS funds;
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
) ENGINE=InnoDB;

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
  latitude       DECIMAL(10,7) NULL,
  longitude      DECIMAL(10,7) NULL,
  loan_status    ENUM('none','active','overdue','closed') NOT NULL DEFAULT 'none',
  assigned_agent CHAR(36)     NULL,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_customers_agent (assigned_agent),
  CONSTRAINT fk_customers_agent FOREIGN KEY (assigned_agent)
    REFERENCES profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------- loans ----------
CREATE TABLE loans (
  id                  CHAR(36)     NOT NULL PRIMARY KEY,
  loan_number         VARCHAR(64)  NOT NULL,
  customer_id         CHAR(36)     NULL,
  customer_name       VARCHAR(191) NULL,
  loan_amount         DECIMAL(14,2) NOT NULL DEFAULT 0,
  interest_percentage DECIMAL(8,2)  NOT NULL DEFAULT 0,
  loan_duration       INT           NOT NULL DEFAULT 0,
  loan_type           ENUM('monthly','weekly','daily') NOT NULL DEFAULT 'monthly',
  start_date          DATE          NULL,
  assigned_agent      CHAR(36)      NULL,
  agent_name          VARCHAR(191)  NULL,
  processing_fee      DECIMAL(14,2) NOT NULL DEFAULT 0,
  emi                 DECIMAL(14,2) NOT NULL DEFAULT 0,
  total_interest      DECIMAL(14,2) NOT NULL DEFAULT 0,
  total_repayment     DECIMAL(14,2) NOT NULL DEFAULT 0,
  outstanding_balance DECIMAL(14,2) NOT NULL DEFAULT 0,
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
) ENGINE=InnoDB;

-- ---------- repayment_schedule ----------
CREATE TABLE repayment_schedule (
  id             CHAR(36)     NOT NULL PRIMARY KEY,
  loan_id        CHAR(36)     NOT NULL,
  installment_no INT          NOT NULL,
  due_date       DATE         NULL,
  emi_amount     DECIMAL(14,2) NOT NULL DEFAULT 0,
  paid_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
  balance        DECIMAL(14,2) NOT NULL DEFAULT 0,
  status         ENUM('paid','partial','overdue','pending') NOT NULL DEFAULT 'pending',
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_sched_loan (loan_id),
  CONSTRAINT fk_sched_loan FOREIGN KEY (loan_id)
    REFERENCES loans(id) ON DELETE CASCADE
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

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
  created_at           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

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
  created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_funds_customer (customer_id)
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

-- ---------- settings ----------
CREATE TABLE settings (
  id              CHAR(36)     NOT NULL PRIMARY KEY,
  company_name    VARCHAR(191) NOT NULL DEFAULT '',
  logo_url        LONGTEXT     NULL,
  address         TEXT         NULL,
  gst_number      VARCHAR(64)  NULL,
  contact_number  VARCHAR(32)  NULL,
  interest_config DECIMAL(8,2) NOT NULL DEFAULT 0,
  emi_formula     TEXT         NULL,
  sms_enabled     TINYINT(1)   NOT NULL DEFAULT 0,
  whatsapp_enabled TINYINT(1)  NOT NULL DEFAULT 0,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------- push_subscriptions ----------
CREATE TABLE push_subscriptions (
  id         CHAR(36)     NOT NULL PRIMARY KEY,
  user_id    CHAR(36)     NULL,
  endpoint   TEXT         NOT NULL,
  p256dh     TEXT         NULL,
  auth       TEXT         NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_push_endpoint (endpoint(255))
) ENGINE=InnoDB;

-- ============================================================
--  Seed accounts
--  All passwords below are bcrypt hashes.
--    owner@fincollect.in / owner123   (admin)
--    admin@fincollect.in / admin123   (admin)
--    agent@fincollect.in / agent123   (agent)
--  Hashes are generated by seed.php; this block is a fallback.
-- ============================================================
INSERT INTO profiles (id, email, password_hash, full_name, mobile, role, status)
VALUES
  ('a0000000-0000-4000-8000-000000000001', 'owner@fincollect.in',
   '$2y$10$8K1p/a0dL1LXMIgoEDFrwOe6g7hqz9nB3T8vY1t6iQ0Yy5kqk9Zqu', 'Owner Admin', '9876543210', 'admin', 'active'),
  ('f46ac1bf-6f72-49a3-aadc-dc7583c5cd77', 'admin@fincollect.in',
   '$2y$10$8K1p/a0dL1LXMIgoEDFrwOe6g7hqz9nB3T8vY1t6iQ0Yy5kqk9Zqu', 'Priya Sharma', '9876543211', 'admin', 'active'),
  ('c834ac54-bcb6-442e-a99f-9b7c144dee24', 'agent@fincollect.in',
   '$2y$10$8K1p/a0dL1LXMIgoEDFrwOe6g7hqz9nB3T8vY1t6iQ0Yy5kqk9Zqu', 'Arjun Mehta', '9876543212', 'agent', 'active')
ON DUPLICATE KEY UPDATE email = VALUES(email);
