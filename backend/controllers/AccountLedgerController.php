<?php
// ============================================================
//  AccountLedgerController — Executive Account Book & Working Capital
//  Role enforcement:
//    - Read:   Admin sees everything. An agent is scoped to their own
//              collection receipts (Cash Handover needs them). Customers are
//              refused outright — the chit passbook used to read this table
//              to find a member's payments, which handed every customer the
//              company cash book. It now reads chit_payments instead.
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

        // 2. Reads are privileged: this table is the company cash book.
        if ($method === 'GET') {
            if ($role === 'agent') {
                // An agent may only ever see money they themselves collected.
                $_GET['agent_id'] = 'eq.' . ($claims['sub'] ?? '');
            } elseif ($role !== 'admin') {
                json_error('Only administrators can read the account book', 403);
            }
        }

        // 3. Strict Role Enforcement for Writes
        //    Agents collect chit / fund / loan money in the field, and that
        //    receipt IS the payment record the passbook and account book read.
        //    Blocking it outright made an agent's collection vanish silently, so
        //    they may POST a cash-in collection receipt — and nothing else.
        if ($method === 'PATCH' || $method === 'PUT' || $method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only administrators can modify or delete account book ledger entries', 403);
            }
        } elseif ($method === 'POST') {
            if ($role === 'agent') {
                $this->assertAgentCollectionOnly();
                $this->pinAgentToSelf($claims);
            } elseif ($role !== 'admin') {
                json_error('Only administrators can create account book ledger entries', 403);
            }
        }

        // 3. Validation & Sanitization for incoming data
        if ($method === 'POST' || $method === 'PATCH' || $method === 'PUT') {
            $this->validateAndSanitize();
        }

        parent::handle();
    }

    /** Field-collection categories an agent is allowed to record. */
    private const AGENT_COLLECTION_CATEGORIES = [
        'chit collection',
        'fund collection',
        'loan collection',
    ];

    /**
     * Stamp the receipt with the agent who is actually recording it.
     *
     * Cash Handover holds an agent accountable for what they collected, so the
     * attribution must come from the token, not from whatever the client sent.
     */
    private function pinAgentToSelf(array $claims): void
    {
        $agentId = $claims['sub'] ?? null;
        if (!$agentId) return;

        $profile = Profile::findPublic($agentId);
        $agentName = $profile['full_name'] ?? null;

        $body = $this->body();
        $isList = $body !== [] && array_keys($body) === range(0, count($body) - 1);
        $rows = $isList ? $body : [$body];

        foreach ($rows as &$row) {
            if (!is_array($row)) continue;
            $row['agent_id'] = $agentId;
            $row['agent_name'] = $agentName;
        }
        unset($row);

        set_json_body($isList ? $rows : $rows[0]);
    }

    /**
     * An agent may only file money *coming in* from a field collection.
     * Anything else — expenses, capital movements, custom lending — stays admin-only.
     */
    private function assertAgentCollectionOnly(): void
    {
        $body = $this->body();
        $isList = $body !== [] && array_keys($body) === range(0, count($body) - 1);
        $rows = $isList ? $body : [$body];

        foreach ($rows as $row) {
            if (!is_array($row)) continue;

            if (($row['entry_type'] ?? '') !== 'cash_in') {
                json_error('Agents can only record incoming collection receipts', 403);
            }
            $category = strtolower(trim((string)($row['category'] ?? '')));
            if (!in_array($category, self::AGENT_COLLECTION_CATEGORIES, true)) {
                json_error('Agents can only record chit, fund or loan collection receipts', 403);
            }
        }
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
