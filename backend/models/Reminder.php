<?php
// Payment reminders are a *derived* view over repayment_schedule + loans +
// customers, driven by the Settings ▸ Payment Reminders configuration
// (reminder_days, reminder_time, reminder_template, auto_reminders_enabled).
// This model lists the EMIs that fall due within the reminder window (plus any
// already-overdue ones) and can dispatch a notification to each customer's
// linked login using the configured template.

class Reminder extends Model
{
    // Borrow repayment_schedule column metadata; reads use the joins below.
    protected static string $table = 'repayment_schedule';

    /**
     * EMIs due within `reminder_days` from today (upcoming) and any past-due
     * unpaid installments, joined to the loan and customer. Soonest first.
     */
    public static function due(int $daysBefore = 3): array
    {
        $daysBefore = max(0, min(60, $daysBefore));
        $today  = date('Y-m-d');
        $window = date('Y-m-d', strtotime("+$daysBefore days"));

        $sql = "
            SELECT
                s.id            AS schedule_id,
                s.loan_id,
                s.installment_no,
                s.due_date,
                s.emi_amount,
                s.balance,
                s.status,
                l.loan_number,
                l.customer_id,
                l.customer_name,
                l.assigned_agent,
                c.mobile,
                DATEDIFF(s.due_date, ?) AS days_until
            FROM repayment_schedule s
            JOIN loans l       ON l.id = s.loan_id AND l.delflag = 0 AND l.status <> 'closed'
            LEFT JOIN customers c ON c.id = l.customer_id AND c.delflag = 0
            WHERE s.delflag = 0 AND s.status <> 'paid'
              AND s.due_date IS NOT NULL
              AND s.due_date <= ?
            ORDER BY s.due_date ASC
        ";
        $stmt = Database::pdo()->prepare($sql);
        $stmt->execute([$today, $window]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($rows as &$r) {
            $r['emi_amount'] = (float)$r['emi_amount'];
            $r['balance']    = (float)$r['balance'];
            $r['days_until'] = (int)$r['days_until'];
            $r['overdue']    = $r['days_until'] < 0;
        }
        return $rows;
    }

    /**
     * Create a reminder notification for each due EMI, addressed to the
     * customer's linked login. Idempotent per day: a loan+installment that
     * already got a reminder today is skipped. Returns the number sent.
     */
    public static function dispatch(array $settings): array
    {
        if (empty($settings['auto_reminders_enabled'])) {
            return ['sent' => 0, 'skipped' => 0, 'reason' => 'auto_reminders_disabled'];
        }
        $days     = (int)($settings['reminder_days'] ?? 3);
        $template = (string)($settings['reminder_template'] ?? '')
            ?: 'Dear Customer, your EMI of {amount} for loan {loan_number} is due on {due_date}. Please pay on time.';

        $pdo  = Database::pdo();
        $rows = self::due($days);
        $sent = 0; $skipped = 0;
        $seenLoans = [];

        foreach ($rows as $r) {
            // One reminder per loan — rows are ordered by due date, so the first
            // row for a loan is its nearest/earliest unpaid installment.
            if (isset($seenLoans[$r['loan_id']])) { continue; }
            $seenLoans[$r['loan_id']] = true;

            if (empty($r['customer_id'])) { $skipped++; continue; }

            // Resolve the customer's login profile.
            $ps = $pdo->prepare("SELECT id FROM profiles WHERE customer_id = ? AND role = 'customer' AND delflag = 0 LIMIT 1");
            $ps->execute([$r['customer_id']]);
            $userId = $ps->fetchColumn();
            if (!$userId) { $skipped++; continue; }

            $title = 'EMI Payment Reminder';
            $body  = strtr($template, [
                '{amount}'      => '₹' . number_format($r['balance'] ?: $r['emi_amount'], 0),
                '{loan_number}' => $r['loan_number'],
                '{due_date}'    => $r['due_date'],
            ]);

            // De-dupe: same loan reminder already created today?
            $dupe = $pdo->prepare("
                SELECT COUNT(*) FROM notifications
                WHERE user_id = ? AND type IN ('reminder','emi_due')
                  AND message = ? AND DATE(created_at) = CURDATE()
            ");
            $dupe->execute([$userId, $body]);
            if ((int)$dupe->fetchColumn() > 0) { $skipped++; continue; }

            $type = $r['overdue'] ? 'overdue' : 'emi_due';
            $ins = $pdo->prepare("
                INSERT INTO notifications (id, user_id, title, message, type, `read`, created_at)
                VALUES (?, ?, ?, ?, ?, 0, NOW())
            ");
            $ins->execute([uuid4(), $userId, $title, $body, $type]);
            $sent++;
        }
        return ['sent' => $sent, 'skipped' => $skipped];
    }
}
