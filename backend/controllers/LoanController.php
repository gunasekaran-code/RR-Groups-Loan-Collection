<?php
// Loans CRUD with role enforcement:
//   - Read:   any authenticated user (the frontend scopes rows per role —
//             customers see only their own loans, agents their assigned ones).
//   - Create: admin or agent (a loan_number is auto-filled if the client omits one).
//   - Update: admin or agent — this also covers the real-time schedule sync that
//             rewrites a loan's outstanding_balance/status after each collection.
//   - Delete: admin only.
//   Customers can never write loans.

class LoanController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'PATCH' || $method === 'PUT') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can create or update loans', 403);
            }
        } elseif ($method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only admins can delete loans', 403);
            }
        }

        // Server-side safety net: never let a loan land without a loan number.
        if ($method === 'POST') {
            $this->fillLoanNumbers();
        }

        parent::handle();
    }

    /**
     * Ensure every row in the (possibly bulk) POST body has a loan_number,
     * generating a unique one when the client didn't send it.
     */
    private function fillLoanNumbers(): void
    {
        $body = $this->body();
        $isList = $body !== [] && array_keys($body) === range(0, count($body) - 1);
        $rows = $isList ? $body : [$body];
        $changed = false;
        foreach ($rows as &$row) {
            if (!is_array($row)) continue;
            if (empty($row['loan_number'])) {
                $row['loan_number'] = Loan::nextLoanNumber();
                $changed = true;
            }
        }
        unset($row);
        if ($changed) {
            // Re-seed the cached request body so parent::store() sees the filled numbers.
            set_json_body($isList ? $rows : $rows[0]);
        }
    }
}
