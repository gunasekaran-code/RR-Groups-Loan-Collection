<?php
// ============================================================
//  RRGroups backend configuration
//  Adjust DB credentials to match your XAMPP MySQL setup.
// ============================================================

$hostHeader = explode(':', $_SERVER['HTTP_HOST'] ?? '')[0];
$isLocal = in_array($hostHeader, ['localhost', '127.0.0.1', '::1'], true)
    || (php_sapi_name() === 'cli' && (stripos(PHP_OS, 'WIN') !== false || file_exists('D:\\xampp')));

$dbConfig = $isLocal ? [
    'host'    => getenv('DB_HOST') ?: '127.0.0.1',
    'port'    => (int)(getenv('DB_PORT') ?: 3306),
    'name'    => getenv('DB_NAME') ?: 'rrgroups',
    'user'    => getenv('DB_USER') ?: 'root',
    'pass'    => getenv('DB_PASS') !== false ? getenv('DB_PASS') : 'anantha',
    'charset' => 'utf8mb4',
] : [
    'host'    => getenv('DB_HOST') ?: '127.0.0.1',
    'port'    => (int)(getenv('DB_PORT') ?: 3306),
    'name'    => getenv('DB_NAME') ?: 'cwhycofr_RRgroups',
    'user'    => getenv('DB_USER') ?: 'cwhycofr_rrgroups',
    'pass'    => getenv('DB_PASS') !== false ? getenv('DB_PASS') : 'RRgroups@123',
    'charset' => 'utf8mb4',
];

return [
    'db' => $dbConfig,

    // Secret used to sign JWTs. CHANGE THIS to a long random string in production.
    'jwt_secret' => getenv('JWT_SECRET') ?: 'rrgroups-dev-secret-change-me-6f2a9c1e8b4d',
    'jwt_ttl'    => 60 * 60 * 24 * 7,   // 7 days

    // Allowed CORS origins. Use '*' to allow all origins during development & production.
    'cors_origins' => ['*'],

    // ---- Email (SMTP) for OTP delivery ----
    // For Gmail: host=smtp.gmail.com, port=587, username=<your gmail>,
    // password=<16-char App Password from Google Account > Security > App passwords>.
    // Leave username/password empty to disable email (falls back to demo OTP).
    'smtp' => [
        'host'       => getenv('SMTP_HOST') ?: 'smtp.gmail.com',
        'port'       => (int)(getenv('SMTP_PORT') ?: 587),
        'username'   => getenv('SMTP_USER') ?: 'rrgroups624@gmail.com',   // e.g. yourname@gmail.com
        'password'   => getenv('SMTP_PASS') ?: 'etzy hrqm zmis dwnn',   // 16-char Google App Password (NOT your normal password)
        'from_email' => getenv('SMTP_FROM_EMAIL') ?: 'rrgroups624@gmail.com',   // usually same as username
        'from_name'  => getenv('SMTP_FROM_NAME') ?: 'RR Groups',
    ],

    // ---- SMS gateway for OTP delivery ----
    // provider: 'fast2sms' | 'msg91' | '' (empty disables SMS -> demo fallback).
    'sms' => [
        'provider'    => getenv('SMS_PROVIDER') ?: '',    // 'fast2sms' or 'msg91' — empty disables SMS (email-only OTP)
        'api_key'     => getenv('SMS_API_KEY') ?: '',     // gateway API key / authkey
        'sender_id'   => getenv('SMS_SENDER_ID') ?: '',   // approved sender ID (msg91) — optional for fast2sms
        'template_id' => getenv('SMS_TEMPLATE_ID') ?: '', // DLT template id (msg91) — optional
    ],
];
