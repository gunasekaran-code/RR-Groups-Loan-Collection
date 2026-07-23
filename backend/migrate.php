<?php
// Idempotent migration for existing databases: adds the 'customer' role,
// profiles.customer_id, and KYC columns.  Run once:  php migrate.php
require_once __DIR__ . '/bootstrap.php';

$pdo = Database::pdo();

// 1. Extend the role enum to include 'customer'.
$pdo->exec("ALTER TABLE profiles MODIFY role ENUM('admin','agent','customer') NOT NULL DEFAULT 'agent'");
echo "role enum extended.\n";

// 2. Add customer_id column + index if missing.
$exists = $pdo->query(
    "SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'profiles'
       AND COLUMN_NAME = 'customer_id'"
)->fetchColumn();

if (!$exists) {
    $pdo->exec("ALTER TABLE profiles
                ADD COLUMN customer_id CHAR(36) NULL AFTER role,
                ADD INDEX idx_profiles_customer (customer_id)");
    echo "customer_id column added.\n";
} else {
    echo "customer_id column already present.\n";
}

// 3. Add KYC columns (address, aadhaar, pan, occupation) if missing.
$kyc = [
    'address'    => 'TEXT NULL',
    'aadhaar'    => 'VARCHAR(32) NULL',
    'pan'        => 'VARCHAR(32) NULL',
    'occupation' => 'VARCHAR(128) NULL',
];
foreach ($kyc as $col => $def) {
    $has = $pdo->query(
        "SELECT COUNT(*) FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'profiles' AND COLUMN_NAME = '$col'"
    )->fetchColumn();
    if (!$has) {
        $pdo->exec("ALTER TABLE profiles ADD COLUMN `$col` $def");
        echo "$col column added.\n";
    } else {
        echo "$col column already present.\n";
    }
}

// 4. Add password-reset OTP columns if missing.
$otpCols = [
    'reset_otp_hash'    => 'VARCHAR(255) NULL',
    'reset_otp_expires' => 'DATETIME NULL',
];
foreach ($otpCols as $col => $def) {
    $has = $pdo->query(
        "SELECT COUNT(*) FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'profiles' AND COLUMN_NAME = '$col'"
    )->fetchColumn();
    if (!$has) {
        $pdo->exec("ALTER TABLE profiles ADD COLUMN `$col` $def");
        echo "$col column added.\n";
    } else {
        echo "$col column already present.\n";
    }
}

// 5. Create the funds table (daily-deposit savings scheme) if missing.
$hasFunds = $pdo->query(
    "SELECT COUNT(*) FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'funds'"
)->fetchColumn();
if (!$hasFunds) {
    $pdo->exec("CREATE TABLE funds (
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
        created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_funds_customer (customer_id)
    ) ENGINE=InnoDB");
    echo "funds table created.\n";
} else {
    echo "funds table already present.\n";
}

// 6. Rename fund columns to weekly terminology (daily_amount->weekly_amount, days->weeks).
$colExists = function (string $col) use ($pdo): bool {
    return (bool)$pdo->query(
        "SELECT COUNT(*) FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'funds' AND COLUMN_NAME = '$col'"
    )->fetchColumn();
};
if (!$colExists('weekly_amount') && $colExists('daily_amount')) {
    $pdo->exec("ALTER TABLE funds CHANGE COLUMN `daily_amount` `weekly_amount` DECIMAL(14,2) NOT NULL DEFAULT 0");
    echo "funds.daily_amount renamed to weekly_amount.\n";
}
if (!$colExists('weeks') && $colExists('days')) {
    $pdo->exec("ALTER TABLE funds CHANGE COLUMN `days` `weeks` INT NOT NULL DEFAULT 0");
    echo "funds.days renamed to weeks.\n";
}

// 7. Create the fund_payments passbook table (one row per collection) if missing.
$hasFundPayments = $pdo->query(
    "SELECT COUNT(*) FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'fund_payments'"
)->fetchColumn();
if (!$hasFundPayments) {
    $pdo->exec("CREATE TABLE fund_payments (
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
    ) ENGINE=InnoDB");
    echo "fund_payments table created.\n";
} else {
    echo "fund_payments table already present.\n";
}

// 8. Create the handovers table (agent cash/UPI settlement) if missing.
$hasHandovers = $pdo->query(
    "SELECT COUNT(*) FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'handovers'"
)->fetchColumn();
if (!$hasHandovers) {
    $pdo->exec("CREATE TABLE handovers (
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
    ) ENGINE=InnoDB");
    echo "handovers table created.\n";
} else {
    echo "handovers table already present.\n";
}

// 9. Add latitude/longitude columns to customers (map coordinates) if missing.
$geoCols = [
    'latitude'  => 'DECIMAL(10,7) NULL',
    'longitude' => 'DECIMAL(10,7) NULL',
];
foreach ($geoCols as $col => $def) {
    $has = $pdo->query(
        "SELECT COUNT(*) FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'customers' AND COLUMN_NAME = '$col'"
    )->fetchColumn();
    if (!$has) {
        $pdo->exec("ALTER TABLE customers ADD COLUMN `$col` $def AFTER photo_url");
        echo "customers.$col column added.\n";
    } else {
        echo "customers.$col column already present.\n";
    }
}

echo "Migration complete.\n";
