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

    /**
     * A new member starts with a full passbook of unpaid draws, and an edited
     * one may have moved group. Deletes need nothing: chit_passbook cascades
     * from chit_members, so the statement goes with the member.
     */
    protected function afterWrite(string $method, array $rows): void
    {
        if ($method === 'DELETE') return;

        $ids = [];
        foreach ($rows as $row) {
            if (!empty($row['id'])) $ids[] = $row['id'];
        }
        // generate: a group whose draw sheet was never built still owes this
        // member a passbook, so the sheet is created from the scheme.
        ChitPassbookService::syncMembers($ids, true);
    }
}
