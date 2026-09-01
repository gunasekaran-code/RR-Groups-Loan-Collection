<?php
/**
 * Authoritative chit passbook — one stored row per (member, draw).
 *
 * The passbook a customer opens used to be assembled in the browser: it read
 * the group's draw schedule, read that member's contributions, and ran a
 * waterfall allocation in JavaScript to decide Paid / Partial / Overdue. So the
 * status existed only for as long as the modal was open, no two screens could
 * agree on it, and nothing on the server could report on it.
 *
 * chit_passbook stores that statement instead, keyed on real foreign keys
 * (group_id + member_id), with the draw number, scheduled date, payable
 * contribution, dividend pool value and settled status as columns. Every screen
 * now reads the same rows.
 *
 * Idempotent: a sync always recomputes from the current schedule and the
 * current contributions, so it stays correct after a payment is edited,
 * deleted or back-dated.
 */
class ChitPassbookService
{
    /**
     * The three fixed schemes the office runs, mirrored from the frontend
     * tables so a group created before chit_schedules existed still produces
     * the exact draw sheet the customer has always seen.
     */
    private const SCHEME_750 = [
        [1, 21000, 750], [2, 21000, 750], [3, 21000, 750], [4, 21000, 750], [5, 21000, 750],
        [6, 21300, 760], [7, 21600, 770], [8, 21900, 780], [9, 22200, 790], [10, 22500, 800],
        [11, 22800, 810], [12, 23100, 820], [13, 23400, 830], [14, 23700, 840], [15, 24000, 850],
        [16, 24300, 860], [17, 24600, 870], [18, 24900, 880], [19, 25200, 890], [20, 25500, 900],
        [21, 25800, 910], [22, 26100, 920], [23, 26400, 930], [24, 26700, 940], [25, 27000, 950],
        [26, 27300, 960], [27, 27600, 970], [28, 27900, 980], [29, 28200, 990], [30, 28500, 1000],
    ];

    private const SCHEME_1420 = [
        [1, 39600, 1420], [2, 40200, 1440], [3, 40800, 1460], [4, 41400, 1480], [5, 42000, 1500],
        [6, 42600, 1520], [7, 43200, 1540], [8, 43800, 1560], [9, 44400, 1580], [10, 45000, 1600],
        [11, 45600, 1620], [12, 46200, 1640], [13, 46800, 1660], [14, 47400, 1680], [15, 48000, 1700],
        [16, 48600, 1720], [17, 49200, 1740], [18, 49800, 1760], [19, 50400, 1780], [20, 51000, 1800],
        [21, 51600, 1820], [22, 52200, 1840], [23, 52800, 1860], [24, 53400, 1880], [25, 54000, 1900],
        [26, 54600, 1920], [27, 55200, 1940], [28, 55800, 1960], [29, 56400, 1980], [30, 57000, 2000],
    ];

    private const SCHEME_5000_21M = [
        [0, 0, 5000, 'Company'],
        [1, 80000, 5000, 'Installment #1'],    [2, 81000, 5000, 'Installment #2'],
        [3, 82000, 5000, 'Installment #3'],    [4, 83000, 5000, 'Installment #4'],
        [5, 84000, 5000, 'Installment #5'],    [6, 85000, 5000, 'Installment #6'],
        [7, 86000, 5000, 'Installment #7'],    [8, 87000, 5000, 'Installment #8'],
        [9, 88000, 5000, 'Installment #9'],    [10, 90000, 5000, 'Installment #10'],
        [11, 91000, 5000, 'Installment #11'],  [12, 92000, 5000, 'Installment #12'],
        [13, 93000, 5000, 'Installment #13'],  [14, 94000, 5000, 'Installment #14'],
        [15, 95000, 5000, 'Installment #15'],  [16, 105000, 5000, 'Installment #16'],
        [17, 110000, 5000, 'Installment #17'], [18, 115000, 5000, 'Installment #18'],
        [19, 120000, 5000, 'Installment #19'], [20, 125000, 5000, 'Installment #20'],
    ];

    // ────────────────────────────── entry points ──────────────────────────

    /** Rebuild the passbook for every live member of a group. */
    public static function syncGroup(string $groupId, bool $generateSchedule = false): void
    {
        if ($groupId === '') return;
        try {
            $stmt = Database::pdo()->prepare(
                'SELECT id FROM `chit_members` WHERE `group_id` = ? AND `delflag` = 0'
            );
            $stmt->execute([$groupId]);
            self::syncMembers($stmt->fetchAll(PDO::FETCH_COLUMN, 0) ?: [], $generateSchedule);
        } catch (\Throwable $e) {
            error_log('ChitPassbookService::syncGroup failed for ' . $groupId . ': ' . $e->getMessage());
        }
    }

    /** Rebuild the passbook for a set of members, never throwing. */
    public static function syncMembers(array $memberIds, bool $generateSchedule = false): void
    {
        foreach (array_unique(array_filter($memberIds)) as $id) {
            try {
                self::syncMember((string)$id, $generateSchedule);
            } catch (\Throwable $e) {
                // A passbook refresh must never fail the payment that triggered it.
                error_log('ChitPassbookService failed for member ' . $id . ': ' . $e->getMessage());
            }
        }
    }

    /** Rebuild every passbook. Used by the one-off backfill. */
    public static function syncAll(): int
    {
        $ids = Database::pdo()
            ->query('SELECT id FROM `chit_members` WHERE `delflag` = 0')
            ->fetchAll(PDO::FETCH_COLUMN, 0) ?: [];
        self::syncMembers($ids, true);
        return count($ids);
    }

    /**
     * Recompute one member's passbook from the group's draw schedule and that
     * member's recorded contributions.
     */
    public static function syncMember(string $memberId, bool $generateSchedule = false): void
    {
        if ($memberId === '') return;
        $pdo = Database::pdo();

        $stmt = $pdo->prepare('SELECT * FROM `chit_members` WHERE `id` = ? AND `delflag` = 0 LIMIT 1');
        $stmt->execute([$memberId]);
        $member = $stmt->fetch();
        if (!$member) return;

        $groupId = (string)($member['group_id'] ?? '');
        if ($groupId === '') return;

        $stmt = $pdo->prepare('SELECT * FROM `chit_groups` WHERE `id` = ? LIMIT 1');
        $stmt->execute([$groupId]);
        $group = $stmt->fetch();
        if (!$group) return;

        $schedules = self::schedulesFor($groupId, $group, $generateSchedule);
        if (!$schedules) return;

        // A member's own contributions, oldest first — the order the money was
        // actually received is what decides which draw each rupee settles.
        $stmt = $pdo->prepare(
            'SELECT `amount`, `payment_date`, `created_at`
               FROM `chit_payments`
              WHERE `member_id` = ? AND `delflag` = 0
              ORDER BY COALESCE(`payment_date`, DATE(`created_at`)) ASC, `created_at` ASC'
        );
        $stmt->execute([$memberId]);
        $payments = $stmt->fetchAll();

        $rows = self::allocate($schedules, $payments);
        self::writeRows($pdo, $member, $group, $rows);
        self::writeMemberStatus($pdo, $member, $rows);
    }

    // ──────────────────────────── the allocation ──────────────────────────

    /**
     * Waterfall the contributions across the draws, earliest draw first — the
     * same rule the loan side uses. Paying two draws early settles the next two
     * draws; it never counts twice.
     *
     * @return array<int,array<string,mixed>>
     */
    private static function allocate(array $schedules, array $payments): array
    {
        $today = new DateTimeImmutable('today');
        $count = count($payments);

        $pIdx  = 0;
        $pLeft = $count ? (float)$payments[0]['amount'] : 0.0;
        $out   = [];

        foreach ($schedules as $s) {
            $payable = (float)($s['payable_amount'] ?? 0);
            $need    = $payable;
            $applied = 0.0;
            $paidOn  = null;

            while ($need > 0.009 && $pIdx < $count) {
                if ($pLeft <= 0.009) {
                    $pIdx++;
                    $pLeft = $pIdx < $count ? (float)$payments[$pIdx]['amount'] : 0.0;
                    continue;
                }
                $take     = min($need, $pLeft);
                $applied += $take;
                $need    -= $take;
                $pLeft   -= $take;
                $paidOn   = $payments[$pIdx]['payment_date']
                    ?: substr((string)($payments[$pIdx]['created_at'] ?? ''), 0, 10);
            }

            $balance = round(max(0, $payable - $applied), 2);
            $isPaid  = $payable > 0 && $applied + 0.009 >= $payable;

            $due       = !empty($s['due_date']) ? new DateTimeImmutable((string)$s['due_date']) : null;
            $isOverdue = !$isPaid && $due !== null && $due < $today;

            // Precedence matches the badge the passbook has always shown: a
            // part-paid instalment reads "Partial · ₹x left", which tells the
            // customer more than a bare "Overdue". is_overdue is stored beside
            // it so a report can still find every late draw.
            if ($isPaid)              $status = 'paid';
            elseif ($applied > 0.009) $status = 'partial';
            elseif ($isOverdue)       $status = 'overdue';
            else                      $status = 'pending';

            $out[] = [
                'schedule_id'    => $s['id'] ?? null,
                'installment_no' => (int)($s['installment_no'] ?? 0),
                'due_date'       => $s['due_date'] ?? null,
                'payable_amount' => round($payable, 2),
                'pool_amount'    => round((float)($s['pool_amount'] ?? 0), 2),
                'paid_amount'    => round($applied, 2),
                'balance'        => $balance,
                'payment_status' => $status,
                'is_overdue'     => $isOverdue ? 1 : 0,
                'paid_date'      => $isPaid ? $paidOn : null,
                'is_overridden'  => (int)($s['is_overridden'] ?? 0),
                'notes'          => $s['notes'] ?? null,
                'is_due'         => $due === null || $due <= $today,
            ];
        }

        return $out;
    }

    // ───────────────────────────── persistence ────────────────────────────

    private static function writeRows(PDO $pdo, array $member, array $group, array $rows): void
    {
        $memberId = (string)$member['id'];

        // UNIQUE(member_id, installment_no) makes this an upsert, so repeated
        // syncs can never grow a second copy of a draw — the failure that
        // inflated loan balances on the repayment side.
        $ins = $pdo->prepare(
            "INSERT INTO `chit_passbook`
               (id, group_id, member_id, customer_id, schedule_id, group_number, group_name,
                member_name, installment_no, due_date, payable_amount, pool_amount,
                paid_amount, balance, payment_status, is_overdue, paid_date,
                is_overridden, notes, synced_at, delflag)
             VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,0)
             ON DUPLICATE KEY UPDATE
               group_id       = VALUES(group_id),
               customer_id    = VALUES(customer_id),
               schedule_id    = VALUES(schedule_id),
               group_number   = VALUES(group_number),
               group_name     = VALUES(group_name),
               member_name    = VALUES(member_name),
               due_date       = VALUES(due_date),
               payable_amount = VALUES(payable_amount),
               pool_amount    = VALUES(pool_amount),
               paid_amount    = VALUES(paid_amount),
               balance        = VALUES(balance),
               payment_status = VALUES(payment_status),
               is_overdue     = VALUES(is_overdue),
               paid_date      = VALUES(paid_date),
               is_overridden  = VALUES(is_overridden),
               notes          = VALUES(notes),
               synced_at      = VALUES(synced_at),
               delflag        = 0,
               deleted_at     = NULL,
               deleted_by     = NULL"
        );

        $now = date('Y-m-d H:i:s');
        foreach ($rows as $r) {
            $ins->execute([
                uuid4(),
                $group['id'],
                $memberId,
                $member['customer_id'] ?? null,
                $r['schedule_id'],
                $group['group_number'] ?? null,
                $group['group_name'] ?? null,
                $member['member_name'] ?? null,
                $r['installment_no'],
                $r['due_date'],
                $r['payable_amount'],
                $r['pool_amount'],
                $r['paid_amount'],
                $r['balance'],
                $r['payment_status'],
                $r['is_overdue'],
                $r['paid_date'],
                $r['is_overridden'],
                $r['notes'],
                $now,
            ]);
        }

        // Drop draws that no longer exist — the schedule was shortened or
        // regenerated. These rows are derived, so they go outright rather than
        // being flagged; leaving flagged copies behind is exactly what taught
        // us to add the UNIQUE index above.
        $keep = array_map(static function ($r) { return (int)$r['installment_no']; }, $rows);
        if ($keep) {
            $ph = implode(',', array_fill(0, count($keep), '?'));
            $pdo->prepare(
                "DELETE FROM `chit_passbook`
                  WHERE `member_id` = ? AND `installment_no` NOT IN ($ph)"
            )->execute(array_merge([$memberId], $keep));
        }
    }

    /**
     * Keep the member card in step with the passbook.
     *
     * "Paid" here means up to date on everything due so far — the passbook
     * header used to read Paid while the table underneath it listed an overdue
     * draw, because the two came from different places.
     */
    private static function writeMemberStatus(PDO $pdo, array $member, array $rows): void
    {
        $firstUnsettledDue = null;
        $firstUnsettled    = null;
        $anyPaid           = false;

        foreach ($rows as $r) {
            if ($r['paid_amount'] > 0) $anyPaid = true;
            if ($r['payment_status'] === 'paid') continue;
            if ($firstUnsettled === null) $firstUnsettled = $r;
            if ($firstUnsettledDue === null && $r['is_due']) $firstUnsettledDue = $r;
        }

        if ($firstUnsettledDue !== null) {
            $status = $firstUnsettledDue['paid_amount'] > 0 ? 'partial' : 'overdue';
        } elseif ($firstUnsettled === null || $anyPaid) {
            $status = 'paid';          // nothing outstanding that has fallen due
        } else {
            $status = 'pending';
        }

        $nextDue = $firstUnsettled['due_date'] ?? ($member['due_date'] ?? null);

        $pdo->prepare('UPDATE `chit_members` SET `payment_status` = ?, `due_date` = ? WHERE `id` = ?')
            ->execute([$status, $nextDue, $member['id']]);
    }

    // ─────────────────────────── recording money ──────────────────────────

    /**
     * Record one chit contribution, end to end, on the server.
     *
     * This used to be six round trips driven by the browser: write the ledger
     * receipt, read back every prior payment, read the draw sheet, waterfall it
     * in JavaScript to guess which draw the money settled, insert the payment,
     * then overwrite the member's status with a flat 'paid' and a date computed
     * in the client. A tab closed midway left the receipt without the payment,
     * and the status it wrote was not the one the passbook derived — which is
     * how a passbook cover came to read Paid above an overdue draw.
     *
     * Now it is one request inside one transaction, and the passbook, the
     * member and the group totals are all derived from what is stored.
     *
     * @return array{payment: array, passbook: array, member: array, group: array}
     */
    public static function collect(array $in, array $actor): array
    {
        $pdo = Database::pdo();

        $memberId = trim((string)($in['member_id'] ?? ''));
        $amount   = round((float)($in['amount'] ?? 0), 2);
        if ($memberId === '')  json_error('Which member is paying?', 400);
        if ($amount <= 0)      json_error('The collection amount must be more than zero', 400);

        $stmt = $pdo->prepare('SELECT * FROM `chit_members` WHERE `id` = ? AND `delflag` = 0 LIMIT 1');
        $stmt->execute([$memberId]);
        $member = $stmt->fetch();
        if (!$member) json_error('That chit member no longer exists', 404);

        $stmt = $pdo->prepare('SELECT * FROM `chit_groups` WHERE `id` = ? LIMIT 1');
        $stmt->execute([$member['group_id']]);
        $group = $stmt->fetch();
        if (!$group) json_error('That chit group no longer exists', 404);

        $method  = in_array($in['payment_method'] ?? '', ['cash', 'upi', 'card', 'bank', 'cheque'], true)
            ? $in['payment_method'] : 'cash';
        $payDate = self::asDate($in['payment_date'] ?? null) ?: date('Y-m-d');
        $notes   = trim((string)($in['notes'] ?? ''));

        // The collector is taken from the token, never from the request body:
        // an agent must not be able to file cash under someone else's name.
        $agentId   = $actor['sub'] ?? null;
        $agentName = null;
        if ($agentId) {
            $p = Profile::findPublic($agentId);
            $agentName = $p['full_name'] ?? null;
        }

        // Make sure the draw sheet exists before deciding which draw is settled.
        self::schedulesFor((string)$group['id'], $group, true);

        $pdo->beginTransaction();
        try {
            // The cash book receipt. Written first so the money is on record
            // even if something below it fails — and rolled back with the rest
            // if it does, rather than stranding a receipt with no payment.
            $ledgerId = uuid4();
            $pdo->prepare(
                'INSERT INTO `account_ledger`
                   (id, entry_type, title, amount, category, entry_date, notes,
                    agent_id, agent_name, payment_method)
                 VALUES (?,?,?,?,?,?,?,?,?,?)'
            )->execute([
                $ledgerId,
                'cash_in',
                'Chit Contribution: ' . ($group['group_name'] ?? '') . ' - ' . ($member['member_name'] ?? 'Member'),
                $amount,
                'Chit Collection',
                $payDate,
                $notes !== '' ? $notes : sprintf(
                    'Collected %s (%s) for %s',
                    '₹' . number_format($amount, 2),
                    strtoupper($method),
                    $group['group_number'] ?? ''
                ),
                $agentId,
                $agentName,
                $method,
            ]);

            $stmt = $pdo->prepare(
                'SELECT COALESCE(SUM(`amount`), 0) FROM `chit_payments`
                  WHERE `member_id` = ? AND `delflag` = 0'
            );
            $stmt->execute([$memberId]);
            $priorPaid = (float)$stmt->fetchColumn();

            $paymentId = uuid4();
            $pdo->prepare(
                'INSERT INTO `chit_payments`
                   (id, group_id, member_id, group_number, group_name, customer_id, customer_name,
                    installment_no, amount, balance_after, payment_method, payment_date,
                    agent_id, agent_name, ledger_id, notes)
                 VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)'
            )->execute([
                $paymentId,
                $group['id'],
                $memberId,
                $group['group_number'] ?? null,
                $group['group_name'] ?? null,
                $member['customer_id'] ?? null,
                $member['member_name'] ?? null,
                self::nextUnsettledDraw($pdo, $memberId),
                $amount,
                round($priorPaid + $amount, 2),
                $method,
                $payDate,
                $agentId,
                $agentName,
                $ledgerId,
                $notes !== '' ? $notes : null,
            ]);

            $pdo->commit();
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $e;
        }

        // Everything below is derived from what was just stored, so it is
        // recomputed rather than adjusted — a correction or a deletion lands
        // on exactly the same code path.
        self::syncMember($memberId, true);
        self::recalcGroupTotals((string)$group['id']);

        return [
            'payment'  => self::rowById($pdo, 'chit_payments', $paymentId),
            'passbook' => self::passbookFor($pdo, $memberId),
            'member'   => self::rowById($pdo, 'chit_members', $memberId),
            'group'    => self::rowById($pdo, 'chit_groups', (string)$group['id']),
        ];
    }

    /**
     * The draw a new contribution settles: the first one not yet fully paid.
     * Read from the passbook rather than re-waterfalled, so the number stamped
     * on the receipt is the same one the customer sees against the draw.
     */
    private static function nextUnsettledDraw(PDO $pdo, string $memberId): int
    {
        $stmt = $pdo->prepare(
            "SELECT installment_no FROM `chit_passbook`
              WHERE `member_id` = ? AND `delflag` = 0 AND `payment_status` <> 'paid'
              ORDER BY `installment_no` ASC LIMIT 1"
        );
        $stmt->execute([$memberId]);
        $no = $stmt->fetchColumn();
        if ($no !== false) return (int)$no;

        // Every scheduled draw is settled — this is an extra payment beyond
        // the scheme, so it sits one past the last draw rather than at 0.
        $stmt = $pdo->prepare(
            'SELECT COALESCE(MAX(`installment_no`), 0) FROM `chit_passbook`
              WHERE `member_id` = ? AND `delflag` = 0'
        );
        $stmt->execute([$memberId]);
        return (int)$stmt->fetchColumn() + 1;
    }

    /**
     * A group's collected / pending totals, summed from the contributions
     * rather than incremented. Incrementing drifts the moment a payment is
     * corrected or deleted, and the drift is invisible.
     */
    public static function recalcGroupTotals(string $groupId): void
    {
        $pdo = Database::pdo();
        $stmt = $pdo->prepare(
            'SELECT COALESCE(SUM(`amount`), 0) FROM `chit_payments`
              WHERE `group_id` = ? AND `delflag` = 0'
        );
        $stmt->execute([$groupId]);
        $collected = round((float)$stmt->fetchColumn(), 2);

        $stmt = $pdo->prepare('SELECT `group_value`, `status` FROM `chit_groups` WHERE `id` = ? LIMIT 1');
        $stmt->execute([$groupId]);
        $g = $stmt->fetch();
        if (!$g) return;

        $value   = (float)$g['group_value'];
        $pending = round(max(0, $value - $collected), 2);
        // A group only closes on money; a manual 'pending' is left alone until
        // the first contribution arrives.
        $status  = $value > 0 && $collected >= $value ? 'closed'
                 : ($collected > 0 ? 'active' : $g['status']);

        $pdo->prepare(
            'UPDATE `chit_groups` SET `collected_amount` = ?, `pending_amount` = ?, `status` = ? WHERE `id` = ?'
        )->execute([$collected, $pending, $status, $groupId]);
    }

    /**
     * Rebuild a group's draw sheet from its scheme, then every member's
     * passbook from the new sheet. Replaces the browser doing a delete followed
     * by thirty inserts, which could half-fail and leave a group owing draws
     * twice.
     */
    public static function regenerateSchedule(string $groupId): array
    {
        $pdo = Database::pdo();
        $stmt = $pdo->prepare('SELECT * FROM `chit_groups` WHERE `id` = ? LIMIT 1');
        $stmt->execute([$groupId]);
        $group = $stmt->fetch();
        if (!$group) json_error('That chit group no longer exists', 404);

        $pdo->beginTransaction();
        try {
            // Hand delete, not a soft one: a draw sheet is derived from the
            // scheme, and flagged copies left behind would be counted again.
            $pdo->prepare('DELETE FROM `chit_schedules` WHERE `group_id` = ?')->execute([$groupId]);
            $pdo->commit();
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $e;
        }

        $schedules = self::schedulesFor($groupId, $group, true);
        self::syncGroup($groupId, true);

        return $schedules;
    }

    private static function passbookFor(PDO $pdo, string $memberId): array
    {
        $stmt = $pdo->prepare(
            'SELECT * FROM `chit_passbook` WHERE `member_id` = ? AND `delflag` = 0
              ORDER BY `installment_no` ASC'
        );
        $stmt->execute([$memberId]);
        return $stmt->fetchAll() ?: [];
    }

    private static function rowById(PDO $pdo, string $table, string $id): ?array
    {
        $stmt = $pdo->prepare("SELECT * FROM `$table` WHERE `id` = ? LIMIT 1");
        $stmt->execute([$id]);
        return $stmt->fetch() ?: null;
    }

    private static function asDate($v): ?string
    {
        if (!is_string($v) || $v === '') return null;
        $ts = strtotime($v);
        return $ts === false ? null : date('Y-m-d', $ts);
    }

    // ──────────────────────────── draw schedule ───────────────────────────

    /**
     * The group's draw sheet, generating and storing it when the group has
     * none. Generation used to live only in the browser, so a group whose
     * schedule an admin never generated showed a passbook that existed nowhere
     * but in that one open modal.
     */
    public static function schedulesFor(string $groupId, ?array $group = null, bool $generate = false): array
    {
        $pdo = Database::pdo();

        $rows = self::readSchedules($pdo, $groupId);
        if ($rows || !$generate) return $rows;

        if ($group === null) {
            $stmt = $pdo->prepare('SELECT * FROM `chit_groups` WHERE `id` = ? LIMIT 1');
            $stmt->execute([$groupId]);
            $group = $stmt->fetch() ?: null;
        }
        if (!$group) return [];

        $items = self::generateSchedule($group);
        if (!$items) return [];

        $ins = $pdo->prepare(
            'INSERT INTO `chit_schedules`
               (id, group_id, installment_no, due_date, payable_amount, pool_amount, is_overridden, notes)
             VALUES (?,?,?,?,?,?,0,?)'
        );
        foreach ($items as $i) {
            $ins->execute([
                uuid4(), $groupId, $i['installment_no'], $i['due_date'],
                $i['payable_amount'], $i['pool_amount'], $i['notes'],
            ]);
        }

        return self::readSchedules($pdo, $groupId);
    }

    private static function readSchedules(PDO $pdo, string $groupId): array
    {
        $stmt = $pdo->prepare(
            'SELECT * FROM `chit_schedules` WHERE `group_id` = ? AND `delflag` = 0
              ORDER BY `installment_no` ASC'
        );
        $stmt->execute([$groupId]);
        return $stmt->fetchAll() ?: [];
    }

    /** Mirrors the generation in frontend/src/screens/ChitGroupsScreen.tsx. */
    private static function generateSchedule(array $group): array
    {
        $freq     = (string)($group['draw_frequency'] ?? 'monthly_1');
        $contrib  = (float)($group['monthly_contribution'] ?? 0);
        $duration = (int)($group['duration'] ?? 0);
        $value    = (float)($group['group_value'] ?? 0);
        $start    = new DateTimeImmutable($group['start_date'] ?: date('Y-m-d'));

        $is750  = $freq === 'every_5_days' && ((int)$contrib === 750 || $duration === 30);
        $is1420 = $freq === 'every_10_days' || ((int)$contrib === 1420 && $duration === 30);

        if ($is750)  return self::fromTable(self::SCHEME_750, $start, 5);
        if ($is1420) return self::fromTable(self::SCHEME_1420, $start, 10);

        if ($duration === 21) {
            $out = [];
            foreach (self::SCHEME_5000_21M as $row) {
                [$no, $pool, $payable, $note] = $row;
                $out[] = [
                    'installment_no' => $no,
                    'due_date'       => $start->modify("+$no month")->format('Y-m-d'),
                    'payable_amount' => $payable,
                    'pool_amount'    => $pool,
                    'notes'          => $note,
                ];
            }
            return $out;
        }

        $total = $duration ?: 12;
        $due   = $start;
        $out   = [];
        for ($i = 1; $i <= $total; $i++) {
            $out[] = [
                'installment_no' => $i,
                'due_date'       => $due->format('Y-m-d'),
                'payable_amount' => $contrib,
                'pool_amount'    => $value,
                'notes'          => null,
            ];
            $due = self::nextDrawDate($due, $freq, $group['draw_days'] ?? '1');
        }
        return $out;
    }

    private static function fromTable(array $table, DateTimeImmutable $start, int $stepDays): array
    {
        $out = [];
        foreach ($table as $row) {
            [$no, $pool, $payable] = $row;
            $out[] = [
                'installment_no' => $no,
                'due_date'       => $start->modify('+' . (($no - 1) * $stepDays) . ' days')->format('Y-m-d'),
                'payable_amount' => $payable,
                'pool_amount'    => $pool,
                'notes'          => null,
            ];
        }
        return $out;
    }

    private static function nextDrawDate(DateTimeImmutable $base, string $freq, ?string $drawDays): DateTimeImmutable
    {
        if ($freq === 'every_5_days')  return $base->modify('+5 days');
        if ($freq === 'every_10_days') return $base->modify('+10 days');
        if ($freq === 'interval_days') {
            $n = (int)($drawDays ?: 5) ?: 5;
            return $base->modify("+$n days");
        }

        $days = [];
        foreach (explode(',', (string)$drawDays) as $d) {
            $n = (int)trim($d);
            if ($n >= 1 && $n <= 31) $days[] = $n;
        }
        if (!$days) {
            if ($freq === 'monthly_2')     $days = [1, 15];
            elseif ($freq === 'monthly_3') $days = [1, 10, 20];
            else                           $days = [(int)$base->format('j') ?: 1];
        }
        sort($days);

        $day = (int)$base->format('j');
        foreach ($days as $d) {
            if ($d > $day) {
                return $base->setDate((int)$base->format('Y'), (int)$base->format('n'), $d);
            }
        }
        $next = $base->modify('first day of next month');
        return $next->setDate((int)$next->format('Y'), (int)$next->format('n'), $days[0]);
    }
}
