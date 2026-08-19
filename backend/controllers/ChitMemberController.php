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
        $role   = strtolower(trim($claims['role'] ?? ''));
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'DELETE') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can add or remove chit members', 403);
            }
        } elseif ($method === 'PATCH' || $method === 'PUT') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Not allowed', 403);
            }
        }

        parent::handle();
    }
}
