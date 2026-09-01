<?php
// Chit passbook entries with role enforcement:
//   - Read:   any authenticated user. A customer is additionally pinned to
//             their own customer_id server-side, because this table is what
//             the customer passbook reads and one member must never be able
//             to enumerate another member's contributions.
//   - Create: admin or agent (recording a contribution in the field).
//   - Update/Delete: admin only (corrections).
//   Customers can never write passbook entries.

class ChitPaymentController extends ResourceController
{
    /** Members whose passbook a PATCH/DELETE is about to move money away from. */
    private array $priorMemberIds = [];

    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        if (!$role && !empty($claims['sub'])) {
            $p = Profile::firstRaw(' WHERE id = ?', [$claims['sub']]);
            if ($p) $role = strtolower(trim($p['role'] ?? ''));
        }
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can record chit contributions', 403);
            }
            if ($role === 'agent') {
                $this->pinAgentToSelf($claims);
            }
        } elseif ($method === 'PATCH' || $method === 'PUT' || $method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only administrators can amend chit passbook entries', 403);
            }
            // An edit can reassign a contribution to another member, so
            // remember the passbook it is leaving as well as the one it joins.
            $this->priorMemberIds = $this->memberIdsMatchingFilter();
        } elseif ($method === 'GET' && $role === 'customer') {
            $this->scopeToOwnCustomer($claims);
        }

        parent::handle();
    }

    /**
     * A contribution changes what every later draw in that member's passbook
     * settles, so the stored statement is rebuilt inside the same request the
     * money is recorded in — before the response goes back, so a client that
     * refetches immediately reads the settled position.
     */
    protected function afterWrite(string $method, array $rows): void
    {
        $ids    = $this->priorMemberIds;
        $groups = [];
        foreach ($rows as $row) {
            if (!empty($row['member_id'])) $ids[]    = $row['member_id'];
            if (!empty($row['group_id']))  $groups[] = $row['group_id'];
        }
        // generate: a member can be added to a group whose draw sheet was
        // never generated, and their passbook still has to exist.
        ChitPassbookService::syncMembers($ids, true);

        // A corrected or deleted contribution changes what the group has
        // collected, and that total is summed rather than stepped, so it is
        // right again whichever way the money moved.
        foreach (array_unique($groups) as $groupId) {
            ChitPassbookService::recalcGroupTotals((string)$groupId);
        }
    }

    /** Member ids of the contributions the request's filter currently matches. */
    private function memberIdsMatchingFilter(): array
    {
        $model = $this->model;
        [$where, $binds] = QueryParser::where($model::columns());
        if ($where === '') return [];

        $ids = [];
        foreach ($model::select($where, $binds) as $row) {
            if (!empty($row['member_id'])) $ids[] = $row['member_id'];
        }
        return $ids;
    }

    /**
     * Force customer_id=eq.<own> onto the query whatever the client asked for,
     * so a hand-crafted request cannot read another member's passbook.
     */
    private function scopeToOwnCustomer(array $claims): void
    {
        $profile    = Profile::findPublic($claims['sub'] ?? '');
        $customerId = $profile['customer_id'] ?? null;
        if (!$customerId) {
            // A customer login with no linked customer record owns no payments.
            json_out([]);
        }
        $_GET['customer_id'] = 'eq.' . $customerId;
    }

    /** Stamp the collecting agent from the token, never from the request body. */
    private function pinAgentToSelf(array $claims): void
    {
        $agentId = $claims['sub'] ?? null;
        if (!$agentId) return;

        $profile   = Profile::findPublic($agentId);
        $agentName = $profile['full_name'] ?? null;

        $body   = $this->body();
        $isList = $body !== [] && array_keys($body) === range(0, count($body) - 1);
        $rows   = $isList ? $body : [$body];

        foreach ($rows as &$row) {
            if (!is_array($row)) continue;
            $row['agent_id']   = $agentId;
            $row['agent_name'] = $agentName;
        }
        unset($row);

        set_json_body($isList ? $rows : $rows[0]);
    }
}
