<?php
// ============================================================
//  Bootstrap: config, PSR-style autoloader, and HTTP helpers.
//  Every entry point (auth.php, rest.php, users.php) requires this.
// ============================================================

$GLOBALS['app_config'] = require __DIR__ . '/config.php';

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
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
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
    $raw = file_get_contents('php://input');
    if ($raw === '' || $raw === false) {
        return [];
    }
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function bearer_token(): ?string
{
    $hdr = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!$hdr && function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        $hdr = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    }
    if (preg_match('/Bearer\s+(.+)/i', $hdr, $m)) {
        return trim($m[1]);
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
