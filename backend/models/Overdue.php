<?php
// Overdue is a *derived* view, not a stored table: an account is overdue when a
// loan has one or more repayment_schedule installments whose due date has passed
// and which aren't fully paid. This model computes that live from the database
// and can reconcile each loan's status column so dashboards stay consistent.

class Overdue extends Model
{
    // Reuse the loans table for column metadata; reads use the custom query below.
    protected static string $table = 'loans';
    private static bool $schemaChecked = false;

    public static function ensureSchema(): void
    {
        if (self::$schemaChecked) return;
        self::$schemaChecked = true;
        $pdo = Database::pdo();
        try {
            $cols = $pdo->query("SHOW COLUMNS FROM `loans` LIKE 'penalty_enabled'")->fetchAll();
            if (empty($cols)) {
                $pdo->exec("ALTER TABLE `loans` ADD COLUMN `penalty_enabled` TINYINT(1) NOT NULL DEFAULT 0");
            }
            $cols = $pdo->query("SHOW COLUMNS FROM `loans` LIKE 'penalty_rate_per_day'")->fetchAll();
            if (empty($cols)) {
                $pdo->exec("ALTER TABLE `loans` ADD COLUMN `penalty_rate_per_day` DECIMAL(10,2) NOT NULL DEFAULT 0.00");
            }
            $cols = $pdo->query("SHOW COLUMNS FROM `loans` LIKE 'penalty_amount'")->fetchAll();
            if (empty($cols)) {
                $pdo->exec("ALTER TABLE `loans` ADD COLUMN `penalty_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00");
            }
            $cols = $pdo->query("SHOW COLUMNS FROM `repayment_schedule` LIKE 'penalty_amount'")->fetchAll();
            if (empty($cols)) {
                $pdo->exec("ALTER TABLE `repayment_schedule` ADD COLUMN `penalty_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00");
            }
        } catch (Throwable $e) {
            // Ignore error
        }
    }

    /**
     * Live list of overdue accounts with days-overdue and the outstanding
     * past-due amount, joined to customer contact details. Newest-overdue first.
     */
    public static function accounts(): array
    {
        self::ensureSchema();
        $today = date('Y-m-d');
        $sql = "
            SELECT
                l.id                         AS loan_id,
                l.loan_number,
                l.customer_id,
                l.customer_name,
                l.loan_amount,
                l.loan_type,
                l.emi,
                l.outstanding_balance,
                l.penalty_amount             AS loan_penalty_amount,
                l.penalty_enabled,
                l.penalty_rate_per_day,
                l.status,
                l.agent_name,
                l.assigned_agent,
                c.mobile,
                c.address,
                COUNT(s.id)                  AS overdue_installments,
                COALESCE(SUM(s.balance), 0)  AS overdue_amount,
                COALESCE(SUM(s.penalty_amount), 0) AS accrued_penalty,
                MIN(s.due_date)              AS earliest_due_date,
                DATEDIFF(?, MIN(s.due_date)) AS days_overdue
            FROM loans l
            JOIN repayment_schedule s
                ON s.loan_id = l.id AND s.delflag = 0 AND s.due_date < ? AND s.status <> 'paid'
            LEFT JOIN customers c ON c.id = l.customer_id AND c.delflag = 0
            WHERE l.delflag = 0 AND l.status <> 'closed'
            GROUP BY
                l.id, l.loan_number, l.customer_id, l.customer_name, l.loan_amount,
                l.loan_type, l.emi, l.outstanding_balance, l.penalty_amount,
                l.penalty_enabled, l.penalty_rate_per_day, l.status, l.agent_name,
                l.assigned_agent, c.mobile, c.address
            HAVING overdue_amount > 0
            ORDER BY days_overdue DESC, overdue_amount DESC
        ";
        $stmt = Database::pdo()->prepare($sql);
        $stmt->execute([$today, $today]);
        $rows = $stmt->fetchAll();

        // Coerce numeric strings PDO returns into real numbers for the JSON API.
        foreach ($rows as &$r) {
            foreach (['loan_amount', 'emi', 'outstanding_balance', 'overdue_amount', 'loan_penalty_amount', 'accrued_penalty', 'penalty_rate_per_day'] as $n) {
                if (isset($r[$n])) $r[$n] = (float)$r[$n];
            }
            $r['overdue_installments'] = (int)$r['overdue_installments'];
            $r['days_overdue'] = (int)$r['days_overdue'];
            $r['penalty_enabled'] = !empty($r['penalty_enabled']);

            $isWeekly = (($r['loan_type'] ?? '') === 'weekly');
            $penaltyEnabled = !empty($r['penalty_enabled']);
            $penaltyRatePerDay = (float)($r['penalty_rate_per_day'] ?? 0);

            $weeklyPenaltyPerMissed = $isWeekly && $r['loan_amount'] > 0 ? max(100.0, round($r['loan_amount'] * 0.01, 2)) : 0.0;
            if ($isWeekly) {
                $penalty = (float)($r['overdue_installments'] * $weeklyPenaltyPerMissed);
            } elseif ($penaltyEnabled && $penaltyRatePerDay > 0) {
                $penalty = (float)round($r['days_overdue'] * $penaltyRatePerDay, 2);
            } else {
                $penalty = (float)($r['accrued_penalty'] ?? 0.0);
            }

            $r['penalty_amount'] = (float)$penalty;
            $r['weekly_penalty_rate'] = (float)$weeklyPenaltyPerMissed;
            $r['total_due_with_penalty'] = round($r['overdue_amount'] + $penalty, 2);
        }
        return $rows;
    }

    /**
     * Reconcile loans.status against the schedule so time-based overdues are
     * reflected without waiting for a payment event:
     *   active → overdue  when a past-due unpaid installment exists,
     *   overdue → active  when none remain (and the loan isn't closed).
     * Returns the number of loans whose status changed.
     */
    public static function recompute(): int
    {
        self::ensureSchema();
        $today = date('Y-m-d');
        $pdo = Database::pdo();

        $toOverdue = $pdo->prepare("
            UPDATE loans l SET l.status = 'overdue'
            WHERE l.delflag = 0 AND l.status = 'active'
              AND EXISTS (
                SELECT 1 FROM repayment_schedule s
                WHERE s.loan_id = l.id AND s.delflag = 0 AND s.due_date < ? AND s.status <> 'paid'
              )
        ");
        $toOverdue->execute([$today]);
        $changed = $toOverdue->rowCount();

        $toActive = $pdo->prepare("
            UPDATE loans l SET l.status = 'active'
            WHERE l.delflag = 0 AND l.status = 'overdue'
              AND NOT EXISTS (
                SELECT 1 FROM repayment_schedule s
                WHERE s.loan_id = l.id AND s.delflag = 0 AND s.due_date < ? AND s.status <> 'paid'
              )
        ");
        $toActive->execute([$today]);
        return $changed + $toActive->rowCount();
    }
}
