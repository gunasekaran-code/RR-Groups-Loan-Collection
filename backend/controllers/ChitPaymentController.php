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
        } elseif ($method === 'GET' && $role === 'customer') {
            $this->scopeToOwnCustomer($claims);
        }

        parent::handle();
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
