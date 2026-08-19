<?php
// Chit-group updates are a *derived* view over chit_members + chit_groups,
// driven by Settings ▸ Groups Updates (group_updates_enabled,
// group_auction_alerts, group_payment_alerts). This model lists members whose
// monthly contribution is due/overdue and can dispatch alerts to each member's
// linked customer login.

class GroupUpdate extends Model
{
    protected static string $table = 'chit_members';

    /**
     * Chit members with a contribution due within `daysBefore` days (or already
     * overdue), joined to their group. Soonest first.
     */
    public static function pending(int $daysBefore = 3): array
    {
        $daysBefore = max(0, min(60, $daysBefore));
        $today  = date('Y-m-d');
        $window = date('Y-m-d', strtotime("+$daysBefore days"));

        $sql = "
            SELECT
                m.id                 AS member_id,
                m.group_id,
                m.customer_id,
                m.member_name,
                m.contribution_amount,
                m.due_date,
                m.payment_status,
                g.group_name,
                g.group_number,
                g.status             AS group_status,
                DATEDIFF(m.due_date, ?) AS days_until
            FROM chit_members m
            JOIN chit_groups g ON g.id = m.group_id AND g.status <> 'closed'
            WHERE m.payment_status <> 'paid'
              AND m.due_date IS NOT NULL
              AND m.due_date <= ?
            ORDER BY m.due_date ASC
        ";
        $stmt = Database::pdo()->prepare($sql);
        $stmt->execute([$today, $window]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($rows as &$r) {
            $r['contribution_amount'] = (float)$r['contribution_amount'];
            $r['days_until']          = (int)$r['days_until'];
            $r['overdue']             = $r['days_until'] < 0;
        }
        return $rows;
    }

    /**
     * Notify each member's linked login about their due chit contribution when
     * payment alerts are enabled. Idempotent per day. Returns counts.
     */
    public static function dispatch(array $settings): array
    {
        $enabled = !isset($settings['group_updates_enabled']) || (bool)$settings['group_updates_enabled'];
        if (!$enabled) {
            return ['sent' => 0, 'skipped' => 0, 'reason' => 'group_updates_disabled'];
        }
        $paymentAlerts = !isset($settings['group_payment_alerts']) || (bool)$settings['group_payment_alerts'];
        if (!$paymentAlerts) {
            return ['sent' => 0, 'skipped' => 0, 'reason' => 'payment_alerts_disabled'];
        }
        $days = (int)($settings['reminder_days'] ?? 3);
        $pdo  = Database::pdo();
        $rows = self::pending($days);
        $sent = 0; $skipped = 0;

        foreach ($rows as $r) {
            if (empty($r['customer_id'])) { $skipped++; continue; }
            $ps = $pdo->prepare("SELECT id FROM profiles WHERE customer_id = ? AND role = 'customer' LIMIT 1");
            $ps->execute([$r['customer_id']]);
            $userId = $ps->fetchColumn();
            if (!$userId) { $skipped++; continue; }

            $groupNum = $r['group_number'] ?? $r['group_name'] ?? 'Chit Group';
            $groupName = $r['group_name'] ?? '';
            $title = 'Chit Contribution Due';
            $body  = 'Your monthly contribution of ₹' . number_format((float)($r['contribution_amount'] ?? 0), 0)
                   . ' for chit group ' . $groupNum . ($groupName ? ' (' . $groupName . ')' : '')
                   . ' is due on ' . ($r['due_date'] ?? 'soon') . '.';

            $dupe = $pdo->prepare("
                SELECT COUNT(*) FROM notifications
                WHERE user_id = ? AND message = ? AND DATE(created_at) = CURDATE()
            ");
            $dupe->execute([$userId, $body]);
            if ((int)$dupe->fetchColumn() > 0) { $skipped++; continue; }

            $ins = $pdo->prepare("
                INSERT INTO notifications (id, user_id, title, message, type, `read`, created_at)
                VALUES (?, ?, ?, ?, 'reminder', 0, NOW())
            ");
            $ins->execute([uuid4(), $userId, $title, $body]);
            $sent++;
        }
        return ['sent' => $sent, 'skipped' => $skipped];
    }
}
