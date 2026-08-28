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
 * Per-contribution chit passbook ledger.
 *
 * Before this table existed the only record of a chit contribution was the
 * free-text account_ledger receipt, and the customer passbook had to find its
 * own payments by substring-matching the member and group name inside that
 * text. That silently cross-matched similar names and broke whenever a group
 * or member was renamed. chit_payments stores the link as real foreign keys.
 */
function ensure_chit_payments_table(): void
{
    static $ran = false;
    if ($ran) return;
    $ran = true;

    try {
        $pdo = Database::pdo();
        $hasTable = (int)$pdo->query(
            "SELECT COUNT(*) FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'chit_payments'"
        )->fetchColumn();

        if (!$hasTable) {
            $pdo->exec("
                CREATE TABLE chit_payments (
                  id             CHAR(36)     NOT NULL PRIMARY KEY,
                  group_id       CHAR(36)     NOT NULL,
                  member_id      CHAR(36)     NULL,
                  group_number   VARCHAR(64)  NULL,
                  group_name     VARCHAR(191) NULL,
                  customer_id    CHAR(36)     NULL,
                  customer_name  VARCHAR(191) NULL,
                  installment_no INT          NOT NULL DEFAULT 0,
                  amount         DECIMAL(14,2) NOT NULL DEFAULT 0,
                  balance_after  DECIMAL(14,2) NOT NULL DEFAULT 0,
                  payment_method ENUM('cash','upi','card','bank','cheque') NOT NULL DEFAULT 'cash',
                  payment_date   DATE         NULL,
                  agent_id       CHAR(36)     NULL,
                  agent_name     VARCHAR(191) NULL,
                  ledger_id      CHAR(36)     NULL,
                  notes          TEXT         NULL,
                  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_chit_payments_group (group_id),
                  INDEX idx_chit_payments_member (member_id),
                  INDEX idx_chit_payments_customer (customer_id),
                  INDEX idx_chit_payments_ledger (ledger_id),
                  CONSTRAINT fk_chit_payments_group FOREIGN KEY (group_id)
                    REFERENCES chit_groups(id) ON DELETE CASCADE,
                  CONSTRAINT fk_chit_payments_member FOREIGN KEY (member_id)
                    REFERENCES chit_members(id) ON DELETE SET NULL
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            ");
        }

        backfill_chit_payments_from_ledger();
    } catch (\Throwable $e) {
        // Schema check failures must never take the API down.
    }
}

/**
 * Recover historic contributions that only exist as account_ledger receipts.
 *
 * Idempotent: a receipt is skipped once a chit_payments row references it, so
 * this can run on every deployment without duplicating money. Receipts whose
 * group or member cannot be resolved are left behind rather than guessed at —
 * they stay visible in the Account Book either way.
 */
function backfill_chit_payments_from_ledger(): void
{
    $pdo = Database::pdo();

    $rows = $pdo->query(
        "SELECT l.id, l.title, l.notes, l.amount, l.entry_date, l.agent_id, l.agent_name, l.payment_method
         FROM account_ledger l
         LEFT JOIN chit_payments p ON p.ledger_id = l.id
         WHERE LOWER(l.category) LIKE '%chit%' AND p.id IS NULL"
    )->fetchAll(PDO::FETCH_ASSOC);

    if (!$rows) return;

    $groups  = $pdo->query("SELECT id, group_name, group_number FROM chit_groups")->fetchAll(PDO::FETCH_ASSOC);
    $members = $pdo->query("SELECT id, group_id, customer_id, member_name FROM chit_members")->fetchAll(PDO::FETCH_ASSOC);

    $ins = $pdo->prepare(
        "INSERT INTO chit_payments
           (id, group_id, member_id, group_number, group_name, customer_id, customer_name,
            installment_no, amount, balance_after, payment_method, payment_date,
            agent_id, agent_name, ledger_id, notes)
         VALUES (?,?,?,?,?,?,?,0,?,0,?,?,?,?,?,?)"
    );

    $touched = [];
    foreach ($rows as $r) {
        $haystack = strtolower(trim(($r['title'] ?? '') . ' ' . ($r['notes'] ?? '')));
        if ($haystack === '') continue;

        // Resolve the group first — prefer the group number, which is unique.
        $group = null;
        foreach ($groups as $g) {
            $num = strtolower(trim((string)($g['group_number'] ?? '')));
            if ($num !== '' && strpos($haystack, $num) !== false) { $group = $g; break; }
        }
        if (!$group) {
            $best = 0;
            foreach ($groups as $g) {
                $name = strtolower(trim((string)($g['group_name'] ?? '')));
                if ($name !== '' && strpos($haystack, $name) !== false && strlen($name) > $best) {
                    $group = $g; $best = strlen($name);
                }
            }
        }
        if (!$group) continue;

        // Then the member, scoped to that group. Longest name wins so that
        // "Ramesh" cannot claim a receipt belonging to "Ramesh Kumar".
        $member = null; $best = 0;
        foreach ($members as $m) {
            if ($m['group_id'] !== $group['id']) continue;
            $name = strtolower(trim((string)($m['member_name'] ?? '')));
            if ($name !== '' && strpos($haystack, $name) !== false && strlen($name) > $best) {
                $member = $m; $best = strlen($name);
            }
        }
        if (!$member) continue;

        $method = strtolower(trim((string)($r['payment_method'] ?? 'cash')));
        if (!in_array($method, ['cash', 'upi', 'card', 'bank', 'cheque'], true)) $method = 'cash';

        $ins->execute([
            uuid4(),
            $group['id'],
            $member['id'],
            $group['group_number'] ?? null,
            $group['group_name'] ?? null,
            $member['customer_id'] ?? null,
            $member['member_name'] ?? null,
            (float)($r['amount'] ?? 0),
            $method,
            $r['entry_date'] ?: null,
            $r['agent_id'] ?? null,
            $r['agent_name'] ?? null,
            $r['id'],
            'Recovered from account book receipt during chit_payments migration.',
        ]);
        $touched[$member['id']] = true;
    }

    // Rebuild the running balance for every member the backfill touched.
    $sel = $pdo->prepare(
        "SELECT id, amount FROM chit_payments
         WHERE member_id = ? ORDER BY payment_date IS NULL, payment_date ASC, created_at ASC, id ASC"
    );
    $upd = $pdo->prepare("UPDATE chit_payments SET balance_after = ? WHERE id = ?");
    foreach (array_keys($touched) as $memberId) {
        $sel->execute([$memberId]);
        $running = 0.0;
        foreach ($sel->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $running = round($running + (float)$row['amount'], 2);
            $upd->execute([$running, $row['id']]);
        }
    }
}

ensure_chit_payments_table();

/**
 * Soft-delete archive backing the admin Recycle Bin.
 *
 * Carries no foreign keys on purpose: it has to survive the deletion of the
 * very rows it describes, and the utf8mb4 migration drops and recreates every
 * FK in the schema — one fewer constraint to juggle there.
 */
function ensure_recycle_bin_table(): void
{
    static $ran = false;
    if ($ran) return;
    $ran = true;

    try {
        $pdo = Database::pdo();
        $hasTable = (int)$pdo->query(
            "SELECT COUNT(*) FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'recycle_bin'"
        )->fetchColumn();
        if ($hasTable) return;

        $pdo->exec("
            CREATE TABLE recycle_bin (
              id              CHAR(36)     NOT NULL PRIMARY KEY,
              table_name      VARCHAR(64)  NOT NULL,
              record_id       VARCHAR(64)  NULL,
              label           VARCHAR(255) NULL,
              payload         LONGTEXT     NOT NULL,
              child_count     INT          NOT NULL DEFAULT 0,
              deleted_by      CHAR(36)     NULL,
              deleted_by_name VARCHAR(191) NULL,
              deleted_by_role VARCHAR(32)  NULL,
              deleted_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
              restored_at     DATETIME     NULL,
              INDEX idx_recycle_table (table_name),
              INDEX idx_recycle_deleted_at (deleted_at),
              INDEX idx_recycle_actor (deleted_by)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } catch (\Throwable $e) {
        // Never take the API down over a schema check.
    }
}

ensure_recycle_bin_table();

/**
 * Soft-delete flag on customers.
 *
 * A customer cannot simply be removed: loans, collections, funds and chit
 * membership all point at them, and wiping the row would either orphan or
 * erase real financial history. delflag = 1 hides them everywhere instead.
 */
function ensure_customer_delflag(): void
{
    static $ran = false;
    if ($ran) return;
    $ran = true;

    try {
        $pdo = Database::pdo();
        $cols = $pdo->query("SHOW COLUMNS FROM customers")->fetchAll(PDO::FETCH_COLUMN, 0);
        if (!in_array('delflag', $cols, true)) {
            $pdo->exec("ALTER TABLE customers ADD COLUMN delflag TINYINT(1) NOT NULL DEFAULT 0");
            $pdo->exec("ALTER TABLE customers ADD INDEX idx_customers_delflag (delflag)");
        }
        if (!in_array('deleted_at', $cols, true)) {
            $pdo->exec("ALTER TABLE customers ADD COLUMN deleted_at DATETIME NULL");
        }
        if (!in_array('deleted_by', $cols, true)) {
            $pdo->exec("ALTER TABLE customers ADD COLUMN deleted_by CHAR(36) NULL");
        }
    } catch (\Throwable $e) {
        // A schema check must never take the API down.
    }
}

ensure_customer_delflag();

/**
 * Tables carrying the soft-delete flag.
 *
 * recycle_bin is deliberately absent: it IS the archive, and "Empty Recycle
 * Bin" has to mean the records are gone. Flagging rows there would leave the
 * bin permanently full and give the admin no way to actually purge anything.
 */
const SOFT_DELETE_TABLES = [
    'account_ledger', 'biometric_credentials', 'chit_groups', 'chit_members',
    'chit_payments', 'chit_schedules', 'collections', 'customers',
    'fund_payments', 'funds', 'handovers', 'loans', 'notifications',
    'profiles', 'promo_popups', 'push_subscriptions', 'repayment_schedule',
    'settings',
];

/**
 * Add delflag / deleted_at / deleted_by everywhere.
 *
 * 0 = active, 1 = deleted. Rows are flagged rather than removed so that the
 * financial trail — loans against a customer, collections against a loan,
 * contributions against a chit member — survives a deletion anywhere above it.
 */
function ensure_soft_delete_columns(): void
{
    static $ran = false;
    if ($ran) return;
    $ran = true;

    try {
        $pdo = Database::pdo();

        $existing = $pdo->query(
            "SELECT TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND COLUMN_NAME IN ('delflag','deleted_at','deleted_by')"
        )->fetchAll(PDO::FETCH_ASSOC);

        $have = [];
        foreach ($existing as $r) {
            $have[$r['TABLE_NAME']][$r['COLUMN_NAME']] = true;
        }

        $tables = $pdo->query(
            "SELECT TABLE_NAME FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE'"
        )->fetchAll(PDO::FETCH_COLUMN, 0);

        foreach (SOFT_DELETE_TABLES as $table) {
            if (!in_array($table, $tables, true)) continue;

            // Each ALTER is guarded on its own: a shared host that refuses one
            // must not stop the rest from being added.
            if (empty($have[$table]['delflag'])) {
                try {
                    $pdo->exec("ALTER TABLE `$table` ADD COLUMN delflag TINYINT(1) NOT NULL DEFAULT 0");
                    $pdo->exec("ALTER TABLE `$table` ADD INDEX idx_{$table}_delflag (delflag)");
                } catch (\Throwable $e) {}
            }
            if (empty($have[$table]['deleted_at'])) {
                try { $pdo->exec("ALTER TABLE `$table` ADD COLUMN deleted_at DATETIME NULL"); } catch (\Throwable $e) {}
            }
            if (empty($have[$table]['deleted_by'])) {
                try { $pdo->exec("ALTER TABLE `$table` ADD COLUMN deleted_by CHAR(36) NULL"); } catch (\Throwable $e) {}
            }
        }
    } catch (\Throwable $e) {
        // A schema check must never take the API down.
    }
}

ensure_soft_delete_columns();

/**
 * `customers.loan_status` was only ever written by seed.php, so every
 * customer created through the app has been stuck on 'none' — the directory
 * showed "No Loan" next to people holding live loans. It is maintained
 * going forward by Customer::recalcLoanStatus(); this corrects the rows
 * that are already wrong.
 */
function backfill_customer_loan_status(): void
{
    static $ran = false;
    if ($ran) return;
    $ran = true;

    $marker = sys_get_temp_dir() . '/rrgroups_loanstatus_' . md5(__DIR__) . '.ok';
    if (is_file($marker)) return;

    try {
        Customer::recalcLoanStatus(null);
        @file_put_contents($marker, date('c'));
    } catch (\Throwable $e) {
        // Retry on the next request rather than taking the API down.
    }
}

backfill_customer_loan_status();

/** True when $table carries the soft-delete flag (cached per request). */
function table_has_delflag(string $table): bool
{
    static $cache = null;
    if ($cache === null) {
        $cache = [];
        try {
            $rows = Database::pdo()->query(
                "SELECT TABLE_NAME FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE() AND COLUMN_NAME = 'delflag'"
            )->fetchAll(PDO::FETCH_COLUMN, 0);
            foreach ($rows as $t) $cache[$t] = true;
        } catch (\Throwable $e) {
            $cache = [];
        }
    }
    return !empty($cache[$table]);
}

/**
 * UNIQUE columns that must be released when a row is soft-deleted.
 *
 * This is the trap in every soft-delete design: the row stays, so its UNIQUE
 * value stays claimed. A deleted customer's login email could never be used
 * again, and re-registering the same phone for push or the same passkey would
 * collide with a hidden row. Each value is tombstoned with the row id, which
 * keeps it unique while freeing the original.
 *
 * The recycle bin snapshot still holds the real value, so a restore puts it
 * back — and if someone has claimed it meanwhile, the restore fails loudly
 * instead of silently producing two accounts with one email.
 */
const SOFT_DELETE_UNIQUE_COLUMNS = [
    'profiles'              => ['email'],
    'push_subscriptions'    => ['endpoint'],
    'biometric_credentials' => ['credential_id'],
];

/**
 * Flag the rows the database would have removed by ON DELETE CASCADE.
 *
 * A hard DELETE on a chit group took its members, draws and payments with
 * it. Now that the parent is only flagged the cascade never fires, so the
 * children would stay visible — a deleted group's contributions would keep
 * showing in a member's passbook. This walks the same foreign keys and
 * flags them, so soft delete matches what hard delete used to do.
 */
function soft_delete_cascade(string $table, array $rows, ?string $actorId, int $depth = 0): void
{
    if ($depth >= 3 || !$rows) return;

    try {
        $pdo = Database::pdo();
        $links = $pdo->prepare(
            "SELECT k.TABLE_NAME, k.COLUMN_NAME
             FROM information_schema.REFERENTIAL_CONSTRAINTS rc
             JOIN information_schema.KEY_COLUMN_USAGE k
               ON k.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
              AND k.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
             WHERE rc.CONSTRAINT_SCHEMA = DATABASE()
               AND rc.REFERENCED_TABLE_NAME = ?
               AND rc.DELETE_RULE = 'CASCADE'"
        );
        $links->execute([$table]);
        $children = $links->fetchAll(PDO::FETCH_ASSOC);
        if (!$children) return;

        $now = date('Y-m-d H:i:s');
        foreach ($rows as $row) {
            $id = $row['id'] ?? null;
            if (!$id) continue;

            foreach ($children as $c) {
                $childTable = $c['TABLE_NAME'];
                $childCol   = $c['COLUMN_NAME'];
                if ($childTable === 'recycle_bin' || !table_has_delflag($childTable)) continue;

                $sel = $pdo->prepare("SELECT id FROM `$childTable` WHERE `$childCol` = ? AND delflag = 0");
                $sel->execute([$id]);
                $kids = $sel->fetchAll(PDO::FETCH_ASSOC);
                if (!$kids) continue;

                $pdo->prepare(
                    "UPDATE `$childTable` SET delflag = 1, deleted_at = ?, deleted_by = ?
                     WHERE `$childCol` = ? AND delflag = 0"
                )->execute([$now, $actorId, $id]);

                soft_delete_cascade($childTable, $kids, $actorId, $depth + 1);
            }
        }
    } catch (\Throwable $e) {
        // Never let the cascade block the delete the user asked for.
    }
}

/**
 * Tombstone the UNIQUE columns of rows about to be soft-deleted.
 * Call BEFORE flagging them, with the rows as they still are.
 */
function release_unique_columns(string $table, array $rows): void
{
    $columns = SOFT_DELETE_UNIQUE_COLUMNS[$table] ?? null;
    if (!$columns || !$rows) return;

    try {
        $pdo = Database::pdo();
        foreach ($rows as $row) {
            $id = $row['id'] ?? null;
            if (!$id) continue;

            foreach ($columns as $col) {
                $current = $row[$col] ?? null;
                if ($current === null || $current === '') continue;
                // Already tombstoned by an earlier delete — leave it alone.
                if (strncmp((string)$current, 'deleted:', 8) === 0) continue;

                $tomb = $col === 'email'
                    ? 'deleted+' . $id . '@deleted.invalid'
                    : 'deleted:' . $id . ':' . $current;

                $pdo->prepare("UPDATE `$table` SET `$col` = ? WHERE `id` = ?")
                    ->execute([$tomb, $id]);
            }
        }
    } catch (\Throwable $e) {
        // Freeing the value is a convenience; never block the delete over it.
    }
}

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
