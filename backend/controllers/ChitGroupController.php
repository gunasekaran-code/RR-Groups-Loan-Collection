<?php
// Chit groups with role enforcement:
//   - Read:   any authenticated user (customers see the groups they belong to).
//   - Create/Delete: admin only.
//   - Update: admin (any field) or agent (collection fields only — when an agent
//             records a member's monthly contribution the group's running totals
//             and status are updated).
//   Customers can never write chit groups.
//
// This controller also serves ?table=chit_schedules, because a group and its
// draw sheet are edited together and carry the same permissions.

class ChitGroupController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'DELETE') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can create or delete chit groups', 403);
            }
        } elseif ($method === 'PATCH' || $method === 'PUT') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Not allowed', 403);
            }
        }

        parent::handle();
    }

    /**
     * A saved group gets its draw sheet, and every member gets a passbook
     * built from it, before the response goes back.
     *
     * Creating the group used to leave the browser to work out the scheme,
     * insert thirty chit_schedules rows and hope none of them failed. The
     * schedule is generated here now (ChitPassbookService::schedulesFor), so a
     * group created from anywhere — this screen, the agent app, an import — has
     * the same sheet, and its members' passbooks exist immediately.
     *
     * Only a group with no sheet is generated for: once draws exist an admin
     * may have overridden dates or amounts on them, and those are not to be
     * silently rewritten. Rebuilding on purpose is chit.php?action=generate_schedule.
     */
    protected function afterWrite(string $method, array $rows): void
    {
        $isGroupWrite = $this->model::table() === 'chit_groups';

        $ids = [];
        foreach ($rows as $row) {
            $id = $row['group_id'] ?? ($isGroupWrite ? ($row['id'] ?? null) : null);
            if ($id) $ids[] = $id;
        }

        $build = $isGroupWrite && $method !== 'DELETE';
        foreach (array_unique($ids) as $groupId) {
            // The sheet is built even when the group has no members yet: the
            // draws belong to the group, and the members inherit them.
            if ($build) ChitPassbookService::schedulesFor((string)$groupId, null, true);
            // A schedule write is a rebuild in progress (delete, then insert),
            // so generating there would race the rows about to arrive.
            ChitPassbookService::syncGroup((string)$groupId, $build);
        }
    }
}
