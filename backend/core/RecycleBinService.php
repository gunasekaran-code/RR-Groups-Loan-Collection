<?php
// ============================================================
//  RecycleBinService — soft-delete archive for every table.
//
//  Every DELETE that goes through ResourceController is snapshotted here
//  first, whoever performed it (admin, agent, or customer). The admin panel
//  can then restore the record or purge it for good.
//
//  Two things this deliberately does NOT do the easy way:
//
//  1. It reads the doomed rows RAW, straight from PDO, rather than reusing the
//     model's cast rows. Model::select() strips $hidden columns, so archiving
//     those would silently drop profiles.password_hash and restore a user who
//     could never log in again.
//
//  2. It follows ON DELETE CASCADE foreign keys and archives the children too.
//     Deleting a chit group takes its members, schedules and payments with it
//     at the database level; restoring only the parent would bring back an
//     empty shell.
// ============================================================

class RecycleBinService
{
    /** Guard against a pathological FK graph. */
    private const MAX_DEPTH = 3;

    /** Columns worth showing as a human label, best first. */
    private const LABEL_COLUMNS = [
        'full_name', 'member_name', 'customer_name', 'group_name', 'title',
        'loan_number', 'fund_number', 'group_number', 'receipt_number',
        'name', 'email', 'category',
    ];

    /**
     * Archive rows that are about to be deleted.
     * Must be called BEFORE the DELETE runs.
     */
    public static function capture(string $table, array $rows, array $claims): void
    {
        if ($table === 'recycle_bin' || !$rows) return;

        try {
            $pdo = Database::pdo();
            $ins = $pdo->prepare(
                "INSERT INTO recycle_bin
                   (id, table_name, record_id, label, payload, child_count,
                    deleted_by, deleted_by_name, deleted_by_role)
                 VALUES (?,?,?,?,?,?,?,?,?)"
            );

            $actorId   = $claims['sub'] ?? null;
            $actorRole = strtolower(trim((string)($claims['role'] ?? '')));
            $actorName = null;
            if ($actorId) {
                $p = Profile::firstRaw(' WHERE id = ?', [$actorId]);
                $actorName = $p['full_name'] ?? null;
            }

            foreach ($rows as $row) {
                $id = $row['id'] ?? null;
                if ($id === null) continue;

                $raw = self::rawRow($table, $id);
                if ($raw === null) continue;

                $children  = self::cascadeChildren($table, $id, 0);
                $childCount = 0;
                foreach ($children as $kids) $childCount += count($kids);

                $payload = json_encode(
                    ['table' => $table, 'row' => $raw, 'children' => $children],
                    JSON_UNESCAPED_UNICODE
                );
                if ($payload === false) continue;

                $ins->execute([
                    uuid4(),
                    $table,
                    (string)$id,
                    self::labelFor($table, $raw),
                    $payload,
                    $childCount,
                    $actorId,
                    $actorName,
                    $actorRole ?: null,
                ]);
            }
        } catch (\Throwable $e) {
            // Archiving must never block the delete the user asked for.
        }
    }

    /**
     * Put a record back. Returns [ok, message].
     * The parent goes in first so the children's foreign keys resolve.
     */
    public static function restore(array $entry): array
    {
        $payload = json_decode((string)($entry['payload'] ?? ''), true);
        if (!is_array($payload) || empty($payload['table']) || empty($payload['row'])) {
            return [false, 'This entry has no usable snapshot to restore.'];
        }

        $pdo = Database::pdo();
        $table = (string)$payload['table'];

        if (!self::tableExists($table)) {
            return [false, "The table `$table` no longer exists."];
        }

        try {
            $pdo->beginTransaction();

            // Upsert, not insert: a soft-deleted row (customers.delflag = 1)
            // is still physically there, so INSERT IGNORE would quietly do
            // nothing and report success while the record stayed hidden.
            self::insertRaw($table, $payload['row'], true);

            foreach (($payload['children'] ?? []) as $childTable => $childRows) {
                if (!self::tableExists($childTable)) continue;
                foreach ($childRows as $childRow) {
                    // Upsert here too: a soft-deleted parent flags its children
                    // rather than removing them, so they are still present and a
                    // plain insert would leave them flagged and invisible.
                    self::insertRaw($childTable, $childRow, true);
                }
            }

            $pdo->prepare("UPDATE recycle_bin SET restored_at = NOW() WHERE id = ?")
                ->execute([$entry['id']]);

            $pdo->commit();
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            // The usual cause is a parent that was itself deleted afterwards.
            return [false, 'Could not restore: ' . $e->getMessage()];
        }

        return [true, 'Restored.'];
    }

    // ── internals ────────────────────────────────────────────────────

    private static function rawRow(string $table, $id): ?array
    {
        $st = Database::pdo()->prepare("SELECT * FROM `$table` WHERE `id` = ? LIMIT 1");
        $st->execute([$id]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    /**
     * Rows in other tables that the database will delete along with this one.
     * Keyed by table name; nested cascades are flattened into the same map.
     */
    private static function cascadeChildren(string $table, $id, int $depth): array
    {
        if ($depth >= self::MAX_DEPTH) return [];

        $out = [];
        foreach (self::cascadeLinks($table) as $link) {
            $childTable = $link['TABLE_NAME'];
            $childCol   = $link['COLUMN_NAME'];
            if ($childTable === 'recycle_bin') continue;

            $st = Database::pdo()->prepare("SELECT * FROM `$childTable` WHERE `$childCol` = ?");
            $st->execute([$id]);
            $kids = $st->fetchAll(PDO::FETCH_ASSOC);
            if (!$kids) continue;

            $out[$childTable] = array_merge($out[$childTable] ?? [], $kids);

            foreach ($kids as $kid) {
                if (empty($kid['id'])) continue;
                foreach (self::cascadeChildren($childTable, $kid['id'], $depth + 1) as $t => $rows) {
                    $out[$t] = array_merge($out[$t] ?? [], $rows);
                }
            }
        }
        return $out;
    }

    /** FK columns in other tables that point here with ON DELETE CASCADE. */
    private static function cascadeLinks(string $table): array
    {
        static $cache = [];
        if (isset($cache[$table])) return $cache[$table];

        try {
            $st = Database::pdo()->prepare(
                "SELECT k.TABLE_NAME, k.COLUMN_NAME
                 FROM information_schema.REFERENTIAL_CONSTRAINTS rc
                 JOIN information_schema.KEY_COLUMN_USAGE k
                   ON k.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
                  AND k.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
                 WHERE rc.CONSTRAINT_SCHEMA = DATABASE()
                   AND rc.REFERENCED_TABLE_NAME = ?
                   AND rc.DELETE_RULE = 'CASCADE'"
            );
            $st->execute([$table]);
            $cache[$table] = $st->fetchAll(PDO::FETCH_ASSOC);
        } catch (\Throwable $e) {
            $cache[$table] = [];
        }
        return $cache[$table];
    }

    /**
     * @param bool $overwrite Restore the snapshot over a row that still exists
     *                        (the soft-delete case). Children stay INSERT IGNORE
     *                        so a partially-restored set is not clobbered.
     */
    private static function insertRaw(string $table, array $row, bool $overwrite = false): void
    {
        if (!$row) return;
        $cols = array_keys($row);
        $colList = implode(',', array_map(fn($c) => "`$c`", $cols));
        $ph = implode(',', array_fill(0, count($cols), '?'));
        $binds = array_values($row);

        if ($overwrite) {
            $updates = implode(',', array_map(fn($c) => "`$c` = VALUES(`$c`)", $cols));
            $sql = "INSERT INTO `$table` ($colList) VALUES ($ph) ON DUPLICATE KEY UPDATE $updates";
        } else {
            // A row already put back by an earlier restore must not abort the rest.
            $sql = "INSERT IGNORE INTO `$table` ($colList) VALUES ($ph)";
        }
        Database::pdo()->prepare($sql)->execute($binds);
    }

    private static function tableExists(string $table): bool
    {
        $st = Database::pdo()->prepare(
            "SELECT COUNT(*) FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?"
        );
        $st->execute([$table]);
        return (int)$st->fetchColumn() > 0;
    }

    /**
     * A line the admin can actually recognise in the bin.
     *
     * Plenty of tables have no name column at all — a repayment installment is
     * just numbers — and those were all landing in the bin as "(no name)". For
     * those, describe the row from what it does have, and say which parent it
     * belonged to so two identical-looking installments can be told apart.
     */
    private static function labelFor(string $table, array $row): ?string
    {
        $money = fn($v) => '₹' . number_format((float)$v, 0);

        switch ($table) {
            case 'loans':
                // Both halves matter: the number identifies the loan, the name
                // tells the admin whose it was.
                return self::join([
                    $row['loan_number']   ?? null,
                    $row['customer_name'] ?? null,
                    !empty($row['loan_amount']) ? $money($row['loan_amount']) : null,
                ]);

            case 'funds':
                return self::join([
                    $row['fund_number']   ?? null,
                    $row['customer_name'] ?? null,
                ]);

            case 'chit_groups':
                return self::join([
                    $row['group_name']   ?? null,
                    $row['group_number'] ?? null,
                ]);

            case 'repayment_schedule':
                $parts = ['Installment #' . (int)($row['installment_no'] ?? 0)];
                if (!empty($row['emi_amount'])) $parts[] = $money($row['emi_amount']);
                if (!empty($row['due_date']))   $parts[] = 'due ' . $row['due_date'];
                $loan = self::parentLabel('loans', $row['loan_id'] ?? null, ['loan_number', 'customer_name']);
                if ($loan) $parts[] = $loan;
                return self::join($parts);

            case 'chit_schedules':
                $parts = ['Draw #' . (int)($row['installment_no'] ?? 0)];
                if (!empty($row['payable_amount'])) $parts[] = $money($row['payable_amount']);
                if (!empty($row['due_date']))       $parts[] = 'due ' . $row['due_date'];
                $grp = self::parentLabel('chit_groups', $row['group_id'] ?? null, ['group_name', 'group_number']);
                if ($grp) $parts[] = $grp;
                return self::join($parts);

            case 'fund_payments':
                $parts = ['Week ' . (int)($row['week_no'] ?? 0)];
                if (!empty($row['amount'])) $parts[] = $money($row['amount']);
                if (!empty($row['customer_name'])) $parts[] = (string)$row['customer_name'];
                return self::join($parts);

            case 'chit_payments':
                $parts = [];
                $parts[] = !empty($row['installment_no'])
                    ? 'Draw #' . (int)$row['installment_no'] . ' contribution'
                    : 'Chit contribution';
                if (!empty($row['amount']))        $parts[] = $money($row['amount']);
                if (!empty($row['customer_name'])) $parts[] = (string)$row['customer_name'];
                return self::join($parts);

            case 'collections':
                $parts = [];
                if (!empty($row['receipt_number']))    $parts[] = (string)$row['receipt_number'];
                if (!empty($row['collection_amount'])) $parts[] = $money($row['collection_amount']);
                if (!empty($row['collection_date']))   $parts[] = (string)$row['collection_date'];
                return self::join($parts) ?? 'Collection';

            case 'handovers':
                $parts = ['Cash handover'];
                if (!empty($row['total_amount']))   $parts[] = $money($row['total_amount']);
                if (!empty($row['handover_date']))  $parts[] = (string)$row['handover_date'];
                return self::join($parts);

            case 'push_subscriptions':
                return 'Push notification subscription';
        }

        foreach (self::LABEL_COLUMNS as $col) {
            if (!empty($row[$col]) && is_scalar($row[$col])) {
                return mb_substr(trim((string)$row[$col]), 0, 200);
            }
        }

        // Last resort: anything readable beats "(no name)".
        foreach ($row as $k => $v) {
            if ($k === 'id' || !is_scalar($v) || $v === '' || $v === null) continue;
            if (is_string($v) && preg_match('/^[0-9a-f-]{36}$/i', $v)) continue;
            return mb_substr(trim((string)$v), 0, 120);
        }
        return null;
    }

    private static function join(array $parts): ?string
    {
        $parts = array_values(array_filter($parts, fn($p) => $p !== null && $p !== ''));
        return $parts ? mb_substr(implode(' · ', $parts), 0, 200) : null;
    }

    /** Name of the row this one hangs off, so siblings are distinguishable. */
    private static function parentLabel(string $table, $id, array $columns): ?string
    {
        if (empty($id)) return null;
        try {
            $st = Database::pdo()->prepare("SELECT * FROM `$table` WHERE `id` = ? LIMIT 1");
            $st->execute([$id]);
            $parent = $st->fetch(PDO::FETCH_ASSOC);
            if (!$parent) return null;
            foreach ($columns as $c) {
                if (!empty($parent[$c])) return mb_substr(trim((string)$parent[$c]), 0, 80);
            }
        } catch (\Throwable $e) {
            // A label is a nicety; never let it break the archive.
        }
        return null;
    }
}
