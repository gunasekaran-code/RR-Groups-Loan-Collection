<?php
class Loan extends Model
{
    protected static string $table = 'loans';

    /**
     * Sequential HP Number starting at RR001, auto-incrementing sequentially
     * (RR002, RR003, etc.) based on existing database entries.
     */
    public static function nextLoanNumber(): string
    {
        $pdo = Database::pdo();
        $stmt = $pdo->query("SELECT loan_number FROM loans WHERE loan_number LIKE 'RR%'");
        $numbers = $stmt->fetchAll(PDO::FETCH_COLUMN);

        $max = 0;
        foreach ($numbers as $num) {
            if (preg_match('/^RR(\d+)$/i', trim($num), $m)) {
                $val = (int)$m[1];
                if ($val > $max) {
                    $max = $val;
                }
            }
        }

        $next = $max + 1;
        return 'RR' . str_pad((string)$next, 3, '0', STR_PAD_LEFT);
    }
}
