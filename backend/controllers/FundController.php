<?php
// Funds CRUD with role enforcement:
//   - Read:   any authenticated user (frontend scopes rows per role).
//   - Create/Delete: admin only.
//   - Update: admin (any field) or agent (collections only — collected_amount/status).
//   Customers can never write funds.

class FundController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'DELETE') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can create or delete funds', 403);
            }
        } elseif ($method === 'PATCH' || $method === 'PUT') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Not allowed', 403);
            }
        }

        parent::handle();
    }
}
