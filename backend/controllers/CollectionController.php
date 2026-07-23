<?php
// Collections (loan repayments) with role enforcement:
//   - Read:   any authenticated user (frontend scopes: a customer sees only
//             their own receipts, an agent their own collections).
//   - Create/Update: admin or agent (field agents record payments).
//   - Delete: admin only.
//   Customers can never write collections.

class CollectionController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'PATCH' || $method === 'PUT') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can record collections', 403);
            }
        } elseif ($method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only admins can delete collections', 403);
            }
        }

        parent::handle();
    }
}
