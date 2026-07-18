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
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only admins can create or delete funds', 403);
            }
        } elseif ($method === 'PATCH' || $method === 'PUT') {
            if ($role === 'admin') {
                // full edit allowed
            } elseif ($role === 'agent') {
                // Agents may only record collections.
                $allowed = ['collected_amount', 'status'];
                foreach (array_keys($this->body()) as $k) {
                    if (!in_array($k, $allowed, true)) {
                        json_error('Agents can only record fund collections', 403);
                    }
                }
            } else {
                json_error('Not allowed', 403);
            }
        }

        parent::handle();
    }
}
