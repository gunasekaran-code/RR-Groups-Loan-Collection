<?php
class Loan extends Model
{
    protected static string $table = 'loans';

    /**
     * A unique loan number in the app's LN-######## style. Used as a server-side
     * fallback when a loan is created without one. Time-based so it can't collide
     * with the random numbers the frontend generates.
     */
    public static function nextLoanNumber(): string
    {
        return 'LN-' . substr((string) (int) (microtime(true) * 1000), -8);
    }
}
