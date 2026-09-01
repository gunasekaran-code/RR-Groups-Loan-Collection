<?php
// Repayment schedule (installment plan) with role enforcement:
//   - Read:   any authenticated user (customers see their own installments).
//   - Create: admin or agent (generated when a loan is activated).
//   - Update: admin or agent (the real-time paid/balance/status sync after each
//             collection runs in agent/admin context).
//   - Delete: admin only.
//   Customers can never write the schedule.

class ScheduleController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'PATCH' || $method === 'PUT') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can change the repayment schedule', 403);
            }
        } elseif ($method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only admins can delete schedule rows', 403);
            }
        } elseif ($method === 'GET') {
            $this->syncRequestedLoan();
        }

        parent::handle();
    }

    /**
     * Recompute the one loan whose schedule is being opened.
     *
     * Instalment status, balances and penalties are all date-dependent, but
     * nothing re-derives them while the app sits idle — LoanRecalc only runs
     * when a loan or a collection is written. A daily loan could therefore show
     * a week of past-due instalments still labelled "Pending".
     *
     * Scoped to a single ?loan_id=eq.<id> request, which is exactly how the
     * Repayment Schedule screen loads, so a full listing is never recomputed.
     */
    private function syncRequestedLoan(): void
    {
        $filter = $_GET['loan_id'] ?? '';
        if (!is_string($filter) || strncmp($filter, 'eq.', 3) !== 0) return;

        $loanId = substr($filter, 3);
        if ($loanId === '') return;

        try {
            LoanRecalc::sync($loanId);
        } catch (\Throwable $e) {
            // Showing a slightly stale schedule beats failing the read.
            error_log('Schedule sync-on-read failed for ' . $loanId . ': ' . $e->getMessage());
        }
    }
}
