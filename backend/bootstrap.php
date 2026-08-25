<?php
// ============================================================
//  Bootstrap: config, PSR-style autoloader, and HTTP helpers.
//  Every entry point (auth.php, rest.php, users.php) requires this.
// ============================================================

$GLOBALS['app_config'] = require __DIR__ . '/config.php';

// Normalize & support method override for servers (e.g. LiteSpeed) that block PATCH / PUT / DELETE:
$methodOverride = $_SERVER['HTTP_X_HTTP_METHOD_OVERRIDE']
    ?? $_SERVER['REDIRECT_HTTP_X_HTTP_METHOD_OVERRIDE']
    ?? $_GET['_method']
    ?? $_POST['_method']
    ?? null;
if ($methodOverride && in_array(strtoupper($methodOverride), ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'], true)) {
    $_SERVER['REQUEST_METHOD'] = strtoupper($methodOverride);
}

// Global uncaught exception handler returning JSON error
set_exception_handler(function (\Throwable $e) {
    if (!headers_sent()) {
        send_cors();
    }
    json_error($e->getMessage(), 500);
});

// Autoload classes from core/, models/, controllers/ by class name.
spl_autoload_register(function (string $class): void {
    foreach (['core', 'models', 'controllers'] as $dir) {
        $file = __DIR__ . "/$dir/$class.php";
        if (is_file($file)) {
            require_once $file;
            return;
        }
    }
});

function config(?string $key = null)
{
    $cfg = $GLOBALS['app_config'];
    return $key === null ? $cfg : ($cfg[$key] ?? null);
}

// ---------------- HTTP helpers ----------------
/** Allow localhost and private-LAN origins (any port) so phones on the same Wi-Fi work. */
function is_lan_origin(string $origin): bool
{
    $host = parse_url($origin, PHP_URL_HOST) ?: '';
    if ($host === 'localhost') return true;
    if (preg_match('/^127\./', $host)) return true;              // loopback
    if (preg_match('/^10\./', $host)) return true;               // 10.0.0.0/8
    if (preg_match('/^192\.168\./', $host)) return true;         // 192.168.0.0/16
    if (preg_match('/^172\.(1[6-9]|2\d|3[01])\./', $host)) return true; // 172.16.0.0/12
    return false;
}

function send_cors(): void
{
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    $allowed = config('cors_origins') ?? [];
    if (in_array('*', $allowed, true)) {
        header('Access-Control-Allow-Origin: *');
    } elseif ($origin && (in_array($origin, $allowed, true) || is_lan_origin($origin))) {
        header("Access-Control-Allow-Origin: $origin");
        header('Vary: Origin');
    }
    header('Access-Control-Allow-Methods: GET, POST, PATCH, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Authorization, X-Api-Token');
    header('Access-Control-Max-Age: 86400');
    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}

// Set default character encoding to UTF-8
if (function_exists('mb_internal_encoding')) {
    mb_internal_encoding('UTF-8');
}
if (function_exists('mb_http_output')) {
    mb_http_output('UTF-8');
}

function json_out($data, int $status = 200): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function json_error(string $message, int $status = 400): void
{
    json_out(['error' => $message], $status);
}

function read_json_body(): array
{
    if (isset($GLOBALS['__json_body_override'])) {
        return $GLOBALS['__json_body_override'];
    }
    $raw = file_get_contents('php://input');
    if ($raw === '' || $raw === false) {
        return [];
    }
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

/** Override the parsed request body for the rest of this request (per-process). */
function set_json_body(array $body): void
{
    $GLOBALS['__json_body_override'] = $body;
}

function bearer_token(): ?string
{
    $hdr = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? $_SERVER['HTTP_X_AUTHORIZATION']
        ?? $_SERVER['HTTP_X_API_TOKEN']
        ?? $_SERVER['REDIRECT_HTTP_X_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_REDIRECT_HTTP_AUTHORIZATION']
        ?? $_SERVER['AUTHORIZATION']
        ?? '';

    if (!$hdr && function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        $hdr = $headers['Authorization']
            ?? $headers['authorization']
            ?? $headers['X-Authorization']
            ?? $headers['x-authorization']
            ?? $headers['X-Api-Token']
            ?? $headers['x-api-token']
            ?? '';
    }

    if (!$hdr && function_exists('getallheaders')) {
        $headers = getallheaders();
        $hdr = $headers['Authorization']
            ?? $headers['authorization']
            ?? $headers['X-Authorization']
            ?? $headers['x-authorization']
            ?? $headers['X-Api-Token']
            ?? $headers['x-api-token']
            ?? '';
    }

    if (!$hdr && !empty($_GET['token'])) {
        $hdr = 'Bearer ' . $_GET['token'];
    }

    if (preg_match('/Bearer\s+(.+)/i', $hdr, $m)) {
        return trim($m[1]);
    }
    if ($hdr && !preg_match('/\s/', $hdr)) {
        return trim($hdr);
    }
    return null;
}

function uuid4(): string
{
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
}

function ensure_sequential_codes(): void
{
    static $ran = false;
    if ($ran) return;
    $ran = true;

    try {
        $pdo = Database::pdo();

        // Remove old 'owner' account so only Admin, Staff, and Customer logins exist.
        $pdo->exec("DELETE FROM profiles WHERE email = 'owner@fincollect.in' OR full_name = 'Owner Admin'");

        // 1. Ensure user_code column exists in profiles
        $hasUserCode = $pdo->query(
            "SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'profiles' AND COLUMN_NAME = 'user_code'"
        )->fetchColumn();
        if (!$hasUserCode) {
            $pdo->exec("ALTER TABLE profiles ADD COLUMN `user_code` VARCHAR(64) NULL AFTER `role`");
        }

        // 2. Check if any profiles or customers need code updates
        $unfixedCust = (int)$pdo->query("SELECT COUNT(*) FROM customers WHERE customer_id NOT LIKE 'RRG-CUS-%'")->fetchColumn();
        $unfixedProf = (int)$pdo->query("SELECT COUNT(*) FROM profiles WHERE user_code IS NULL OR user_code NOT LIKE 'RRG-%'")->fetchColumn();

        if ($unfixedCust > 0 || $unfixedProf > 0) {
            // Fix profiles
            foreach (['admin' => 'RRG-ADM-', 'agent' => 'RRG-STF-', 'customer' => 'RRG-CUS-'] as $r => $prefix) {
                $rows = $pdo->query("SELECT id, user_code FROM profiles WHERE role = '$r' ORDER BY created_at ASC, id ASC")->fetchAll(PDO::FETCH_ASSOC);
                $idx = 1;
                foreach ($rows as $row) {
                    $code = sprintf('%s%04d', $prefix, $idx);
                    $stmt = $pdo->prepare("UPDATE profiles SET user_code = ? WHERE id = ?");
                    $stmt->execute([$code, $row['id']]);
                    $idx++;
                }
            }

            // Fix customers
            $custRows = $pdo->query("SELECT id, customer_id FROM customers ORDER BY created_at ASC, id ASC")->fetchAll(PDO::FETCH_ASSOC);
            $cIdx = 1;
            foreach ($custRows as $cRow) {
                $code = sprintf('RRG-CUS-%04d', $cIdx);
                $stmt = $pdo->prepare("UPDATE customers SET customer_id = ? WHERE id = ?");
                $stmt->execute([$code, $cRow['id']]);
                $cIdx++;
            }
        }
    } catch (\Throwable $e) {
        // Silently ignore schema check errors
    }
}

function ensure_chit_schedules_table(): void
{
    static $ran = false;
    if ($ran) return;
    $ran = true;

    try {
        $pdo = Database::pdo();
        $hasTable = (int)$pdo->query(
            "SELECT COUNT(*) FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'chit_schedules'"
        )->fetchColumn();
        if (!$hasTable) {
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
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            ");
        }
        // Ensure every_10_days is supported in draw_frequency enum
        $pdo->exec("ALTER TABLE chit_groups MODIFY draw_frequency ENUM('monthly_1', 'monthly_2', 'monthly_3', 'custom', 'every_5_days', 'every_10_days', 'interval_days') NOT NULL DEFAULT 'monthly_1'");
    } catch (\Throwable $e) {
        // Silently ignore schema check errors
    }
}

function ensure_funds_units_column() {
    try {
        $pdo = Database::pdo();
        $stmt = $pdo->query("SHOW COLUMNS FROM funds LIKE 'units'");
        if ($stmt && $stmt->rowCount() === 0) {
            $pdo->exec("ALTER TABLE funds ADD COLUMN units DECIMAL(10,2) NOT NULL DEFAULT 1.00");
        }
    } catch (\Throwable $e) {
        // Silently ignore schema check errors
    }
}

function ensure_popup_settings_columns() {
    try {
        $pdo = Database::pdo();
        $stmt = $pdo->query("SHOW COLUMNS FROM settings LIKE 'popup_enabled'");
        if ($stmt && $stmt->rowCount() === 0) {
            $pdo->exec("ALTER TABLE settings ADD COLUMN popup_enabled TINYINT(1) NOT NULL DEFAULT 0, ADD COLUMN popup_image_url LONGTEXT NULL, ADD COLUMN popup_target_url TEXT NULL");
        }
        $countStmt = $pdo->query("SELECT COUNT(*) FROM settings");
        if ($countStmt && (int)$countStmt->fetchColumn() === 0) {
            $pdo->exec("INSERT INTO settings (id, company_name, popup_enabled, updated_at) VALUES (UUID(), 'RR Groups', 1, NOW())");
        }
    } catch (\Throwable $e) {
        // Silently ignore schema check errors
    }
}

/**
 * Penalty columns on `loans`.
 *
 * `penalty_per_week` lets an operator type the weekly-loan penalty by hand.
 * Left at 0 the recalculator falls back to the original automatic rate
 * (1% of principal per missed week, minimum ₹100), so loans created before
 * this column existed keep behaving exactly as they did.
 */
function ensure_loan_penalty_columns(): void
{
    static $ran = false;
    if ($ran) return;
    $ran = true;

    try {
        $pdo = Database::pdo();
        $add = [];
        foreach ([
            'penalty_amount'       => "DECIMAL(14,2) NOT NULL DEFAULT 0.00",
            'penalty_enabled'      => "TINYINT(1) NOT NULL DEFAULT 0",
            'penalty_rate_per_day' => "DECIMAL(10,2) NOT NULL DEFAULT 0.00",
            'penalty_per_week'     => "DECIMAL(10,2) NOT NULL DEFAULT 0.00",
        ] as $col => $def) {
            $stmt = $pdo->query("SHOW COLUMNS FROM loans LIKE '$col'");
            if ($stmt && $stmt->rowCount() === 0) {
                $add[] = "ADD COLUMN `$col` $def";
            }
        }
        if ($add) {
            $pdo->exec("ALTER TABLE loans " . implode(', ', $add));
        }
    } catch (\Throwable $e) {
        // Silently ignore schema check errors
    }
}

ensure_chit_schedules_table();
ensure_funds_units_column();
ensure_popup_settings_columns();
/**
 * Attribution columns on `account_ledger`.
 *
 * A chit contribution is recorded only as a ledger receipt, so without an
 * agent_id there is no way to tell who took the money — which kept agent chit
 * collections out of the Cash Handover tally. payment_method lets the same
 * screen split cash from UPI instead of parsing it out of the notes text.
 */
function ensure_ledger_agent_columns(): void
{
    static $ran = false;
    if ($ran) return;
    $ran = true;

    try {
        $pdo = Database::pdo();
        $add = [];
        foreach ([
            'agent_id'       => "CHAR(36) NULL",
            'agent_name'     => "VARCHAR(191) NULL",
            'payment_method' => "VARCHAR(32) NULL",
        ] as $col => $def) {
            $stmt = $pdo->query("SHOW COLUMNS FROM account_ledger LIKE '$col'");
            if ($stmt && $stmt->rowCount() === 0) {
                $add[] = "ADD COLUMN `$col` $def";
            }
        }
        if ($add) {
            $pdo->exec("ALTER TABLE account_ledger " . implode(', ', $add));
        }
    } catch (\Throwable $e) {
        // Silently ignore schema check errors
    }
}

ensure_loan_penalty_columns();
ensure_ledger_agent_columns();

function ensure_promo_popups_table() {
    try {
        $pdo = Database::pdo();
        $pdo->exec("CREATE TABLE IF NOT EXISTS promo_popups (
          id           CHAR(36)     NOT NULL PRIMARY KEY,
          title        VARCHAR(191) NOT NULL DEFAULT 'Promotional Banner',
          image_url    LONGTEXT     NOT NULL,
          target_url   TEXT         NULL,
          is_active    TINYINT(1)   NOT NULL DEFAULT 1,
          created_by   VARCHAR(191) NULL,
          created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    } catch (\Throwable $e) {
        // Silently ignore schema check errors
    }
}
ensure_promo_popups_table();

/**
 * Self-healing UTF-8 migration.
 *
 * Tamil (and any non-Latin) text is stored as "?" whenever the database, table
 * or column charset is latin1 — MySQL replaces every character it cannot encode.
 * Shared hosts often default new schemas to latin1, so the tables created there
 * silently lose Tamil even though the PDO connection already speaks utf8mb4.
 *
 * This walks the current schema once and converts anything that is not utf8mb4.
 * A marker file keeps it from re-running information_schema on every request.
 */
function ensure_utf8mb4_charset(): void
{
    static $ran = false;
    if ($ran) return;
    $ran = true;

    $report = ['status' => 'skipped', 'converted' => [], 'fks_restored' => 0, 'errors' => []];

    $marker = sys_get_temp_dir() . '/rrgroups_utf8mb4_' . md5(__DIR__) . '.ok';
    if (is_file($marker)) {
        $report['status'] = 'already-done';
        $GLOBALS['utf8mb4_migration'] = $report;
        return;
    }

    try {
        $pdo = Database::pdo();
    } catch (\Throwable $e) {
        $report['status'] = 'no-db';
        $GLOBALS['utf8mb4_migration'] = $report;
        return;
    }

    // Any text column that is not utf8mb4 will mangle Tamil and the rupee sign.
    try {
        $bad = $pdo->query(
            "SELECT DISTINCT TABLE_NAME FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND CHARACTER_SET_NAME IS NOT NULL
               AND CHARACTER_SET_NAME <> 'utf8mb4'"
        )->fetchAll(PDO::FETCH_COLUMN);
    } catch (\Throwable $e) {
        $report['status'] = 'inspect-failed';
        $report['errors']['inspect'] = $e->getMessage();
        $GLOBALS['utf8mb4_migration'] = $report;
        return;
    }

    if (!$bad) {
        $report['status'] = 'ok';
        $GLOBALS['utf8mb4_migration'] = $report;
        @file_put_contents($marker, date('c'));
        return;
    }

    // Shared hosts often withhold schema-level ALTER. That only changes the
    // default for FUTURE tables, so it must never block the conversion below.
    try {
        $dbDefault = $pdo->query(
            "SELECT DEFAULT_CHARACTER_SET_NAME FROM information_schema.SCHEMATA
             WHERE SCHEMA_NAME = DATABASE()"
        )->fetchColumn();
        if ($dbDefault !== 'utf8mb4') {
            $pdo->exec('ALTER DATABASE `' . $pdo->query('SELECT DATABASE()')->fetchColumn()
                . '` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
        }
    } catch (\Throwable $e) {
        $report['errors']['alter_database'] = $e->getMessage();
    }

    // MariaDB refuses to re-charset a column that sits in a foreign key
    // (errno 1832/1833) and SET FOREIGN_KEY_CHECKS=0 does NOT waive it — unlike
    // MySQL 8. So capture every constraint, drop them, convert, put them back.
    $fks = [];
    try {
        $rows = $pdo->query(
            "SELECT rc.CONSTRAINT_NAME, rc.TABLE_NAME, rc.REFERENCED_TABLE_NAME,
                    rc.UPDATE_RULE, rc.DELETE_RULE
             FROM information_schema.REFERENTIAL_CONSTRAINTS rc
             WHERE rc.CONSTRAINT_SCHEMA = DATABASE()"
        )->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as $r) {
            $cols = $pdo->prepare(
                "SELECT COLUMN_NAME, REFERENCED_COLUMN_NAME
                 FROM information_schema.KEY_COLUMN_USAGE
                 WHERE CONSTRAINT_SCHEMA = DATABASE()
                   AND CONSTRAINT_NAME = ? AND TABLE_NAME = ?
                 ORDER BY ORDINAL_POSITION"
            );
            $cols->execute([$r['CONSTRAINT_NAME'], $r['TABLE_NAME']]);
            $pairs = $cols->fetchAll(PDO::FETCH_ASSOC);
            if (!$pairs) continue;
            $r['cols'] = array_column($pairs, 'COLUMN_NAME');
            $r['refs'] = array_column($pairs, 'REFERENCED_COLUMN_NAME');
            $fks[] = $r;
        }
    } catch (\Throwable $e) {
        $report['errors']['read_foreign_keys'] = $e->getMessage();
    }

    $quote = function (array $names): string {
        return '`' . implode('`, `', $names) . '`';
    };

    // Drop first so every table below is free to change charset.
    $dropped = [];
    foreach ($fks as $fk) {
        try {
            $pdo->exec("ALTER TABLE `{$fk['TABLE_NAME']}` DROP FOREIGN KEY `{$fk['CONSTRAINT_NAME']}`");
            $dropped[] = $fk;
        } catch (\Throwable $e) {
            $report['errors']['drop_fk_' . $fk['CONSTRAINT_NAME']] = $e->getMessage();
        }
    }

    $failed = false;
    try {
        foreach ($bad as $table) {
            try {
                // CONVERT TO rewrites every text column in the table in one pass.
                $pdo->exec("ALTER TABLE `$table` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
                $report['converted'][] = $table;
            } catch (\Throwable $e) {
                // One stubborn table must not strand the rest.
                $report['errors'][$table] = $e->getMessage();
                $failed = true;
            }
        }
    } finally {
        // Always put the constraints back, even if a conversion threw.
        foreach ($dropped as $fk) {
            try {
                $pdo->exec(
                    "ALTER TABLE `{$fk['TABLE_NAME']}` ADD CONSTRAINT `{$fk['CONSTRAINT_NAME']}`"
                    . " FOREIGN KEY (" . $quote($fk['cols']) . ")"
                    . " REFERENCES `{$fk['REFERENCED_TABLE_NAME']}` (" . $quote($fk['refs']) . ")"
                    . " ON DELETE {$fk['DELETE_RULE']} ON UPDATE {$fk['UPDATE_RULE']}"
                );
                $report['fks_restored']++;
            } catch (\Throwable $e) {
                $report['errors']['restore_fk_' . $fk['CONSTRAINT_NAME']] = $e->getMessage();
                $failed = true;
            }
        }
    }

    $report['status'] = $failed ? 'partial' : 'ok';
    $GLOBALS['utf8mb4_migration'] = $report;

    // Only stop re-checking once everything came out clean.
    if (!$failed) {
        @file_put_contents($marker, date('c'));
    }
}

ensure_utf8mb4_charset();
