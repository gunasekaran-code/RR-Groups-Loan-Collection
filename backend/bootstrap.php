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

function json_out($data, int $status = 200): void
{
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($data);
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
                ) ENGINE=InnoDB
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

ensure_chit_schedules_table();
ensure_funds_units_column();
ensure_popup_settings_columns();

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
        ) ENGINE=InnoDB");
    } catch (\Throwable $e) {
        // Silently ignore schema check errors
    }
}
ensure_promo_popups_table();
