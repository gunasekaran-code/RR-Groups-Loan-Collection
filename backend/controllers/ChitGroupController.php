<?php
// Chit groups with role enforcement:
//   - Read:   any authenticated user (customers see the groups they belong to).
//   - Create/Delete: admin only.
//   - Update: admin (any field) or agent (collection fields only — when an agent
//             records a member's monthly contribution the group's running totals
//             and status are updated).
//   Customers can never write chit groups.

class ChitGroupController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only admins can create or delete chit groups', 403);
            }
        } elseif ($method === 'PATCH' || $method === 'PUT') {
            if ($role === 'admin') {
                // full edit allowed
            } elseif ($role === 'agent') {
                $allowed = ['collected_amount', 'pending_amount', 'status'];
                foreach (array_keys($this->body()) as $k) {
                    if (!in_array($k, $allowed, true)) {
                        json_error('Agents can only record chit collections', 403);
                    }
                }
            } else {
                json_error('Not allowed', 403);
            }
        }

        parent::handle();
    }
}
