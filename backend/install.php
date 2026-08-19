<?php
// ============================================================
//  RR Groups — 1-Click Database Setup & Admin Seed Installer
//  Open in browser: https://rrgroupscbe.com/backend/install.php
// ============================================================

require_once __DIR__ . '/bootstrap.php';

header('Content-Type: text/html; charset=utf-8');

$logs = [];
$success = true;

try {
    $pdo = Database::pdo();
    $dbConfig = config('db');
    $logs[] = "Connected to database: <strong>{$dbConfig['name']}</strong> successfully.";

    // 1. Create Tables
    $tables = [
        "profiles" => "CREATE TABLE IF NOT EXISTS profiles (
            id            CHAR(36)     NOT NULL PRIMARY KEY,
            email         VARCHAR(191) NULL UNIQUE,
            password_hash VARCHAR(255) NULL,
            full_name     VARCHAR(191) NOT NULL,
            mobile        VARCHAR(32)  NULL,
            role          ENUM('admin','agent','customer') NOT NULL DEFAULT 'agent',
            user_code     VARCHAR(32)  NULL,
            customer_id   CHAR(36)     NULL,
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
        ) ENGINE=InnoDB",

        "customers" => "CREATE TABLE IF NOT EXISTS customers (
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
            created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_customers_agent (assigned_agent)
        ) ENGINE=InnoDB",

        "loans" => "CREATE TABLE IF NOT EXISTS loans (
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
            INDEX idx_loans_status (status)
        ) ENGINE=InnoDB",

        "repayment_schedule" => "CREATE TABLE IF NOT EXISTS repayment_schedule (
            id             CHAR(36)     NOT NULL PRIMARY KEY,
            loan_id        CHAR(36)     NOT NULL,
            installment_no INT          NOT NULL,
            due_date       DATE         NULL,
            emi_amount     DECIMAL(14,2) NOT NULL DEFAULT 0,
            paid_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
            balance        DECIMAL(14,2) NOT NULL DEFAULT 0,
            status         ENUM('paid','partial','overdue','pending') NOT NULL DEFAULT 'pending',
            created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_sched_loan (loan_id)
        ) ENGINE=InnoDB",

        "collections" => "CREATE TABLE IF NOT EXISTS collections (
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
        ) ENGINE=InnoDB",

        "chit_groups" => "CREATE TABLE IF NOT EXISTS chit_groups (
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
        ) ENGINE=InnoDB",

        "chit_members" => "CREATE TABLE IF NOT EXISTS chit_members (
            id                  CHAR(36)     NOT NULL PRIMARY KEY,
            group_id            CHAR(36)     NOT NULL,
            customer_id         CHAR(36)     NULL,
            member_name         VARCHAR(191) NULL,
            contribution_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
            due_date            DATE         NULL,
            payment_status      ENUM('paid','partial','overdue','pending') NOT NULL DEFAULT 'pending',
            created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_members_group (group_id)
        ) ENGINE=InnoDB",

        "chit_schedules" => "CREATE TABLE IF NOT EXISTS chit_schedules (
            id             CHAR(36)     NOT NULL PRIMARY KEY,
            group_id       CHAR(36)     NOT NULL,
            installment_no INT          NOT NULL,
            due_date       DATE         NOT NULL,
            payable_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
            pool_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
            is_overridden  TINYINT(1)   NOT NULL DEFAULT 0,
            notes          VARCHAR(255) NULL,
            created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_chit_sched_group (group_id)
        ) ENGINE=InnoDB",

        "funds" => "CREATE TABLE IF NOT EXISTS funds (
            id               CHAR(36)     NOT NULL PRIMARY KEY,
            fund_number      VARCHAR(64)  NOT NULL,
            customer_id      CHAR(36)     NULL,
            customer_name    VARCHAR(191) NULL,
            weekly_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
            weeks            INT           NOT NULL DEFAULT 0,
            bonus            DECIMAL(14,2) NOT NULL DEFAULT 0,
            deposit_amount   DECIMAL(14,2) NOT NULL DEFAULT 0,
            total_amount     DECIMAL(14,2) NOT NULL DEFAULT 0,
            collected_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
            start_date       DATE          NULL,
            maturity_date    DATE          NULL,
            status           ENUM('active','matured','closed') NOT NULL DEFAULT 'active',
            assigned_agent   CHAR(36)      NULL,
            agent_name       VARCHAR(191)  NULL,
            units            DECIMAL(10,2) NOT NULL DEFAULT 1.00,
            created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_funds_customer (customer_id),
            INDEX idx_funds_agent (assigned_agent)
        ) ENGINE=InnoDB",

        "fund_payments" => "CREATE TABLE IF NOT EXISTS fund_payments (
            id             CHAR(36)     NOT NULL PRIMARY KEY,
            fund_id        CHAR(36)     NOT NULL,
            fund_number    VARCHAR(64)  NULL,
            customer_id    CHAR(36)     NULL,
            customer_name  VARCHAR(191) NULL,
            week_no        INT          NOT NULL DEFAULT 0,
            amount         DECIMAL(14,2) NOT NULL DEFAULT 0,
            balance_after  DECIMAL(14,2) NOT NULL DEFAULT 0,
            payment_method ENUM('cash','upi','card','bank','cheque') NOT NULL DEFAULT 'cash',
            payment_date   DATE         NULL,
            agent_id       CHAR(36)     NULL,
            agent_name     VARCHAR(191) NULL,
            notes          TEXT         NULL,
            created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_fund_payments_fund (fund_id),
            INDEX idx_fund_payments_customer (customer_id)
        ) ENGINE=InnoDB",

        "handovers" => "CREATE TABLE IF NOT EXISTS handovers (
            id            CHAR(36)     NOT NULL PRIMARY KEY,
            agent_id      CHAR(36)     NULL,
            agent_name    VARCHAR(191) NULL,
            cash_amount   DECIMAL(14,2) NOT NULL DEFAULT 0,
            upi_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
            total_amount  DECIMAL(14,2) NOT NULL DEFAULT 0,
            handover_date DATE         NULL,
            notes         TEXT         NULL,
            status        ENUM('pending','verified') NOT NULL DEFAULT 'pending',
            received_by   CHAR(36)     NULL,
            created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_handovers_agent (agent_id),
            INDEX idx_handovers_date (handover_date)
        ) ENGINE=InnoDB",

        "notifications" => "CREATE TABLE IF NOT EXISTS notifications (
            id         CHAR(36)     NOT NULL PRIMARY KEY,
            user_id    CHAR(36)     NULL,
            title      VARCHAR(191) NOT NULL,
            message    TEXT         NULL,
            type       ENUM('emi_due','overdue','approval','reminder','info') NOT NULL DEFAULT 'info',
            `read`     TINYINT(1)   NOT NULL DEFAULT 0,
            created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_notifications_user (user_id)
        ) ENGINE=InnoDB",

        "settings" => "CREATE TABLE IF NOT EXISTS settings (
            id                       CHAR(36)     NOT NULL PRIMARY KEY,
            company_name             VARCHAR(191) NOT NULL DEFAULT 'RR Groups',
            logo_url                 LONGTEXT     NULL,
            address                  TEXT         NULL,
            gst_number               VARCHAR(64)  NULL,
            contact_number           VARCHAR(32)  NULL,
            interest_config          DECIMAL(8,2) NOT NULL DEFAULT 12.00,
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
            updated_at               DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB",

        "push_subscriptions" => "CREATE TABLE IF NOT EXISTS push_subscriptions (
            id         CHAR(36)     NOT NULL PRIMARY KEY,
            user_id    CHAR(36)     NULL,
            endpoint   TEXT         NOT NULL,
            p256dh     TEXT         NULL,
            auth       TEXT         NULL,
            created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uniq_push_endpoint (endpoint(255))
        ) ENGINE=InnoDB",

        "biometric_credentials" => "CREATE TABLE IF NOT EXISTS biometric_credentials (
            id            CHAR(36)     NOT NULL PRIMARY KEY,
            user_id       CHAR(36)     NOT NULL,
            credential_id VARCHAR(255) NOT NULL,
            public_key    TEXT         NULL,
            label         VARCHAR(191) NULL,
            created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            last_used_at  DATETIME     NULL,
            INDEX idx_biocred_user (user_id),
            UNIQUE KEY uniq_biocred (credential_id)
        ) ENGINE=InnoDB",

        "account_ledger" => "CREATE TABLE IF NOT EXISTS account_ledger (
            id           CHAR(36)     NOT NULL PRIMARY KEY,
            entry_type   VARCHAR(64)  NOT NULL DEFAULT 'cash_in',
            title        VARCHAR(191) NOT NULL,
            amount       DECIMAL(14,2) NOT NULL DEFAULT 0,
            category     VARCHAR(128) NOT NULL DEFAULT 'General',
            entry_date   DATE         NULL,
            notes        TEXT         NULL,
            created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_account_ledger_type (entry_type),
            INDEX idx_account_ledger_date (entry_date)
        ) ENGINE=InnoDB",

        "promo_popups" => "CREATE TABLE IF NOT EXISTS promo_popups (
            id           CHAR(36)     NOT NULL PRIMARY KEY,
            title        VARCHAR(191) NOT NULL DEFAULT 'Promotional Banner',
            image_url    LONGTEXT     NOT NULL,
            target_url   TEXT         NULL,
            is_active    TINYINT(1)   NOT NULL DEFAULT 1,
            created_by   VARCHAR(191) NULL,
            created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB"
    ];

    foreach ($tables as $name => $sql) {
        $pdo->exec($sql);
        $logs[] = "Table <code>{$name}</code> checked / created successfully.";
    }

    // 2. Ensure columns in profiles & settings
    $pdo->exec("ALTER TABLE profiles MODIFY role ENUM('admin','agent','customer') NOT NULL DEFAULT 'agent'");
    $hasUserCode = $pdo->query("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'profiles' AND COLUMN_NAME = 'user_code'")->fetchColumn();
    if (!$hasUserCode) {
        $pdo->exec("ALTER TABLE profiles ADD COLUMN `user_code` VARCHAR(64) NULL AFTER `role`");
    }

    // 3. Seed Users
    $users = [
        [
            'id'        => 'f46ac1bf-6f72-49a3-aadc-dc7583c5cd77',
            'email'     => 'admin@fincollect.in',
            'password'  => 'admin123',
            'full_name' => 'Priya Sharma',
            'mobile'    => '9876543211',
            'role'      => 'admin',
            'code'      => 'RRG-ADM-0001'
        ],
        [
            'id'        => 'c834ac54-bcb6-442e-a99f-9b7c144dee24',
            'email'     => 'agent@fincollect.in',
            'password'  => 'agent123',
            'full_name' => 'Arjun Mehta',
            'mobile'    => '9876543212',
            'role'      => 'agent',
            'code'      => 'RRG-STF-0001'
        ],
        [
            'id'        => 'd0000000-0000-4000-8000-000000000004',
            'email'     => 'customer@fincollect.in',
            'password'  => 'customer123',
            'full_name' => 'Ramesh Iyer',
            'mobile'    => '9876500000',
            'role'      => 'customer',
            'code'      => 'RRG-CUS-0001'
        ]
    ];

    $userStmt = $pdo->prepare("
        INSERT INTO profiles (id, email, password_hash, full_name, mobile, role, user_code, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'active')
        ON DUPLICATE KEY UPDATE
            password_hash = VALUES(password_hash),
            full_name     = VALUES(full_name),
            mobile        = VALUES(mobile),
            role          = VALUES(role),
            user_code     = VALUES(user_code),
            status        = 'active'
    ");

    foreach ($users as $u) {
        $hash = password_hash($u['password'], PASSWORD_BCRYPT);
        $userStmt->execute([$u['id'], $u['email'], $hash, $u['full_name'], $u['mobile'], $u['role'], $u['code']]);
        $logs[] = "Seeded Account: <strong>{$u['email']}</strong> ({$u['role']}) — Password: <code>{$u['password']}</code>";
    }

    // 4. Seed Settings
    $pdo->exec("
        INSERT INTO settings (id, company_name, interest_config, emi_formula, reminder_days, reminder_time, auto_reminders_enabled, group_updates_enabled, group_auction_alerts, group_payment_alerts, language)
        VALUES ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'RR Groups', 12.00, 'P × r × (1 + r)ⁿ / ( (1 + r)ⁿ − 1 )', 3, '09:00', 1, 1, 1, 1, 'en')
        ON DUPLICATE KEY UPDATE company_name = VALUES(company_name)
    ");
    $logs[] = "Default company settings seeded.";

} catch (\Throwable $e) {
    $success = false;
    $logs[] = "<span style='color:red;'>ERROR: " . htmlspecialchars($e->getMessage()) . "</span>";
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>RR Groups — Database Installation</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0d1226; color: #e2e8f0; margin: 0; padding: 40px 20px; }
    .container { max-width: 680px; margin: 0 auto; background: #161e38; border-radius: 16px; padding: 32px; border: 1px solid #2d375a; box-shadow: 0 20px 40px rgba(0,0,0,0.5); }
    h1 { color: #dcaa3c; margin-top: 0; font-size: 24px; display: flex; align-items: center; gap: 10px; }
    .badge { display: inline-block; padding: 4px 12px; border-radius: 99px; font-size: 12px; font-weight: bold; background: <?= $success ? '#065f46; color: #6ee7b7;' : '#991b1b; color: #fca5a5;' ?>; margin-bottom: 20px; }
    .log-box { background: #0b0f20; border-radius: 10px; padding: 16px; font-family: monospace; font-size: 13px; line-height: 1.8; max-height: 340px; overflow-y: auto; border: 1px solid #1e294b; }
    .btn { display: inline-block; width: 100%; box-sizing: border-box; text-align: center; background: #a87615; color: #fff; text-decoration: none; padding: 14px 20px; border-radius: 10px; font-weight: bold; margin-top: 24px; transition: background 0.2s; }
    .btn:hover { background: #c58d20; }
    code { background: #26335a; padding: 2px 6px; border-radius: 4px; color: #fbd38d; }
  </style>
</head>
<body>
  <div class="container">
    <h1>RR Groups Setup &amp; Seeder</h1>
    <div class="badge"><?= $success ? '✔ SETUP COMPLETED SUCCESSFULLY' : '✖ SETUP FAILED' ?></div>
    
    <div class="log-box">
      <?php foreach ($logs as $log): ?>
        <div><?= $log ?></div>
      <?php endforeach; ?>
    </div>

    <?php if ($success): ?>
      <a href="/" class="btn">👉 Go to RR Groups Login Page</a>
    <?php endif; ?>
  </div>
</body>
</html>
