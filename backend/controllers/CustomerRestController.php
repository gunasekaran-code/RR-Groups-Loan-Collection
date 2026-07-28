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
        $userId = $claims['sub'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'GET' && isset($_GET['view'])) {
            $view = (string)$_GET['view'];
            if ($view === 'map') {
                $this->mapView($role, $userId);
                return;
            }
            if ($view === 'map_summary') {
                $this->mapSummary($role, $userId);
                return;
            }
        }

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

    private function mapView(string $role, string $userId): void
    {
        [$where, $binds] = $this->mapScope($role, $userId);
        $sql = "
            SELECT
                c.id,
                c.customer_id,
                c.full_name AS customer_name,
                c.assigned_agent AS agent_id,
                COALESCE(p.full_name, 'Unknown Agent') AS agent_name,
                c.latitude,
                c.longitude,
                c.loan_status AS status,
                c.created_at,
                c.mobile,
                c.address
            FROM customers c
            LEFT JOIN profiles p ON p.id = c.assigned_agent
            $where
            ORDER BY c.created_at DESC
        ";
        $stmt = Database::pdo()->prepare($sql);
        $stmt->execute($binds);
        json_out(['data' => $stmt->fetchAll()]);
    }

    private function mapSummary(string $role, string $userId): void
    {
        [$where, $binds] = $this->mapScope($role, $userId);
        $sql = "
            SELECT
                COUNT(*) AS on_map,
                SUM(CASE WHEN c.latitude IS NOT NULL AND c.longitude IS NOT NULL THEN 1 ELSE 0 END) AS collected_count,
                COUNT(DISTINCT c.assigned_agent) AS active_agents,
                COUNT(*) AS total_collected
            FROM customers c
            LEFT JOIN profiles p ON p.id = c.assigned_agent
            $where
        ";
        $stmt = Database::pdo()->prepare($sql);
        $stmt->execute($binds);
        json_out($stmt->fetch() ?: [
            'on_map' => 0,
            'collected_count' => 0,
            'active_agents' => 0,
            'total_collected' => 0,
        ]);
    }

    private function mapScope(string $role, string $userId): array
    {
        $clauses = ['WHERE c.latitude IS NOT NULL AND c.longitude IS NOT NULL'];
        $binds = [];

        if ($role === 'agent' && $userId !== '') {
            $clauses[] = 'AND c.assigned_agent = ?';
            $binds[] = $userId;
        }

        if (isset($_GET['agent_id']) && $_GET['agent_id'] !== '' && $_GET['agent_id'] !== 'all' && $role === 'admin') {
            $clauses[] = 'AND c.assigned_agent = ?';
            $binds[] = (string)$_GET['agent_id'];
        }

        return [' ' . implode(' ', $clauses), $binds];
    }
}
