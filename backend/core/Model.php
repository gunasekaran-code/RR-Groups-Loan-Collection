<?php
// Base data model: schema introspection, type casting, and CRUD builders.
// Concrete models set $table (and optionally $hidden).

abstract class Model
{
    protected static string $table = '';
    /** Columns never returned to clients (e.g. password_hash). */
    protected static array $hidden = [];

    /** table name => model class, used by rest.php to resolve ?table=. */
    private const REGISTRY = [
        'profiles'           => Profile::class,
        'customers'          => Customer::class,
        'loans'              => Loan::class,
        'repayment_schedule' => RepaymentSchedule::class,
        'collections'        => Collection::class,
        'chit_groups'        => ChitGroup::class,
        'chit_members'       => ChitMember::class,
        'funds'              => Fund::class,
        'fund_payments'      => FundPayment::class,
        'notifications'      => Notification::class,
        'settings'           => Setting::class,
        'push_subscriptions' => PushSubscription::class,
    ];

    public static function forTable(string $table): ?string
    {
        return self::REGISTRY[$table] ?? null;
    }

    public static function table(): string
    {
        return static::$table;
    }

    /** column name => MySQL type string (cached per table). */
    public static function columns(): array
    {
        static $cache = [];
        $t = static::$table;
        if (!isset($cache[$t])) {
            $rows = Database::pdo()->query("SHOW COLUMNS FROM `$t`")->fetchAll();
            $cols = [];
            foreach ($rows as $r) {
                $cols[$r['Field']] = strtolower($r['Type']);
            }
            $cache[$t] = $cols;
        }
        return $cache[$t];
    }

    /** Cast numeric columns to real numbers and drop hidden columns. */
    public static function castRows(array $rows): array
    {
        $types = static::columns();
        $hidden = static::$hidden;
        return array_map(function ($row) use ($types, $hidden) {
            foreach ($hidden as $h) {
                unset($row[$h]);
            }
            foreach ($row as $k => $v) {
                if ($v === null || !isset($types[$k])) continue;
                $t = $types[$k];
                if (str_starts_with($t, 'decimal') || str_starts_with($t, 'float') || str_starts_with($t, 'double')) {
                    $row[$k] = (float)$v;
                } elseif (str_starts_with($t, 'int') || str_starts_with($t, 'bigint')
                       || str_starts_with($t, 'smallint') || str_starts_with($t, 'mediumint')
                       || str_starts_with($t, 'tinyint')) {
                    $row[$k] = (int)$v;
                }
            }
            return $row;
        }, $rows);
    }

    private static function coerce($v)
    {
        if (is_bool($v)) return $v ? 1 : 0;
        if (is_array($v)) return json_encode($v);
        return $v;
    }

    /**
     * Coerce a value for a specific column type. Converts JavaScript ISO 8601
     * datetimes (e.g. "2026-07-16T10:20:30.123Z") into MySQL's expected
     * "Y-m-d H:i:s" / "Y-m-d" so strict mode accepts them.
     */
    private static function normalize($v, string $type)
    {
        $v = self::coerce($v);
        if (is_string($v) && $v !== '') {
            if (str_starts_with($type, 'datetime') || str_starts_with($type, 'timestamp')) {
                if (strpbrk($v, 'TZ') !== false) {
                    $ts = strtotime($v);
                    if ($ts !== false) return date('Y-m-d H:i:s', $ts);
                }
            } elseif (str_starts_with($type, 'date') && strpos($v, 'T') !== false) {
                return substr($v, 0, 10);
            }
        }
        return $v;
    }

    /** SELECT with pre-built WHERE/ORDER/LIMIT fragments. Returns cast rows. */
    public static function select(string $where, array $binds, string $order = '', string $limit = ''): array
    {
        $stmt = Database::pdo()->prepare("SELECT * FROM `" . static::$table . "`$where$order$limit");
        $stmt->execute($binds);
        return static::castRows($stmt->fetchAll());
    }

    /** Raw first row INCLUDING hidden columns (used for auth). */
    public static function firstRaw(string $where, array $binds): ?array
    {
        $stmt = Database::pdo()->prepare("SELECT * FROM `" . static::$table . "`$where LIMIT 1");
        $stmt->execute($binds);
        return $stmt->fetch() ?: null;
    }

    /**
     * Insert one or many rows. Generates a UUID id when the table has an id
     * column and none is supplied. Returns the inserted rows (cast).
     */
    public static function insertRows(array $rows, bool $upsert = false): array
    {
        $columns = static::columns();
        $pdo = Database::pdo();
        $ids = [];
        foreach ($rows as $row) {
            if (!is_array($row)) continue;
            $data = [];
            foreach ($row as $k => $v) {
                if (isset($columns[$k])) $data[$k] = self::normalize($v, $columns[$k]);
            }
            if (isset($columns['id']) && empty($data['id'])) {
                $data['id'] = uuid4();
            }
            if (!$data) {
                json_error('No valid columns to insert', 400);
            }
            $cols = array_keys($data);
            $ph = implode(',', array_fill(0, count($cols), '?'));
            $colList = implode(',', array_map(fn($c) => "`$c`", $cols));
            $sql = "INSERT INTO `" . static::$table . "` ($colList) VALUES ($ph)";
            if ($upsert) {
                $updates = implode(',', array_map(fn($c) => "`$c` = VALUES(`$c`)", $cols));
                $sql .= " ON DUPLICATE KEY UPDATE $updates";
            }
            $pdo->prepare($sql)->execute(array_values($data));
            $ids[] = $data['id'] ?? $pdo->lastInsertId();
        }
        if (!$ids || !isset($columns['id'])) {
            return [];
        }
        $ph = implode(',', array_fill(0, count($ids), '?'));
        return static::select(" WHERE `id` IN ($ph)", $ids);
    }

    /** UPDATE rows matching $where with $data. Returns updated rows (cast). */
    public static function updateWhere(array $data, string $where, array $binds): array
    {
        $columns = static::columns();
        $set = [];
        $setBinds = [];
        foreach ($data as $k => $v) {
            if (isset($columns[$k])) {
                $set[] = "`$k` = ?";
                $setBinds[] = self::normalize($v, $columns[$k]);
            }
        }
        if (!$set) {
            json_error('No valid columns to update', 400);
        }
        $sql = "UPDATE `" . static::$table . "` SET " . implode(', ', $set) . $where;
        Database::pdo()->prepare($sql)->execute([...$setBinds, ...$binds]);
        return static::select($where, $binds);
    }

    public static function deleteWhere(string $where, array $binds): void
    {
        Database::pdo()->prepare("DELETE FROM `" . static::$table . "`$where")->execute($binds);
    }
}
