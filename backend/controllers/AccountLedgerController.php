<?php
// ============================================================
//  AccountLedgerController — Executive Account Book & Working Capital
//  Role enforcement:
//    - Read:   Authenticated users (Admin sees full details).
//    - Create: Admin only (validates positive amount, title, type).
//    - Update: Admin only.
//    - Delete: Admin only.
//    - Actions:
//        ?action=summary / ?action=net_balance -> Live real-time calculations.
//        ?action=stream / ?action=transactions -> Unified transaction history.
// ============================================================

class AccountLedgerController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        // 1. Specialized GET Actions
        if ($method === 'GET') {
            $action = $_GET['action'] ?? '';
            if ($action === 'summary' || $action === 'net_balance') {
                json_out(AccountLedger::getRealtimeSummary());
            } elseif ($action === 'stream' || $action === 'transactions') {
                $limit  = max(1, min(500, (int)($_GET['limit'] ?? 500)));
                $offset = max(0, (int)($_GET['offset'] ?? 0));
                $type   = $_GET['type'] ?? null;
                json_out(AccountLedger::getUnifiedTransactions($limit, $offset, $type));
            } elseif ($action === 'outstanding' || $action === 'debtors') {
                json_out(AccountLedger::getOutstandingDebtors());
            }
        }

        // 2. Strict Role Enforcement for Writes
        if ($method === 'POST' || $method === 'PATCH' || $method === 'PUT' || $method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only administrators can create, modify, or delete account book ledger entries', 403);
            }
        }

        // 3. Validation & Sanitization for incoming data
        if ($method === 'POST' || $method === 'PATCH' || $method === 'PUT') {
            $this->validateAndSanitize();
        }

        parent::handle();
    }

    /**
     * Ensure entries have valid dates, types, sanitized titles and non-negative numbers.
     */
    private function validateAndSanitize(): void
    {
        $body = $this->body();
        $isList = $body !== [] && array_keys($body) === range(0, count($body) - 1);
        $rows = $isList ? $body : [$body];
        $changed = false;

        foreach ($rows as &$row) {
            if (!is_array($row)) continue;

            // Trim fields
            if (isset($row['title'])) {
                $row['title'] = trim((string)$row['title']);
            }
            if (isset($row['category'])) {
                $row['category'] = trim((string)$row['category']);
                if ($row['category'] === '') {
                    $row['category'] = 'General';
                }
            }
            if (empty($row['entry_date'])) {
                $row['entry_date'] = date('Y-m-d');
                $changed = true;
            }

            // If POST, validate strictly
            if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
                $errors = AccountLedger::validateEntry($row);
                if (!empty($errors)) {
                    json_error(implode('; ', $errors), 422);
                }
            } elseif (isset($row['amount']) && (float)$row['amount'] <= 0) {
                json_error('Amount must be greater than zero', 422);
            }

            $changed = true;
        }
        unset($row);

        if ($changed) {
            set_json_body($isList ? $rows : $rows[0]);
        }
    }
}
