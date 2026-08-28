<?php
/**
 * Authoritative loan recalculation — the single source of truth for a loan's
 * live figures (repayment schedule, outstanding balance, monthly interest).
 *
 * This used to run only in the browser (frontend/src/schedule.ts), so a
 * collection recorded from anywhere else — the agent app, a direct API call, an
 * import, a second tab — left the loan card showing stale numbers. Running it
 * here, inside the request that writes the payment, makes the database itself
 * correct so every client reads live data.
 *
 * Idempotent: it always recomputes from the current set of collections, so it
 * stays right after a payment is edited or deleted.
 */
class LoanRecalc
{
    /** Recompute every loan touched by a set of loan ids. */
    public static function syncMany(array $loanIds): void
    {
        $loanIds = array_unique(array_filter($loanIds));
        foreach ($loanIds as $id) {
            try {
                self::sync((string)$id);
            } catch (\Throwable $e) {
                // A recalc failure must never fail the payment that triggered it.
                error_log('LoanRecalc failed for loan ' . $id . ': ' . $e->getMessage());
            }
        }

        // A payment can close a loan or push it overdue, which changes what
        // the customer directory should show next to that customer.
        if ($loanIds) {
            Customer::recalcLoanStatus(Customer::idsForLoans(array_values($loanIds)));
        }
    }

    public static function sync(string $loanId): void
    {
        if ($loanId === '') return;
        $pdo = Database::pdo();

        $stmt = $pdo->prepare('SELECT * FROM `loans` WHERE `id` = ? LIMIT 1');
        $stmt->execute([$loanId]);
        $loan = $stmt->fetch();
        if (!$loan) return;

        $stmt = $pdo->prepare(
            'SELECT `collection_amount`, `notes`, `collection_date`
               FROM `collections` WHERE `loan_id` = ?
              ORDER BY `collection_date` ASC, `created_at` ASC'
        );
        $stmt->execute([$loanId]);
        $collections = $stmt->fetchAll();

        $stmt = $pdo->prepare(
            'SELECT * FROM `repayment_schedule` WHERE `loan_id` = ? ORDER BY `installment_no` ASC'
        );
        $stmt->execute([$loanId]);
        $rows = $stmt->fetchAll();

        if (($loan['loan_type'] ?? '') === 'monthly_interest') {
            self::syncMonthlyInterest($pdo, $loan, $collections, $rows);
        } else {
            self::syncRegular($pdo, $loan, $collections, $rows);
        }
    }

    private static function round2(float $n): float
    {
        return round($n, 2);
    }

    /**
     * Split one payment into principal / interest using the note the collector
     * chose in the UI ("Principal Part-Payment", "Monthly Interest Payment").
     * Unlabelled payments settle the current month's interest first and only
     * then bite into principal.
     */
    private static function classify(string $notes): string
    {
        $n = mb_strtolower($notes);
        if (str_contains($n, 'principal') || str_contains($n, "\u{0B85}\u{0B9A}\u{0BB2}\u{0BCD}") || str_contains($n, 'part-payment')) {
            return 'principal';
        }
        if (str_contains($n, 'interest') || str_contains($n, "\u{0BB5}\u{0B9F}\u{0BCD}\u{0B9F}\u{0BBF}")) {
            return 'interest';
        }
        return 'general';
    }

    /**
     * BRANCH A — Monthly interest loans (maatha vatti / மாத வட்டி).
     * Principal repayment is flexible; the monthly interest is always
     * recalculated against whatever principal is still outstanding, so paying
     * down principal immediately lowers the monthly due.
     */
    private static function syncMonthlyInterest(PDO $pdo, array $loan, array $collections, array $rows): void
    {
        $ratePct = (float)($loan['interest_percentage'] ?? 0);
        $remainingPrincipal = (float)($loan['loan_amount'] ?? 0);
        $availableInterestPaid = 0.0;

        foreach ($collections as $c) {
            $amt = (float)($c['collection_amount'] ?? 0);
            if ($amt <= 0) continue;

            switch (self::classify((string)($c['notes'] ?? ''))) {
                case 'principal':
                    $pPay = min($remainingPrincipal, $amt);
                    $remainingPrincipal = max(0.0, $remainingPrincipal - $pPay);
                    $availableInterestPaid += ($amt - $pPay);
                    break;

                case 'interest':
                    $availableInterestPaid += $amt;
                    break;

                default:
                    $curMonthlyInterest = self::round2($remainingPrincipal * ($ratePct / 100));
                    if ($amt <= $curMonthlyInterest) {
                        $availableInterestPaid += $amt;
                    } else {
                        $availableInterestPaid += $curMonthlyInterest;
                        $excess = $amt - $curMonthlyInterest;
                        $pPay = min($remainingPrincipal, $excess);
                        $remainingPrincipal = max(0.0, $remainingPrincipal - $pPay);
                        $availableInterestPaid += ($excess - $pPay);
                    }
                    break;
            }
        }

        $remainingPrincipal = self::round2($remainingPrincipal);
        $newMonthlyInterest = $remainingPrincipal > 0
            ? self::round2($remainingPrincipal * ($ratePct / 100))
            : 0.0;

        self::writeInterestSchedule($pdo, $rows, $remainingPrincipal, $newMonthlyInterest, $availableInterestPaid);

        // For this loan type the real debt is the remaining principal, and the
        // emi column carries the *current* monthly interest.
        self::writeLoan($pdo, $loan, $remainingPrincipal, $newMonthlyInterest);
    }

    private static function writeInterestSchedule(
        PDO $pdo,
        array $rows,
        float $remainingPrincipal,
        float $newMonthlyInterest,
        float $interestPool
    ): void {
        if (!$rows) return;
        $today = date('Y-m-d');

        foreach ($rows as $r) {
            $oldEmi = (float)($r['emi_amount'] ?? 0);
            $targetEmi = $newMonthlyInterest;
            $paid = 0.0;
            $balance = 0.0;
            $status = 'pending';

            if ($oldEmi > 0 && $interestPool >= $oldEmi) {
                // Historical instalment already settled — keep it as billed.
                $paid = $oldEmi;
                $targetEmi = $oldEmi;
                $status = 'paid';
                $interestPool -= $oldEmi;
            } elseif ($interestPool > 0) {
                $paid = $interestPool;
                $balance = max(0.0, self::round2($newMonthlyInterest - $paid));
                $status = 'partial';
                $interestPool = 0.0;
            } elseif ($remainingPrincipal <= 0.01) {
                // Principal is cleared, so no further interest can accrue.
                $targetEmi = 0.0;
                $status = 'paid';
            } else {
                $balance = $newMonthlyInterest;
                $status = (!empty($r['due_date']) && $r['due_date'] < $today) ? 'overdue' : 'pending';
            }

            $paid = self::round2($paid);
            $targetEmi = self::round2($targetEmi);
            $balance = self::round2($balance);

            if ((float)$r['emi_amount'] !== $targetEmi
                || (float)$r['paid_amount'] !== $paid
                || (float)$r['balance'] !== $balance
                || $r['status'] !== $status
            ) {
                $pdo->prepare(
                    'UPDATE `repayment_schedule`
                        SET `emi_amount` = ?, `paid_amount` = ?, `balance` = ?, `status` = ?
                      WHERE `id` = ?'
                )->execute([$targetEmi, $paid, $balance, $status, $r['id']]);
            }
        }
    }

    /**
     * BRANCH B — Monthly EMI, weekly and daily loans.
     * Total collected cascades over the instalments oldest-first.
     * Automatic weekly penalty (₹100 per ₹10,000 loan per missed week) is computed for overdue weekly installments.
     */
    private static function syncRegular(PDO $pdo, array $loan, array $collections, array $rows): void
    {
        $totalCollected = 0.0;
        foreach ($collections as $c) {
            $totalCollected += (float)($c['collection_amount'] ?? 0);
        }

        $isWeekly = (($loan['loan_type'] ?? '') === 'weekly');
        $penaltyEnabled = !empty($loan['penalty_enabled']);
        $penaltyRatePerDay = (float)($loan['penalty_rate_per_day'] ?? 0);
        $loanAmount = (float)($loan['loan_amount'] ?? 0);

        // Weekly penalty per missed week. A manually entered penalty_per_week wins;
        // 0 falls back to the original automatic rate (1% of principal, min ₹100)
        // so loans created before the column existed are unaffected.
        $manualWeekly = (float)($loan['penalty_per_week'] ?? 0);
        $weeklyPenaltyPerMissed = 0.0;
        if ($isWeekly) {
            $weeklyPenaltyPerMissed = $manualWeekly > 0
                ? self::round2($manualWeekly)
                : ($loanAmount > 0 ? max(100.0, self::round2($loanAmount * 0.01)) : 0.0);
        }

        // Without a generated schedule there is nothing to cascade over, but the
        // loan balance must still track payments.
        if (!$rows) {
            $totalDue = (float)($loan['total_repayment'] ?? 0);
            if ($totalDue <= 0) $totalDue = (float)($loan['loan_amount'] ?? 0);
            self::writeLoan($pdo, $loan, max(0.0, self::round2($totalDue - $totalCollected)), null, 0.0);
            return;
        }

        $today = date('Y-m-d');
        $remaining = $totalCollected;
        $totalBalance = 0.0;
        $totalPenalty = 0.0;

        foreach ($rows as $r) {
            $emi = (float)($r['emi_amount'] ?? 0);
            $paid = min($remaining, $emi);
            $remaining = max(0.0, $remaining - $paid);
            $balance = self::round2($emi - $paid);

            $penalty = 0.0;
            $isOverdue = (!empty($r['due_date']) && $r['due_date'] < $today && $paid < $emi);

            if ($isOverdue) {
                if ($isWeekly) {
                    $penalty = $weeklyPenaltyPerMissed;
                } elseif ($penaltyEnabled && $penaltyRatePerDay > 0) {
                    $daysOverdue = max(0, (int)((strtotime($today) - strtotime($r['due_date'])) / 86400));
                    $penalty = self::round2($daysOverdue * $penaltyRatePerDay);
                }
                $totalPenalty += $penalty;
            }

            if ($emi > 0 && $paid >= $emi) {
                $status = 'paid';
            } elseif ($paid > 0) {
                $status = 'partial';
            } elseif (!empty($r['due_date']) && $r['due_date'] < $today) {
                $status = 'overdue';
            } else {
                $status = 'pending';
            }

            $paid = self::round2($paid);
            $totalBalance = self::round2($totalBalance + $balance);

            if ((float)$r['paid_amount'] !== $paid
                || (float)$r['balance'] !== $balance
                || (float)($r['penalty_amount'] ?? 0) !== $penalty
                || $r['status'] !== $status
            ) {
                $pdo->prepare(
                    'UPDATE `repayment_schedule`
                        SET `paid_amount` = ?, `balance` = ?, `penalty_amount` = ?, `status` = ?
                      WHERE `id` = ?'
                )->execute([$paid, $balance, $penalty, $status, $r['id']]);
            }
        }

        $finalOutstanding = self::round2($totalBalance + $totalPenalty);
        self::writeLoan($pdo, $loan, $finalOutstanding, null, $totalPenalty);
    }

    /** Persist the loan's outstanding balance, optional emi, penalty_amount, and derived status. */
    private static function writeLoan(PDO $pdo, array $loan, float $outstanding, ?float $emi, float $penaltyAmount = 0.0): void
    {
        $set = ['`outstanding_balance` = ?', '`penalty_amount` = ?'];
        $binds = [$outstanding, $penaltyAmount];

        if ($emi !== null) {
            $set[] = '`emi` = ?';
            $binds[] = $emi;
        }

        $status = $loan['status'] ?? '';
        if ($outstanding <= 0.01 && $status !== 'closed') {
            $set[] = '`status` = ?';
            $binds[] = 'closed';
        } elseif ($outstanding > 0.01 && $status === 'closed') {
            $set[] = '`status` = ?';
            $binds[] = 'active';
        } elseif ($penaltyAmount > 0 && $status !== 'closed') {
            $set[] = '`status` = ?';
            $binds[] = 'overdue';
        }

        $binds[] = $loan['id'];
        $pdo->prepare('UPDATE `loans` SET ' . implode(', ', $set) . ' WHERE `id` = ?')->execute($binds);
    }
}
