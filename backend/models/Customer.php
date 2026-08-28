<?php
class Customer extends Model
{
    protected static string $table = 'customers';

    /**
     * Recompute `customers.loan_status` from the loans that actually exist.
     *
     * The column is denormalised and was only ever written by seed.php, so it
     * never moved off 'none' — a customer with a live loan still showed
     * "No Loan" in the directory. It is kept up to date here instead of being
     * derived at read time because the Customers screen filters and counts on
     * it, and a subquery on every list would not survive the generic model.
     *
     * Precedence: any overdue loan wins, then active, then closed, else none.
     * Soft-deleted loans are ignored — a deleted loan is not a live one.
     *
     * @param string[]|null $customerIds  null recomputes every customer.
     */
    public static function recalcLoanStatus(?array $customerIds = null): void
    {
        $ids = null;
        if ($customerIds !== null) {
            $ids = array_values(array_unique(array_filter($customerIds)));
            if (!$ids) return;
        }

        $scope = '';
        $binds = [];
        if ($ids !== null) {
            $scope = ' WHERE c.id IN (' . implode(',', array_fill(0, count($ids), '?')) . ')';
            $binds = $ids;
        }

        // One statement so a customer with many loans cannot be half-updated.
        $sql = "
            UPDATE customers c
            SET c.loan_status = (
                SELECT CASE
                    WHEN SUM(l.status = 'overdue') > 0 THEN 'overdue'
                    WHEN SUM(l.status = 'active')  > 0 THEN 'active'
                    WHEN COUNT(*) > 0              THEN 'closed'
                    ELSE 'none'
                END
                FROM loans l
                WHERE l.customer_id = c.id AND l.delflag = 0
            )
            $scope
        ";

        try {
            Database::pdo()->prepare($sql)->execute($binds);
        } catch (\Throwable $e) {
            // Never let a status refresh break the write that triggered it.
            error_log('Customer::recalcLoanStatus failed: ' . $e->getMessage());
        }
    }

    /** Customer ids referenced by the given loan ids (for a targeted recalc). */
    public static function idsForLoans(array $loanIds): array
    {
        $loanIds = array_values(array_unique(array_filter($loanIds)));
        if (!$loanIds) return [];

        $ph = implode(',', array_fill(0, count($loanIds), '?'));
        try {
            $stmt = Database::pdo()->prepare(
                "SELECT DISTINCT customer_id FROM loans WHERE id IN ($ph) AND customer_id IS NOT NULL"
            );
            $stmt->execute($loanIds);
            return $stmt->fetchAll(PDO::FETCH_COLUMN, 0) ?: [];
        } catch (\Throwable $e) {
            return [];
        }
    }
}
