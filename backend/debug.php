<?php
// ============================================================
//  RR Groups — Server Diagnostic Tool
//  Open: https://rrgroupscbe.com/backend/debug.php
//  Shows the EXACT error for every failing endpoint.
// ============================================================
error_reporting(E_ALL);
ini_set('display_errors', 0);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$results = ['timestamp' => date('c'), 'php_version' => phpversion()];

// 1. Config
try {
    $cfg = require __DIR__ . '/config.php';
    $results['config'] = [
        'db_host' => $cfg['db']['host'] ?? '?',
        'db_name' => $cfg['db']['name'] ?? '?',
        'db_user' => $cfg['db']['user'] ?? '?',
        'db_port' => $cfg['db']['port'] ?? '?',
    ];
} catch (\Throwable $e) {
    $results['config_error'] = $e->getMessage();
}

// 2. Database connection
try {
    $d = $cfg['db'];
    $dsn = "mysql:host={$d['host']};port={$d['port']};dbname={$d['name']};charset={$d['charset']}";
    $pdo = new PDO($dsn, $d['user'], $d['pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    $results['db_connection'] = 'OK';
    $results['db_server'] = $pdo->getAttribute(PDO::ATTR_SERVER_VERSION);
} catch (\Throwable $e) {
    $results['db_connection'] = 'FAILED';
    $results['db_error'] = $e->getMessage();
    echo json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit;
}

// 3. List tables
try {
    $tables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    $results['tables_found'] = $tables;
    $results['table_count'] = count($tables);
} catch (\Throwable $e) {
    $results['tables_error'] = $e->getMessage();
}

// 4. Check required tables
$required = [
    'profiles', 'customers', 'loans', 'repayment_schedule', 'collections',
    'chit_groups', 'chit_members', 'chit_schedules', 'funds', 'fund_payments',
    'handovers', 'notifications', 'settings', 'push_subscriptions',
    'biometric_credentials', 'account_ledger', 'promo_popups'
];
$missing = [];
foreach ($required as $t) {
    if (!in_array($t, $tables ?? [])) {
        $missing[] = $t;
    }
}
$results['missing_tables'] = $missing;

// 5. Check profiles columns
try {
    $cols = $pdo->query("SHOW COLUMNS FROM profiles")->fetchAll(PDO::FETCH_COLUMN, 0);
    $results['profiles_columns'] = $cols;
    $results['has_user_code'] = in_array('user_code', $cols);
} catch (\Throwable $e) {
    $results['profiles_columns_error'] = $e->getMessage();
}

// 6. Check admin user exists
try {
    $stmt = $pdo->prepare("SELECT id, email, full_name, role, status, user_code FROM profiles WHERE email = ?");
    $stmt->execute(['admin@fincollect.in']);
    $admin = $stmt->fetch();
    $results['admin_user'] = $admin ?: 'NOT FOUND';
} catch (\Throwable $e) {
    $results['admin_user_error'] = $e->getMessage();
}

// 7. Check settings row
try {
    $row = $pdo->query("SELECT id, company_name FROM settings LIMIT 1")->fetch();
    $results['settings_row'] = $row ?: 'NO ROWS — need to seed';
} catch (\Throwable $e) {
    $results['settings_error'] = $e->getMessage();
}

// 8. Test bootstrap.php loading
try {
    ob_start();
    require_once __DIR__ . '/bootstrap.php';
    ob_end_clean();
    $results['bootstrap'] = 'OK';
} catch (\Throwable $e) {
    ob_end_clean();
    $results['bootstrap_error'] = $e->getMessage() . ' at ' . $e->getFile() . ':' . $e->getLine();
}

// 9. Test Model autoloading
$modelTests = ['Setting', 'PromoPopup', 'Loan', 'Profile'];
foreach ($modelTests as $cls) {
    try {
        if (class_exists($cls)) {
            $results["model_{$cls}"] = 'OK';
        } else {
            $results["model_{$cls}"] = 'CLASS NOT FOUND';
        }
    } catch (\Throwable $e) {
        $results["model_{$cls}_error"] = $e->getMessage();
    }
}

// 10. Test actual queries that are failing
$testQueries = [
    'settings_select'     => "SELECT * FROM settings LIMIT 1",
    'promo_popups_select' => "SELECT * FROM promo_popups WHERE is_active = 1 ORDER BY created_at DESC LIMIT 1",
    'loans_select'        => "SELECT * FROM loans LIMIT 5",
    'profiles_select'     => "SELECT id, email, role FROM profiles LIMIT 5",
];
foreach ($testQueries as $name => $sql) {
    try {
        $stmt = $pdo->query($sql);
        $rows = $stmt->fetchAll();
        $results["query_{$name}"] = ['status' => 'OK', 'row_count' => count($rows)];
    } catch (\Throwable $e) {
        $results["query_{$name}"] = ['status' => 'FAILED', 'error' => $e->getMessage()];
    }
}

// 11. Test Controller instantiation
try {
    if (class_exists('ResourceController') && class_exists('SettingController')) {
        $results['controller_classes'] = 'OK';
    } else {
        $results['controller_classes'] = 'MISSING';
    }
} catch (\Throwable $e) {
    $results['controller_classes_error'] = $e->getMessage();
}

// 12. Check PHP file existence on server
$checkFiles = [
    'bootstrap.php', 'rest.php', 'auth.php', 'config.php',
    'core/Model.php', 'core/Controller.php', 'core/Database.php', 'core/QueryParser.php', 'core/Jwt.php',
    'controllers/ResourceController.php', 'controllers/SettingController.php',
    'controllers/PromoPopupController.php', 'controllers/LoanController.php',
    'controllers/AuthController.php',
    'models/Setting.php', 'models/PromoPopup.php', 'models/Loan.php', 'models/Profile.php',
];
$fileStatus = [];
foreach ($checkFiles as $f) {
    $path = __DIR__ . '/' . $f;
    $fileStatus[$f] = file_exists($path) ? filesize($path) . ' bytes' : 'MISSING';
}
$results['files'] = $fileStatus;

// 13. Check ResourceController method visibility
try {
    $rc = new ReflectionClass('ResourceController');
    $indexMethod = $rc->getMethod('index');
    $results['ResourceController_index_visibility'] = $indexMethod->isProtected() ? 'protected (CORRECT)' : ($indexMethod->isPrivate() ? 'private (BUG — needs protected)' : ($indexMethod->isPublic() ? 'public' : 'unknown'));
    
    $modelProp = $rc->getProperty('model');
    $results['ResourceController_model_visibility'] = $modelProp->isProtected() ? 'protected (CORRECT)' : ($modelProp->isPrivate() ? 'private (BUG — needs protected)' : 'unknown');
} catch (\Throwable $e) {
    $results['ResourceController_reflection_error'] = $e->getMessage();
}

echo json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
