<?php
// ============================================================
//  RRGroups backend configuration
//  Adjust DB credentials to match your XAMPP MySQL setup.
// ============================================================

return [
    // 'db' => [
    //     'host'    => '127.0.0.1',
    //     'port'    => 3306,
    //     'name'    => 'rrgroups',
    //     'user'    => 'root',
    //     'pass'    => 'anantha',   // must match the app user in schema.sql
    //     'charset' => 'utf8mb4',
    // ],

    'db' => [
        'host'    => '127.0.0.1',
        'port'    => 8889,
        'name'    => 'rrgroups',
        'user'    => 'root',
        'pass'    => 'root',
        'charset' => 'utf8mb4',
    ],

    // Secret used to sign JWTs. CHANGE THIS to a long random string in production.
    'jwt_secret' => 'rrgroups-dev-secret-change-me-6f2a9c1e8b4d',
    'jwt_ttl'    => 60 * 60 * 24 * 7,   // 7 days

    // Allowed CORS origins (Vite dev server). Use '*' to allow all during dev.
    'cors_origins' => [
        'http://localhost:5173',
        'http://127.0.0.1:5173',
    ],

    // ---- Email (SMTP) for OTP delivery ----
    // For Gmail: host=smtp.gmail.com, port=587, username=<your gmail>,
    // password=<16-char App Password from Google Account > Security > App passwords>.
    // Leave username/password empty to disable email (falls back to demo OTP).
    'smtp' => [
        'host'       => 'smtp.gmail.com',
        'port'       => 587,
        'username'   => 'rrgroups624@gmail.com',   // e.g. yourname@gmail.com
        'password'   => 'etzy hrqm zmis dwnn',   // 16-char Google App Password (NOT your normal password)
        'from_email' => 'rrgroups624@gmail.com',   // usually same as username
        'from_name'  => 'RR Groups',
    ],

    // ---- SMS gateway for OTP delivery ----
    // provider: 'fast2sms' | 'msg91' | '' (empty disables SMS -> demo fallback).
    'sms' => [
        'provider'  => '',    // 'fast2sms' or 'msg91' — empty disables SMS (email-only OTP)
        'api_key'   => '',    // gateway API key / authkey
        'sender_id' => '',    // approved sender ID (msg91) — optional for fast2sms
        'template_id' => '',  // DLT template id (msg91) — optional
    ],
];
