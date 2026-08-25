<?php
// PDO connection singleton.

class Database
{
    private static ?PDO $pdo = null;

    public static function pdo(): PDO
    {
        if (self::$pdo instanceof PDO) {
            return self::$pdo;
        }
        $d = config('db');
        $charset = !empty($d['charset']) ? $d['charset'] : 'utf8mb4';
        $dsn = "mysql:host={$d['host']};port={$d['port']};dbname={$d['name']};charset={$charset}";
        try {
            self::$pdo = new PDO($dsn, $d['user'], $d['pass'], [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci",
            ]);
            self::$pdo->exec("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci");
            self::$pdo->exec("SET CHARACTER SET utf8mb4");
            try {
                self::$pdo->exec("SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''))");
            } catch (Throwable $e) {
                // Ignore if not supported
            }
        } catch (PDOException $e) {
            json_error('Database connection failed: ' . $e->getMessage(), 500);
        }
        return self::$pdo;
    }
}
