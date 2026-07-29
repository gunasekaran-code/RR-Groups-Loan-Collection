<?php
// Overdue is a *derived* view, not a stored table: an account is overdue when a
// loan has one or more repayment_schedule installments whose due date has passed
// and which aren't fully paid. This model computes that live from the database
// and can reconcile each loan's status column so dashboards stay consistent.

class Overdue extends Model
{
    // Reuse the loans table for column metadata; reads use the custom query below.
    protected static string $table = 'loans';

    /**
     * Live list of overdue accounts with days-overdue and the outstanding
     * past-due amount, joined to customer contact details. Newest-overdue first.
     */
    public static function accounts(): array
    {
        $today = date('Y-m-d');
        $sql = "
            SELECT
                l.id                         AS loan_id,
                l.loan_number,
                l.customer_id,
                l.customer_name,
                l.loan_amount,
                l.emi,
                l.outstanding_balance,
                l.status,
                l.agent_name,
                l.assigned_agent,
                c.mobile,
                c.address,
                COUNT(s.id)                  AS overdue_installments,
                COALESCE(SUM(s.balance), 0)  AS overdue_amount,
                MIN(s.due_date)              AS earliest_due_date,
                DATEDIFF(?, MIN(s.due_date)) AS days_overdue
            FROM loans l
            JOIN repayment_schedule s
                ON s.loan_id = l.id AND s.due_date < ? AND s.status <> 'paid'
            LEFT JOIN customers c ON c.id = l.customer_id
            WHERE l.status <> 'closed'
            GROUP BY l.id
            HAVING overdue_amount > 0
            ORDER BY days_overdue DESC, overdue_amount DESC
        ";
        $stmt = Database::pdo()->prepare($sql);
        $stmt->execute([$today, $today]);
        $rows = $stmt->fetchAll();

        // Coerce numeric strings PDO returns into real numbers for the JSON API.
        foreach ($rows as &$r) {
            foreach (['loan_amount', 'emi', 'outstanding_balance', 'overdue_amount'] as $n) {
                if (isset($r[$n])) $r[$n] = (float)$r[$n];
            }
            $r['overdue_installments'] = (int)$r['overdue_installments'];
            $r['days_overdue'] = (int)$r['days_overdue'];
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
        $today = date('Y-m-d');
        $pdo = Database::pdo();

        $toOverdue = $pdo->prepare("
            UPDATE loans l SET l.status = 'overdue'
            WHERE l.status = 'active'
              AND EXISTS (
                SELECT 1 FROM repayment_schedule s
                WHERE s.loan_id = l.id AND s.due_date < ? AND s.status <> 'paid'
              )
        ");
        $toOverdue->execute([$today]);
        $changed = $toOverdue->rowCount();

        $toActive = $pdo->prepare("
            UPDATE loans l SET l.status = 'active'
            WHERE l.status = 'overdue'
              AND NOT EXISTS (
                SELECT 1 FROM repayment_schedule s
                WHERE s.loan_id = l.id AND s.due_date < ? AND s.status <> 'paid'
              )
        ");
        $toActive->execute([$today]);
        return $changed + $toActive->rowCount();
    }
}
