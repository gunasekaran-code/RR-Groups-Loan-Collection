<?php
// One-time (idempotent) backfill: funds that were collected BEFORE the passbook
// feature existed have a collected_amount but no fund_payments rows. This
// reconstructs passbook entries for the gap, split into weekly instalments and
// clearly marked as opening entries.  Safe to re-run: only fills what's missing.
require_once __DIR__ . '/bootstrap.php';

$pdo = Database::pdo();
$funds = $pdo->query("SELECT * FROM funds WHERE collected_amount > 0")->fetchAll();

$created = 0;
$touched = 0;
foreach ($funds as $f) {
    $existing = $pdo->prepare(
        "SELECT COALESCE(SUM(amount),0) AS s, COUNT(*) AS c FROM fund_payments WHERE fund_id = ?"
    );
    $existing->execute([$f['id']]);
    $row = $existing->fetch();
    $paidSum = (float)$row['s'];
    $paidCnt = (int)$row['c'];

    $gap = round((float)$f['collected_amount'] - $paidSum, 2);
    if ($gap <= 0.01) continue; // already reconciled

    $touched++;
    $weekly = (float)$f['weekly_amount'];
    if ($weekly <= 0) $weekly = $gap; // fall back to a single entry
    $startStr = $f['start_date'] ?: substr((string)$f['created_at'], 0, 10);
    $start = $startStr ? new DateTime($startStr) : new DateTime();

    $remaining = $gap;
    $weekNo = $paidCnt;              // continue numbering after any real entries
    $balance = $paidSum;
    while ($remaining > 0.01) {
        $amt = min($weekly, $remaining);
        $weekNo++;
        $balance = round($balance + $amt, 2);
        $remaining = round($remaining - $amt, 2);

        // Date this instalment: start + (weekNo-1) weeks, capped at today.
        $d = clone $start;
        $d->modify('+' . ($weekNo - 1) . ' weeks');
        $today = new DateTime();
        if ($d > $today) $d = $today;

        FundPayment::insertRows([[
            'fund_id'        => $f['id'],
            'fund_number'    => $f['fund_number'],
            'customer_id'    => $f['customer_id'],
            'customer_name'  => $f['customer_name'],
            'week_no'        => $weekNo,
            'amount'         => $amt,
            'balance_after'  => $balance,
            'payment_method' => 'cash',
            'payment_date'   => $d->format('Y-m-d'),
            'agent_name'     => null,
            'notes'          => 'Opening entry — recorded before passbook',
        ]]);
        $created++;
    }
}

echo "Funds reconciled: $touched\n";
echo "Passbook entries created: $created\n";
echo "Backfill complete.\n";
