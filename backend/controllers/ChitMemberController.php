<?php
// Chit members with role enforcement:
//   - Read:   any authenticated user (a customer sees their own memberships).
//   - Create/Delete: admin only (add / remove a member).
//   - Update: admin (any field) or agent (payment_status + due_date only — when
//             recording a member's monthly contribution).
//   Customers can never write chit members.

class ChitMemberController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only admins can add or remove chit members', 403);
            }
        } elseif ($method === 'PATCH' || $method === 'PUT') {
            if ($role === 'admin') {
                // full edit allowed
            } elseif ($role === 'agent') {
                $allowed = ['payment_status', 'due_date'];
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
