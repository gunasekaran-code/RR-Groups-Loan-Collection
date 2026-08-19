<?php
// Customers reached through rest.php?table=customers.
//   - Read:   any authenticated user (frontend scopes rows per role).
//   - Update: admin (any field) or agent (GPS location + KYC document images —
//             the "Visit" button pins location, and agents capture documents in
//             the field; they still can't rename or reassign a customer).
//   - Delete: admin only.
//   Full create/update with a linked login account goes through customers.php
//   (CustomerController), so POST here is admin-only as a safety net.
//   Customers can never write customer records.

class CustomerRestController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        ensure_sequential_codes();
        $role   = strtolower(trim($claims['role'] ?? ''));
        if (!$role && !empty($claims['sub'])) {
            $p = Profile::firstRaw(' WHERE id = ?', [$claims['sub']]);
            if ($p) $role = strtolower(trim($p['role'] ?? ''));
        }
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if (in_array($method, ['POST', 'PATCH', 'PUT', 'DELETE'], true)) {
            if ($role === 'customer') {
                json_error('Customers cannot modify customer records', 403);
            }
            if ($method === 'DELETE' && $role !== 'admin') {
                json_error('Only admins can delete customers', 403);
            }
        }

        if ($method === 'PATCH' || $method === 'PUT') {
            $b = $this->body();
            if (array_key_exists('assigned_agent', $b)) {
                [$where, $binds] = QueryParser::where(Customer::columns());
                if ($where !== '') {
                    $agentId = $b['assigned_agent'] ?: null;
                    $agentName = null;
                    if ($agentId) {
                        $prof = Profile::findPublic($agentId);
                        $agentName = $prof['full_name'] ?? null;
                    }
                    // Sync assigned_agent to all loans belonging to the customer
                    $customers = Customer::select($where, $binds);
                    foreach ($customers as $cust) {
                        if (!empty($cust['id'])) {
                            Loan::updateWhere(['assigned_agent' => $agentId, 'agent_name' => $agentName], ' WHERE customer_id = ?', [$cust['id']]);
                        }
                    }
                }
            }
        }

        parent::handle();
    }
}
