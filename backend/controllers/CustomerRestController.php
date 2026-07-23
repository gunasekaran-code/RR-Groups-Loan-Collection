<?php
// Customers reached through rest.php?table=customers.
//   - Read:   any authenticated user (frontend scopes rows per role).
//   - Update: admin (any field) or agent (latitude/longitude only — the "Visit"
//             button pins a customer's GPS location while on the field).
//   - Delete: admin only.
//   Full create/update with a linked login account goes through customers.php
//   (CustomerController), so POST here is admin-only as a safety net.
//   Customers can never write customer records.

class CustomerRestController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only admins can create or delete customers', 403);
            }
        } elseif ($method === 'PATCH' || $method === 'PUT') {
            if ($role === 'admin') {
                // full edit allowed
            } elseif ($role === 'agent') {
                $allowed = ['latitude', 'longitude'];
                foreach (array_keys($this->body()) as $k) {
                    if (!in_array($k, $allowed, true)) {
                        json_error('Agents can only update a customer location', 403);
                    }
                }
            } else {
                json_error('Not allowed', 403);
            }
        }

        parent::handle();
    }
}
