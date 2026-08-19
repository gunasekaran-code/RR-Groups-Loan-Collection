<?php
// ============================================================
//  RRGroups backend configuration
//  Adjust DB credentials to match your setup.
// ============================================================

$hostHeader = explode(':', $_SERVER['HTTP_HOST'] ?? '')[0];
$isLocal = in_array($hostHeader, ['localhost', '127.0.0.1', '::1'], true)
    || (php_sapi_name() === 'cli' && (stripos(PHP_OS, 'WIN') !== false || file_exists('D:\\xampp')));

$dbConfig = $isLocal ? [
    'host'    => getenv('DB_HOST') ?: '127.0.0.1',
    'port'    => (int)(getenv('DB_PORT') ?: 8889),
    'name'    => getenv('DB_NAME') ?: 'rrgroups',
    'user'    => getenv('DB_USER') ?: 'root',
    'pass'    => getenv('DB_PASS') !== false ? getenv('DB_PASS') : 'root',
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
    'smtp' => [
        'host'       => getenv('SMTP_HOST') ?: 'smtp.gmail.com',
        'port'       => (int)(getenv('SMTP_PORT') ?: 587),
        'username'   => getenv('SMTP_USER') ?: 'rrgroups624@gmail.com',
        'password'   => getenv('SMTP_PASS') ?: 'etzy hrqm zmis dwnn',
        'from_email' => getenv('SMTP_FROM_EMAIL') ?: 'rrgroups624@gmail.com',
        'from_name'  => getenv('SMTP_FROM_NAME') ?: 'RR Groups',
    ],

    // ---- SMS gateway for OTP delivery ----
    'sms' => [
        'provider'    => getenv('SMS_PROVIDER') ?: '',
        'api_key'     => getenv('SMS_API_KEY') ?: '',
        'sender_id'   => getenv('SMS_SENDER_ID') ?: '',
        'template_id' => getenv('SMS_TEMPLATE_ID') ?: '',
    ],
];