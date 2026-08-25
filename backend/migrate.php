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

// 10. Add KYC document image columns to customers (data-URI images) if missing.
$docCols = [
    'aadhaar_front_url' => 'LONGTEXT NULL',
    'aadhaar_back_url'  => 'LONGTEXT NULL',
    'pan_url'           => 'LONGTEXT NULL',
    'signature_url'     => 'LONGTEXT NULL',
];
foreach ($docCols as $col => $def) {
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

// 11. Add payment reminder, group updates, biometric login, and language columns to settings if missing.
$settingsCols = [
    'reminder_days'            => 'INT NOT NULL DEFAULT 3',
    'reminder_time'            => "VARCHAR(10) NOT NULL DEFAULT '09:00'",
    'auto_reminders_enabled'   => 'TINYINT(1) NOT NULL DEFAULT 1',
    'reminder_template'        => 'TEXT NULL',
    'group_updates_enabled'    => 'TINYINT(1) NOT NULL DEFAULT 1',
    'group_auction_alerts'     => 'TINYINT(1) NOT NULL DEFAULT 1',
    'group_payment_alerts'     => 'TINYINT(1) NOT NULL DEFAULT 1',
    'biometric_enabled'        => 'TINYINT(1) NOT NULL DEFAULT 0',
    'biometric_required_roles' => "VARCHAR(191) NOT NULL DEFAULT 'admin,agent'",
    'language'                 => "VARCHAR(10) NOT NULL DEFAULT 'en'",
];
foreach ($settingsCols as $col => $def) {
    $has = $pdo->query(
        "SELECT COUNT(*) FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'settings' AND COLUMN_NAME = '$col'"
    )->fetchColumn();
    if (!$has) {
        $pdo->exec("ALTER TABLE settings ADD COLUMN `$col` $def");
        echo "settings.$col column added.\n";
    } else {
        echo "settings.$col column already present.\n";
    }
}

// 12. Biometric credentials table (WebAuthn / passkeys) for biometric login.
$hasBio = $pdo->query(
    "SELECT COUNT(*) FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'biometric_credentials'"
)->fetchColumn();
if (!$hasBio) {
    $pdo->exec("
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
        ) ENGINE=InnoDB
    ");
    echo "biometric_credentials table created.\n";
} else {
    echo "biometric_credentials table already present.\n";
}

// 13. Add user_code column to profiles + backfill sequential RRG-ADM-0001, RRG-STF-0001, RRG-CUS-0001 codes.
$hasUserCode = $pdo->query(
    "SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'profiles' AND COLUMN_NAME = 'user_code'"
)->fetchColumn();
if (!$hasUserCode) {
    $pdo->exec("ALTER TABLE profiles ADD COLUMN `user_code` VARCHAR(64) NULL AFTER `role`");
    echo "profiles.user_code column added.\n";
}

// Backfill profiles user_code
foreach (['admin' => 'RRG-ADM-', 'agent' => 'RRG-STF-', 'customer' => 'RRG-CUS-'] as $r => $prefix) {
    $rows = $pdo->query("SELECT id, user_code FROM profiles WHERE role = '$r' ORDER BY created_at ASC, id ASC")->fetchAll(PDO::FETCH_ASSOC);
    $idx = 1;
    foreach ($rows as $row) {
        if (!$row['user_code'] || !str_starts_with($row['user_code'], $prefix)) {
            $code = sprintf('%s%04d', $prefix, $idx);
            $stmt = $pdo->prepare("UPDATE profiles SET user_code = ? WHERE id = ?");
            $stmt->execute([$code, $row['id']]);
        } else if (preg_match('/' . preg_quote($prefix, '/') . '(\d+)/i', $row['user_code'], $m)) {
            $val = (int)$m[1];
            if ($val >= $idx) $idx = $val;
        }
        $idx++;
    }
}

// Backfill customers customer_id to RRG-CUS-XXXX
$custRows = $pdo->query("SELECT id, customer_id FROM customers ORDER BY created_at ASC, id ASC")->fetchAll(PDO::FETCH_ASSOC);
$cIdx = 1;
foreach ($custRows as $cRow) {
    if (!$cRow['customer_id'] || !str_starts_with($cRow['customer_id'], 'RRG-CUS-')) {
        $code = sprintf('RRG-CUS-%04d', $cIdx);
        $stmt = $pdo->prepare("UPDATE customers SET customer_id = ? WHERE id = ?");
        $stmt->execute([$code, $cRow['id']]);
    } else if (preg_match('/RRG-CUS-(\d+)/i', $cRow['customer_id'], $m)) {
        $val = (int)$m[1];
        if ($val >= $cIdx) $cIdx = $val;
    }
    $cIdx++;
}

// 14. Ensure account_ledger table exists and entry_type is VARCHAR(64).
$hasAccountLedger = $pdo->query(
    "SELECT COUNT(*) FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'account_ledger'"
)->fetchColumn();
if (!$hasAccountLedger) {
    $pdo->exec("
        CREATE TABLE account_ledger (
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
        ) ENGINE=InnoDB
    ");
    echo "account_ledger table created.\n";
} else {
    $pdo->exec("ALTER TABLE account_ledger MODIFY COLUMN entry_type VARCHAR(64) NOT NULL DEFAULT 'cash_in'");
    echo "account_ledger table already present, entry_type column set to VARCHAR(64).\n";
}

// 15. Ensure chit_schedules table exists.
$hasChitSchedules = $pdo->query(
    "SELECT COUNT(*) FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'chit_schedules'"
)->fetchColumn();
if (!$hasChitSchedules) {
    $pdo->exec("
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
          INDEX idx_chit_sched_group (group_id),
          CONSTRAINT fk_chit_sched_group FOREIGN KEY (group_id)
            REFERENCES chit_groups(id) ON DELETE CASCADE
        ) ENGINE=InnoDB
    ");
    echo "chit_schedules table created.\n";
} else {
    echo "chit_schedules table already present.\n";
}

// 16. Ensure chit_groups draw_frequency enum includes 'every_10_days'.
try {
    $pdo->exec("ALTER TABLE chit_groups MODIFY draw_frequency ENUM('monthly_1', 'monthly_2', 'monthly_3', 'custom', 'every_5_days', 'every_10_days', 'interval_days') NOT NULL DEFAULT 'monthly_1'");
    echo "chit_groups.draw_frequency enum updated.\n";
} catch (\Throwable $e) {
    // ignore if already updated
}

// 17. Ensure funds units column exists.
try {
    $stmt = $pdo->query("SHOW COLUMNS FROM funds LIKE 'units'");
    if ($stmt && $stmt->rowCount() === 0) {
        $pdo->exec("ALTER TABLE funds ADD COLUMN units DECIMAL(10,2) NOT NULL DEFAULT 1.00");
        echo "funds.units column added.\n";
    }
} catch (\Throwable $e) {
    // ignore if already added
}

// 18. Ensure settings popup columns exist.
try {
    $stmt = $pdo->query("SHOW COLUMNS FROM settings LIKE 'popup_enabled'");
    if ($stmt && $stmt->rowCount() === 0) {
        $pdo->exec("ALTER TABLE settings ADD COLUMN popup_enabled TINYINT(1) NOT NULL DEFAULT 0, ADD COLUMN popup_image_url LONGTEXT NULL, ADD COLUMN popup_target_url TEXT NULL");
        echo "settings.popup columns added.\n";
    }
} catch (\Throwable $e) {
    // ignore if already added
}

// 19. Ensure promo_popups table exists.
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS promo_popups (
      id           CHAR(36)     NOT NULL PRIMARY KEY,
      title        VARCHAR(191) NOT NULL DEFAULT 'Promotional Banner',
      image_url    LONGTEXT     NOT NULL,
      target_url   TEXT         NULL,
      is_active    TINYINT(1)   NOT NULL DEFAULT 1,
      created_by   VARCHAR(191) NULL,
      created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB");
    echo "promo_popups table checked/created.\n";
} catch (\Throwable $e) {
    // ignore if already created
}

// 20. Ensure loans.loan_type supports monthly_interest.
try {
    $pdo->exec("ALTER TABLE loans MODIFY COLUMN loan_type VARCHAR(32) NOT NULL DEFAULT 'monthly'");
    echo "loans.loan_type modified to VARCHAR(32) for monthly_interest support.\n";
} catch (\Throwable $e) {
    // ignore if already updated
}

// 21. Recover loans whose loan_type was blanked by the old ENUM.
// Until step 20 ran, saving an interest-only loan against the original
// ENUM('monthly','weekly','daily') stored '' instead of 'monthly_interest' —
// MySQL's invalid-value fallback when strict mode is off. Those loans then
// rendered as ordinary EMI loans with no type.
//
// The repair is evidence-based rather than a blanket rewrite: an interest-only
// loan's emi IS the monthly interest on its principal. Test against both the
// original principal (an untouched loan) and the outstanding balance (one that
// has had principal part-payments, where the monthly interest has since been
// recalculated downwards). Anything else with a blank type is reported for a
// human to look at instead of being guessed at.
try {
    $blank = $pdo->query(
        "SELECT id, loan_number, loan_amount, interest_percentage, emi, outstanding_balance
           FROM loans WHERE loan_type = '' OR loan_type IS NULL"
    )->fetchAll();

    if (!$blank) {
        echo "loan_type repair: nothing to fix.\n";
    } else {
        $fixed = [];
        $unsure = [];
        foreach ($blank as $l) {
            $rate = (float)$l['interest_percentage'];
            $emi  = (float)$l['emi'];
            $onPrincipal  = round(((float)$l['loan_amount'] * $rate) / 100, 2);
            $onOutstanding = round(((float)$l['outstanding_balance'] * $rate) / 100, 2);
            if ($rate > 0 && $emi > 0
                && (abs($emi - $onPrincipal) < 1.0 || abs($emi - $onOutstanding) < 1.0)) {
                $fixed[] = $l;
            } else {
                $unsure[] = $l;
            }
        }

        foreach ($fixed as $l) {
            $pdo->prepare("UPDATE loans SET loan_type = 'monthly_interest' WHERE id = ?")
                ->execute([$l['id']]);
            echo "  repaired {$l['loan_number']}: blank -> monthly_interest"
               . " (principal {$l['loan_amount']} @ {$l['interest_percentage']}%/mo, emi {$l['emi']})\n";
        }
        echo 'loan_type repair: ' . count($fixed) . " loan(s) restored to monthly_interest.\n";

        foreach ($unsure as $l) {
            echo "  NEEDS REVIEW {$l['loan_number']}: blank loan_type but emi {$l['emi']} does not match"
               . " interest-only maths — set its type by hand in the Loans screen.\n";
        }

        // Settle the repaired loans' figures under the correct loan type.
        if ($fixed) {
            LoanRecalc::syncMany(array_column($fixed, 'id'));
            echo "Recalculated repaired loans (outstanding principal + monthly interest).\n";
        }
    }
} catch (\Throwable $e) {
    echo 'loan_type repair FAILED: ' . $e->getMessage() . "\n";
}

// 22. Ensure penalty_amount column exists on loans and repayment_schedule.
try {
    $stmt = $pdo->query("SHOW COLUMNS FROM loans LIKE 'penalty_amount'");
    if ($stmt && $stmt->rowCount() === 0) {
        $pdo->exec("ALTER TABLE loans ADD COLUMN penalty_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00 AFTER outstanding_balance");
        echo "loans.penalty_amount column added.\n";
    }
} catch (\Throwable $e) {
    // ignore if already added
}

try {
    $stmt = $pdo->query("SHOW COLUMNS FROM repayment_schedule LIKE 'penalty_amount'");
    if ($stmt && $stmt->rowCount() === 0) {
        $pdo->exec("ALTER TABLE repayment_schedule ADD COLUMN penalty_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00 AFTER balance");
        echo "repayment_schedule.penalty_amount column added.\n";
    }
} catch (\Throwable $e) {
    // ignore if already added
}

// 23. Run a global recalculation to populate live weekly penalties and outstanding balances.
try {
    $allLoans = $pdo->query("SELECT id FROM loans WHERE status <> 'closed'")->fetchAll(PDO::FETCH_COLUMN);
    if ($allLoans) {
        LoanRecalc::syncMany($allLoans);
        echo "All active/overdue loans recalculated with live penalty logic.\n";
    }
} catch (\Throwable $e) {
    // ignore
}

// 24. Ensure configurable monthly penalty columns exist on settings and loans.
try {
    $stmt = $pdo->query("SHOW COLUMNS FROM settings LIKE 'monthly_penalty_enabled'");
    if ($stmt && $stmt->rowCount() === 0) {
        $pdo->exec("ALTER TABLE settings ADD COLUMN monthly_penalty_enabled TINYINT(1) NOT NULL DEFAULT 0, ADD COLUMN monthly_penalty_per_day DECIMAL(10,2) NOT NULL DEFAULT 0.00");
        echo "settings.monthly_penalty columns added.\n";
    }
} catch (\Throwable $e) {
    // ignore if already added
}

try {
    $stmt = $pdo->query("SHOW COLUMNS FROM loans LIKE 'penalty_enabled'");
    if ($stmt && $stmt->rowCount() === 0) {
        $pdo->exec("ALTER TABLE loans ADD COLUMN penalty_enabled TINYINT(1) NOT NULL DEFAULT 0 AFTER penalty_amount, ADD COLUMN penalty_rate_per_day DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER penalty_enabled");
        echo "loans.penalty_enabled & penalty_rate_per_day columns added.\n";
    }
} catch (\Throwable $e) {
    // ignore if already added
}

// 24b. Manual weekly penalty override. 0 keeps the automatic
//      1%-of-principal-per-missed-week default used before this column existed.
try {
    $stmt = $pdo->query("SHOW COLUMNS FROM loans LIKE 'penalty_per_week'");
    if ($stmt && $stmt->rowCount() === 0) {
        $pdo->exec("ALTER TABLE loans ADD COLUMN penalty_per_week DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER penalty_rate_per_day");
        echo "loans.penalty_per_week column added.
";
    }
} catch (\Throwable $e) {
    // ignore if already added
}

// 25. Ensure full UTF-8 (utf8mb4) support for Tamil / Unicode text rendering
try {
    $dbName = config('db')['name'] ?? 'rrgroups';
    $pdo->exec("ALTER DATABASE `{$dbName}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    
    $tables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    foreach ($tables as $table) {
        $pdo->exec("ALTER TABLE `{$table}` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    }
    echo "All tables and database converted to utf8mb4_unicode_ci for Tamil Unicode support.\n";
} catch (\Throwable $e) {
    echo "utf8mb4 table conversion: " . $e->getMessage() . "\n";
}

echo "Migration complete.\n";
