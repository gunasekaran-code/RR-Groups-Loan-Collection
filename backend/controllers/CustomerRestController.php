<?php
// Customers reached through rest.php?table=customers.
//   - Read:   any authenticated user (frontend scopes rows per role).
//   - Update: admin (any field) or agent (GPS location + KYC document images —
//             the "Visit" button pins location, and agents capture documents in
//             the field; they still can't rename or reassign a customer).
//   - Delete: admin only, and it is a SOFT delete — the row is flagged
//             delflag = 1 rather than removed, because loans, collections,
//             funds and chit membership all reference it. Reads filter
//             delflag = 0 here, in one place, so none of the ~14 screens
//             that list customers can forget to exclude deleted ones.
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

        // Reads and deletes are handled generically by ResourceController:
        // it filters delflag = 0 for every table that has the column, and
        // turns DELETE into a flag update. Keeping a second copy of that rule
        // here is how the two drift apart.
        parent::handle();
    }
}
