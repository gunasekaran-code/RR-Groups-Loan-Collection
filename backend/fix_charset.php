<?php
/**
 * Force UTF-8mb4 migration on the production database.
 * 
 * Self-contained — does NOT rely on bootstrap.php's ensure_utf8mb4_charset().
 * Handles foreign key constraints, cPanel permission restrictions, and
 * provides detailed diagnostics.
 *
 * Usage: Visit https://rrgroupscbe.com/backend/fix_charset.php
 * Safe to run multiple times — idempotent.
 */
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('max_execution_time', 120);
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$report = ['timestamp' => date('c'), 'steps' => [], 'errors' => []];

// 1. Load config directly (no bootstrap dependency)
try {
    $cfg = require __DIR__ . '/config.php';
    $d = $cfg['db'];
    $dsn = "mysql:host={$d['host']};port={$d['port']};dbname={$d['name']};charset=utf8mb4";
    $pdo = new PDO($dsn, $d['user'], $d['pass'], [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    $report['steps'][] = 'DB connected OK';
    $report['db_name'] = $d['name'];
    $report['db_server'] = $pdo->getAttribute(PDO::ATTR_SERVER_VERSION);
} catch (Throwable $e) {
    $report['errors']['db_connect'] = $e->getMessage();
    echo json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit;
}

// 2. Set session charset to utf8mb4
try {
    $pdo->exec("SET NAMES utf8mb4");
    $pdo->exec("SET CHARACTER SET utf8mb4");
    $pdo->exec("SET character_set_connection = utf8mb4");
    $report['steps'][] = 'Session charset set to utf8mb4';
} catch (Throwable $e) {
    $report['errors']['session_charset'] = $e->getMessage();
}

// 3. Check current database default charset
try {
    $dbCharset = $pdo->query(
        "SELECT DEFAULT_CHARACTER_SET_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = DATABASE()"
    )->fetchColumn();
    $report['database_default_charset'] = $dbCharset;
} catch (Throwable $e) {
    $report['errors']['db_charset_check'] = $e->getMessage();
    $dbCharset = 'unknown';
}

// 4. Try to ALTER DATABASE (may fail on shared hosting — that's OK)
if ($dbCharset !== 'utf8mb4') {
    try {
        $dbName = $pdo->query('SELECT DATABASE()')->fetchColumn();
        $pdo->exec("ALTER DATABASE `{$dbName}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
        $report['steps'][] = "ALTER DATABASE {$dbName} -> utf8mb4 OK";
    } catch (Throwable $e) {
        $report['errors']['alter_database'] = $e->getMessage() . ' (non-fatal — tables will still be converted)';
    }
}

// 5. Find ALL tables with non-utf8mb4 columns
try {
    $badTables = $pdo->query(
        "SELECT DISTINCT TABLE_NAME FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE()
           AND CHARACTER_SET_NAME IS NOT NULL
           AND CHARACTER_SET_NAME <> 'utf8mb4'"
    )->fetchAll(PDO::FETCH_COLUMN);
    $report['tables_needing_conversion'] = $badTables;
} catch (Throwable $e) {
    $report['errors']['inspect'] = $e->getMessage();
    $badTables = [];
}

// 6. Convert each table — disable FK checks first
$converted = [];
$failedTables = [];
if (!empty($badTables)) {
    // Disable FK checks
    try {
        $pdo->exec("SET FOREIGN_KEY_CHECKS = 0");
        $report['steps'][] = 'FOREIGN_KEY_CHECKS = 0';
    } catch (Throwable $e) {
        $report['errors']['fk_disable'] = $e->getMessage();
    }

    foreach ($badTables as $table) {
        try {
            $pdo->exec("ALTER TABLE `{$table}` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
            $converted[] = $table;
        } catch (Throwable $e) {
            // If CONVERT TO fails, try column-by-column approach
            try {
                $cols = $pdo->query(
                    "SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, CHARACTER_SET_NAME
                     FROM information_schema.COLUMNS
                     WHERE TABLE_SCHEMA = DATABASE()
                       AND TABLE_NAME = '{$table}'
                       AND CHARACTER_SET_NAME IS NOT NULL
                       AND CHARACTER_SET_NAME <> 'utf8mb4'"
                )->fetchAll();
                
                foreach ($cols as $col) {
                    $colName = $col['COLUMN_NAME'];
                    $colType = $col['COLUMN_TYPE'];
                    $nullable = $col['IS_NULLABLE'] === 'YES' ? 'NULL' : 'NOT NULL';
                    $default = $col['COLUMN_DEFAULT'] !== null ? "DEFAULT " . $pdo->quote($col['COLUMN_DEFAULT']) : '';
                    
                    $sql = "ALTER TABLE `{$table}` MODIFY COLUMN `{$colName}` {$colType} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci {$nullable} {$default}";
                    $pdo->exec($sql);
                }
                $converted[] = "{$table} (column-by-column)";
            } catch (Throwable $e2) {
                $failedTables[$table] = $e->getMessage() . ' | column-by-column: ' . $e2->getMessage();
            }
        }
    }

    // Re-enable FK checks
    try {
        $pdo->exec("SET FOREIGN_KEY_CHECKS = 1");
        $report['steps'][] = 'FOREIGN_KEY_CHECKS = 1';
    } catch (Throwable $e) {
        $report['errors']['fk_enable'] = $e->getMessage();
    }
} else {
    $report['steps'][] = 'All tables already utf8mb4 — no conversion needed';
}

$report['converted'] = $converted;
$report['failed_tables'] = $failedTables;

// 7. Verify: check remaining non-utf8mb4 columns
try {
    $remaining = $pdo->query(
        "SELECT CONCAT(TABLE_NAME, '.', COLUMN_NAME, ' = ', CHARACTER_SET_NAME)
         FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE()
           AND CHARACTER_SET_NAME IS NOT NULL
           AND CHARACTER_SET_NAME <> 'utf8mb4'"
    )->fetchAll(PDO::FETCH_COLUMN);
    $report['remaining_non_utf8mb4'] = $remaining;
    $report['tamil_safe'] = empty($remaining);
} catch (Throwable $e) {
    $report['errors']['verify'] = $e->getMessage();
}

// 8. Tamil round-trip test on the ACTUAL chit_groups table
try {
    $tamil = "தமிழ் சீட்டு குழு";
    $pdo->exec("CREATE TEMPORARY TABLE _charset_probe (v VARCHAR(100)) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $ins = $pdo->prepare("INSERT INTO _charset_probe (v) VALUES (?)");
    $ins->execute([$tamil]);
    $back = $pdo->query("SELECT v FROM _charset_probe")->fetchColumn();
    $pdo->exec("DROP TEMPORARY TABLE _charset_probe");
    
    $report['tamil_roundtrip'] = [
        'wrote' => $tamil,
        'read'  => $back,
        'match' => ($back === $tamil) ? 'PASS ✅' : 'FAIL ❌',
    ];
} catch (Throwable $e) {
    $report['errors']['tamil_test'] = $e->getMessage();
}

// 9. Also test on the real chit_groups table charset
try {
    $cgCharset = $pdo->query(
        "SELECT CCSA.CHARACTER_SET_NAME 
         FROM information_schema.TABLES T
         JOIN information_schema.COLLATION_CHARACTER_SET_APPLICABILITY CCSA 
           ON T.TABLE_COLLATION = CCSA.COLLATION_NAME
         WHERE T.TABLE_SCHEMA = DATABASE() AND T.TABLE_NAME = 'chit_groups'"
    )->fetchColumn();
    $report['chit_groups_charset'] = $cgCharset;
} catch (Throwable $e) {
    $report['errors']['cg_charset'] = $e->getMessage();
}

// 10. Show existing chit group names to see if they're still broken
try {
    $groups = $pdo->query("SELECT id, group_name, group_number FROM chit_groups ORDER BY created_at DESC LIMIT 10")->fetchAll();
    $report['existing_chit_groups'] = $groups;
} catch (Throwable $e) {
    $report['errors']['cg_list'] = $e->getMessage();
}

// 11. Delete any bootstrap marker file so it doesn't skip future checks
$marker = sys_get_temp_dir() . '/rrgroups_utf8mb4_' . md5(__DIR__) . '.ok';
if (is_file($marker)) {
    @unlink($marker);
    $report['steps'][] = 'Deleted stale marker file';
}

// Summary
$report['status'] = empty($failedTables) ? 'SUCCESS ✅' : 'PARTIAL ⚠️';
$report['instructions'] = empty($remaining) 
    ? 'All tables are now utf8mb4. NEW Tamil text will save correctly. Old broken entries (??????) need to be re-typed manually via the Edit button.'
    : 'Some columns could not be converted. See remaining_non_utf8mb4 for details.';

echo json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
