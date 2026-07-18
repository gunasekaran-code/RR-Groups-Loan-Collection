<?php
// Parses PostgREST-lite query params ($_GET) into SQL WHERE / ORDER / LIMIT.
// Filters:  column=<op>.<value>   ops: eq, neq, gt, gte, lt, lte, like, ilike, in, is

class QueryParser
{
    private const RESERVED = ['table', 'select', 'order', 'limit', 'offset', 'upsert', 'on_conflict', 'action'];

    /** @return array{0:string,1:array} [sqlFragment, binds] */
    public static function where(array $columns): array
    {
        $clauses = [];
        $binds = [];
        foreach ($_GET as $key => $raw) {
            if (in_array($key, self::RESERVED, true)) {
                continue;
            }
            if (!isset($columns[$key])) {
                json_error("Unknown column in filter: $key", 400);
            }
            $col = "`$key`";
            $dot = strpos($raw, '.');
            $op = $dot === false ? 'eq' : substr($raw, 0, $dot);
            $val = $dot === false ? $raw : substr($raw, $dot + 1);

            switch ($op) {
                case 'eq':  $clauses[] = "$col = ?";  $binds[] = $val; break;
                case 'neq': $clauses[] = "$col <> ?"; $binds[] = $val; break;
                case 'gt':  $clauses[] = "$col > ?";  $binds[] = $val; break;
                case 'gte': $clauses[] = "$col >= ?"; $binds[] = $val; break;
                case 'lt':  $clauses[] = "$col < ?";  $binds[] = $val; break;
                case 'lte': $clauses[] = "$col <= ?"; $binds[] = $val; break;
                case 'like':
                case 'ilike': $clauses[] = "$col LIKE ?"; $binds[] = $val; break;
                case 'is':
                    if (strtolower($val) === 'null')        { $clauses[] = "$col IS NULL"; }
                    elseif (strtolower($val) === 'not.null') { $clauses[] = "$col IS NOT NULL"; }
                    else { $clauses[] = "$col = ?"; $binds[] = $val; }
                    break;
                case 'in':
                    $items = ($list = trim($val, '()')) === '' ? [] : explode(',', $list);
                    if (!$items) { $clauses[] = '1 = 0'; break; }
                    $ph = implode(',', array_fill(0, count($items), '?'));
                    $clauses[] = "$col IN ($ph)";
                    foreach ($items as $it) { $binds[] = trim($it, '"'); }
                    break;
                default:
                    json_error("Unsupported filter operator: $op", 400);
            }
        }
        $sql = $clauses ? (' WHERE ' . implode(' AND ', $clauses)) : '';
        return [$sql, $binds];
    }

    public static function order(array $columns): string
    {
        $order = $_GET['order'] ?? '';
        if ($order === '') {
            return '';
        }
        $parts = [];
        foreach (explode(',', $order) as $spec) {
            $spec = trim($spec);
            if ($spec === '') continue;
            $bits = explode('.', $spec);
            $col = $bits[0];
            if (!isset($columns[$col])) {
                json_error("Unknown column in order: $col", 400);
            }
            $dir = (isset($bits[1]) && strtolower($bits[1]) === 'desc') ? 'DESC' : 'ASC';
            $parts[] = "`$col` $dir";
        }
        return $parts ? (' ORDER BY ' . implode(', ', $parts)) : '';
    }

    public static function limit(): string
    {
        if (isset($_GET['limit']) && ctype_digit((string)$_GET['limit'])) {
            $sql = ' LIMIT ' . (int)$_GET['limit'];
            if (isset($_GET['offset']) && ctype_digit((string)$_GET['offset'])) {
                $sql .= ' OFFSET ' . (int)$_GET['offset'];
            }
            return $sql;
        }
        return '';
    }
}
