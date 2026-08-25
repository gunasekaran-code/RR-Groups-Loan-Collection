<?php
// Collections (loan repayments) with role enforcement:
//   - Read:   any authenticated user (frontend scopes: a customer sees only
//             their own receipts, an agent their own collections).
//   - Create/Update: admin or agent (field agents record payments).
//   - Delete: admin only.
//   Customers can never write collections.
//
// Every write also recalculates the affected loan(s) via LoanRecalc before the
// response is sent, so the repayment schedule, outstanding balance and monthly
// interest in the database are correct the moment a payment lands — no matter
// which client wrote it.

class CollectionController extends ResourceController
{
    /** Loan ids captured before an UPDATE/DELETE changes or removes the rows. */
    private array $priorLoanIds = [];

    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'PATCH' || $method === 'PUT') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can record collections', 403);
            }
            if ($method !== 'POST') {
                // An edit can move a payment to a different loan, so remember
                // the loan it is leaving as well as the one it lands on.
                $this->priorLoanIds = $this->loanIdsMatchingFilter();
            }
        } elseif ($method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only admins can delete collections', 403);
            }
        }

        parent::handle();
    }

    protected function afterWrite(string $method, array $rows): void
    {
        $ids = $this->priorLoanIds;
        foreach ($rows as $row) {
            if (!empty($row['loan_id'])) $ids[] = $row['loan_id'];
        }
        LoanRecalc::syncMany($ids);
    }

    /** Loan ids of the collections the request's filter currently matches. */
    private function loanIdsMatchingFilter(): array
    {
        $model = $this->model;
        [$where, $binds] = QueryParser::where($model::columns());
        if ($where === '') return [];

        $ids = [];
        foreach ($model::select($where, $binds) as $row) {
            if (!empty($row['loan_id'])) $ids[] = $row['loan_id'];
        }
        return $ids;
    }
}
