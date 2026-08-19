<?php
// Fund passbook entries with role enforcement:
//   - Read:   any authenticated user (frontend scopes rows per role).
//   - Create: admin or agent (recording a collection).
//   - Update/Delete: admin only (corrections).
//   Customers can never write passbook entries.

class FundPaymentController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'PATCH' || $method === 'PUT' || $method === 'DELETE') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can manage passbook entries', 403);
            }
        }

        parent::handle();
    }
}
