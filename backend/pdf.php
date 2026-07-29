<?php
// Entry point → server-generated PDF documents.
//   GET /backend/pdf.php?doc=loan_application&loan_id=<uuid>[&download=1]
// Auth: Bearer JWT. Admin/agent may fetch any loan's form; a customer only their
// own. Data is read live from the database on every request.
require_once __DIR__ . '/bootstrap.php';
send_cors();
require_once __DIR__ . '/lib/loan_application_pdf.php';

$token  = bearer_token();
$claims = $token ? Jwt::decode($token) : null;
if (!$claims) {
    json_error('Missing or invalid token', 401);
}
$role = $claims['role'] ?? '';

$doc = $_GET['doc'] ?? 'loan_application';
if ($doc !== 'loan_application') {
    json_error("Unknown document: $doc", 404);
}

$loanId = $_GET['loan_id'] ?? ($_GET['id'] ?? '');
if ($loanId === '') {
    json_error('loan_id is required', 400);
}

$loanRows = Loan::select(' WHERE id = ?', [$loanId], '', ' LIMIT 1');
$loan = $loanRows[0] ?? null;
if (!$loan) {
    json_error('Loan not found', 404);
}

// A customer may only download their own loan's application form.
if ($role === 'customer') {
    $me = Profile::findPublic($claims['sub'] ?? '');
    $myCustomerId = $me['customer_id'] ?? null;
    if (!$myCustomerId || $myCustomerId !== ($loan['customer_id'] ?? null)) {
        json_error('Not allowed to view this loan', 403);
    }
}

$customer = null;
if (!empty($loan['customer_id'])) {
    $cr = Customer::select(' WHERE id = ?', [$loan['customer_id']], '', ' LIMIT 1');
    $customer = $cr[0] ?? null;
}

$settingsRows = Setting::select('', [], '', ' LIMIT 1');
$company = $settingsRows[0] ?? [];

$bytes = build_loan_application_pdf($loan, $customer, $company);

$safe = preg_replace('/[^A-Za-z0-9_-]/', '', (string)($loan['loan_number'] ?? 'form'));
$filename = "Loan-Application-$safe.pdf";
$disposition = (($_GET['download'] ?? '') === '1') ? 'attachment' : 'inline';

header('Content-Type: application/pdf');
header("Content-Disposition: $disposition; filename=\"$filename\"");
header('Content-Length: ' . strlen($bytes));
header('Cache-Control: no-store');
echo $bytes;
