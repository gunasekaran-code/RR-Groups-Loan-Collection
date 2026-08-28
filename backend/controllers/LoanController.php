<?php
// Loans CRUD with role enforcement:
//   - Read:   any authenticated user (the frontend scopes rows per role —
//             customers see only their own loans, agents their assigned ones).
//   - Create: admin only (a loan_number is auto-filled if the client omits one).
//             Loan origination is an underwriting decision, so the agent panel
//             has no Create Loan button and the POST is rejected here too.
//   - Update: admin or agent — this also covers the real-time schedule sync that
//             rewrites a loan's outstanding_balance/status after each collection,
//             which is why agents must keep PATCH.
//   - Delete: admin only.
//   Customers can never write loans.

class LoanController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'GET' && ($_GET['action'] ?? '') === 'next_hp_number') {
            json_out(['next_hp_number' => Loan::nextLoanNumber()]);
        }

        if ($method === 'POST') {
            // Only an admin may originate a loan. Agents deliberately keep PATCH
            // below — the post-collection schedule sync PATCHes the loan's
            // outstanding_balance, and blocking that would break collections.
            if ($role !== 'admin') {
                json_error('Only admins can create loans', 403);
            }
        } elseif ($method === 'PATCH' || $method === 'PUT') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can update loans', 403);
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

        // An agent may only ever assign a loan to themselves. The UI hides the
        // dropdown for them, but that is cosmetic — this is the actual rule.
        if ($role === 'agent' && in_array($method, ['POST', 'PATCH', 'PUT'], true)) {
            $this->forceOwnAgent($method, $claims);
        }

        parent::handle();
    }

    /**
     * Recalculate after a write so penalty and balance figures are settled
     * before the response is sent.
     *
     * Without this, editing a loan's penalty terms (e.g. penalty_per_week)
     * left the stored penalty_amount stale until the next collection happened
     * to trigger a sync.
     */
    protected function afterWrite(string $method, array $rows): void
    {
        // The customer's loan_status has to be refreshed on DELETE too —
        // removing someone's only loan should put them back to "No Loan".
        $customerIds = [];
        foreach ($rows as $row) {
            if (!empty($row['customer_id'])) $customerIds[] = $row['customer_id'];
        }

        if ($method !== 'DELETE') {
            $ids = [];
            foreach ($rows as $row) {
                if (!empty($row['id'])) $ids[] = $row['id'];
            }
            if ($ids) {
                LoanRecalc::syncMany($ids);
            }
        }

        if ($customerIds) {
            Customer::recalcLoanStatus($customerIds);
        }
    }

    /**
     * Pin `assigned_agent` to the authenticated agent.
     *
     * On create the agent always owns the loan. On update the fields are only
     * rewritten when the client actually sent them — the repayment-schedule
     * sync PATCHes outstanding_balance/penalty/status and must not be treated
     * as a re-assignment attempt.
     */
    private function forceOwnAgent(string $method, array $claims): void
    {
        $agentId = $claims['sub'] ?? null;
        if (!$agentId) return;

        $profile = Profile::findPublic($agentId);
        $agentName = $profile['full_name'] ?? null;

        $body = $this->body();
        $isList = $body !== [] && array_keys($body) === range(0, count($body) - 1);
        $rows = $isList ? $body : [$body];

        $changed = false;
        foreach ($rows as &$row) {
            if (!is_array($row)) continue;
            $touchesAgent = array_key_exists('assigned_agent', $row) || array_key_exists('agent_name', $row);
            if ($method !== 'POST' && !$touchesAgent) continue;

            if (($row['assigned_agent'] ?? null) !== $agentId) {
                $row['assigned_agent'] = $agentId;
                $changed = true;
            }
            if (($row['agent_name'] ?? null) !== $agentName) {
                $row['agent_name'] = $agentName;
                $changed = true;
            }
        }
        unset($row);

        if ($changed) {
            set_json_body($isList ? $rows : $rows[0]);
        }
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
