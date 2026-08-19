<?php
// Seed / reset demo accounts + sample business data.
// Run after schema.sql (fresh) or migrate.php (existing):  php seed.php
require_once __DIR__ . '/bootstrap.php';

$pdo = Database::pdo();

// ---- fixed demo IDs (stable so re-running is idempotent) ----
const AGENT_ID    = 'c834ac54-bcb6-442e-a99f-9b7c144dee24';
const CUSTOMER_ID = 'c1000000-0000-4000-8000-000000000001'; // customers row
const CUST_PROF   = 'd0000000-0000-4000-8000-000000000004'; // customer login profile
const LOAN_ID     = 'e1000000-0000-4000-8000-000000000001';

// ---------------- accounts ----------------
// [id, email, password, name, mobile, role, customer_id, user_code]
$accounts = [
    ['f46ac1bf-6f72-49a3-aadc-dc7583c5cd77', 'admin@fincollect.in', 'admin123', 'Priya Sharma',  '9876543211', 'admin',    null,        'RRG-ADM-0001'],
    [AGENT_ID,                               'agent@fincollect.in', 'agent123', 'Arjun Mehta',   '9876543212', 'agent',    null,        'RRG-STF-0001'],
    [CUST_PROF,                              'customer@fincollect.in', 'customer123', 'Ramesh Iyer', '9876500000', 'customer', CUSTOMER_ID, 'RRG-CUS-0001'],
];

$acctSql = 'INSERT INTO profiles (id, email, password_hash, full_name, mobile, role, customer_id, user_code, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, "active")
            ON DUPLICATE KEY UPDATE
              password_hash = VALUES(password_hash),
              full_name     = VALUES(full_name),
              mobile        = VALUES(mobile),
              role          = VALUES(role),
              customer_id   = VALUES(customer_id),
              user_code     = VALUES(user_code),
              status        = "active"';
$stmt = $pdo->prepare($acctSql);
foreach ($accounts as [$id, $email, $pass, $name, $mobile, $role, $custId, $userCode]) {
    $stmt->execute([$id, $email, password_hash($pass, PASSWORD_BCRYPT), $name, $mobile, $role, $custId, $userCode]);
    echo "Seeded $email ($role)  code: $userCode  password: $pass\n";
}

// ---------------- demo customer record ----------------
$pdo->prepare(
    'INSERT INTO customers (id, customer_id, full_name, mobile, address, occupation, loan_status, assigned_agent)
     VALUES (?, "RRG-CUS-0001", "Ramesh Iyer", "9876500000", "12 Gandhi St, Chennai", "Shop Owner", "active", ?)
     ON DUPLICATE KEY UPDATE full_name = VALUES(full_name), customer_id = VALUES(customer_id), loan_status = VALUES(loan_status), assigned_agent = VALUES(assigned_agent)'
)->execute([CUSTOMER_ID, AGENT_ID]);

// ---------------- demo loan ----------------
$principal = 50000; $monthlyRate = 3; $months = 10; $paidInstallments = 2;
$monthlyInterest = $principal * ($monthlyRate / 100); // 1500/mo
$emi = ($principal / $months) + $monthlyInterest; // 6500/mo
$totalInterest = $monthlyInterest * $months; // 15000
$totalRepayment = $principal + $totalInterest; // 65000
$outstanding = $totalRepayment - ($emi * $paidInstallments); // 52000

$pdo->prepare(
    'INSERT INTO loans (id, loan_number, customer_id, customer_name, loan_amount, interest_percentage,
        loan_duration, loan_type, start_date, assigned_agent, agent_name, processing_fee, emi,
        total_interest, total_repayment, outstanding_balance, status)
     VALUES (?, "LN-100001", ?, "Ramesh Iyer", ?, ?, ?, "monthly", DATE_SUB(CURDATE(), INTERVAL 2 MONTH),
        ?, "Arjun Mehta", 500, ?, ?, ?, ?, "active")
     ON DUPLICATE KEY UPDATE loan_amount = VALUES(loan_amount), interest_percentage = VALUES(interest_percentage), emi = VALUES(emi), total_interest = VALUES(total_interest), total_repayment = VALUES(total_repayment), outstanding_balance = VALUES(outstanding_balance), status = VALUES(status)'
)->execute([LOAN_ID, CUSTOMER_ID, $principal, $monthlyRate, $months, AGENT_ID, $emi, $totalInterest, $totalRepayment, $outstanding]);

// ---------------- repayment schedule (rebuild) ----------------
$pdo->prepare('DELETE FROM repayment_schedule WHERE loan_id = ?')->execute([LOAN_ID]);
$schStmt = $pdo->prepare(
    'INSERT INTO repayment_schedule (id, loan_id, installment_no, due_date, emi_amount, paid_amount, balance, status)
     VALUES (?, ?, ?, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 2 MONTH), INTERVAL ? MONTH), ?, ?, ?, ?)'
);
for ($i = 1; $i <= $months; $i++) {
    $paid   = $i <= $paidInstallments ? $emi : 0;
    $balance = $i <= $paidInstallments ? 0 : $emi;
    $status = $i <= $paidInstallments ? 'paid' : 'pending';
    $schStmt->execute([sprintf('a1000000-0000-4000-8000-%012d', $i), LOAN_ID, $i, $i - 1, $emi, $paid, $balance, $status]);
}

// ---------------- collections (rebuild the two paid ones) ----------------
$pdo->prepare('DELETE FROM collections WHERE loan_id = ?')->execute([LOAN_ID]);
$colStmt = $pdo->prepare(
    'INSERT INTO collections (id, receipt_number, loan_id, customer_id, customer_name, loan_number,
        collection_amount, payment_method, collection_date, agent_id, agent_name)
     VALUES (?, ?, ?, ?, "Ramesh Iyer", "LN-100001", ?, "cash",
        DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 2 MONTH), INTERVAL ? MONTH), ?, "Arjun Mehta")'
);
for ($i = 1; $i <= $paidInstallments; $i++) {
    $colStmt->execute([
        sprintf('f1000000-0000-4000-8000-%012d', $i),
        'RC-' . str_pad((string)$i, 5, '0', STR_PAD_LEFT),
        LOAN_ID, CUSTOMER_ID, $emi, $i - 1, AGENT_ID,
    ]);
}

echo "Sample customer, loan, schedule and collections seeded.\n";
echo "Done.\n";
