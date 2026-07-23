<?php
// One-time (idempotent) backfill: collections recorded BEFORE the schedule-sync
// feature never updated repayment_schedule, so those installments still show
// Paid ₹0 / Pending. This recomputes each loan's schedule from its actual
// collections using the same earliest-first waterfall as the app.
// Safe to re-run: it only writes rows whose paid/balance/status actually change.
require_once __DIR__ . '/bootstrap.php';

$pdo = Database::pdo();
$today = (new DateTime())->format('Y-m-d');

// Every loan that has at least one schedule row.
$loanIds = $pdo->query(
    "SELECT DISTINCT loan_id FROM repayment_schedule"
)->fetchAll(PDO::FETCH_COLUMN);

$loansTouched = 0;
$rowsUpdated = 0;

foreach ($loanIds as $loanId) {
    // Total collected against this loan.
    $stmt = $pdo->prepare(
        "SELECT COALESCE(SUM(collection_amount),0) FROM collections WHERE loan_id = ?"
    );
    $stmt->execute([$loanId]);
    $remaining = (float)$stmt->fetchColumn();

    // Schedule rows, earliest first.
    $rowsStmt = $pdo->prepare(
        "SELECT * FROM repayment_schedule WHERE loan_id = ? ORDER BY installment_no ASC"
    );
    $rowsStmt->execute([$loanId]);
    $rows = $rowsStmt->fetchAll();

    $loanChanged = false;
    $totalBalance = 0.0;
    foreach ($rows as $r) {
        $emi = (float)$r['emi_amount'];
        $paid = min($remaining, $emi);
        $remaining = max(0, round($remaining - $paid, 2));
        $paid = round($paid, 2);
        $balance = round($emi - $paid, 2);
        $totalBalance = round($totalBalance + $balance, 2);

        if ($paid >= $emi && $emi > 0)      $status = 'paid';
        elseif ($paid > 0)                  $status = 'partial';
        elseif ($r['due_date'] && $r['due_date'] < $today) $status = 'overdue';
        else                                $status = 'pending';

        if ((float)$r['paid_amount'] === $paid
            && (float)$r['balance'] === $balance
            && $r['status'] === $status) {
            continue; // already correct
        }

        $upd = $pdo->prepare(
            "UPDATE repayment_schedule SET paid_amount = ?, balance = ?, status = ? WHERE id = ?"
        );
        $upd->execute([$paid, $balance, $status, $r['id']]);
        $rowsUpdated++;
        $loanChanged = true;
    }

    // Sync the loan's outstanding balance (and closed status) too.
    $lStmt = $pdo->prepare("SELECT outstanding_balance, status FROM loans WHERE id = ?");
    $lStmt->execute([$loanId]);
    $loan = $lStmt->fetch();
    if ($loan) {
        $newStatus = $loan['status'];
        if ($totalBalance <= 0.01 && $loan['status'] !== 'closed') $newStatus = 'closed';
        elseif ($totalBalance > 0.01 && $loan['status'] === 'closed') $newStatus = 'active';
        if ((float)$loan['outstanding_balance'] !== $totalBalance || $newStatus !== $loan['status']) {
            $pdo->prepare("UPDATE loans SET outstanding_balance = ?, status = ? WHERE id = ?")
                ->execute([$totalBalance, $newStatus, $loanId]);
            $loanChanged = true;
        }
    }

    if ($loanChanged) $loansTouched++;
}

echo "Loans reconciled: $loansTouched\n";
echo "Schedule rows updated: $rowsUpdated\n";
echo "Backfill complete.\n";
