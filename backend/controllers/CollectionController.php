<?php
// Collections (loan repayments) with role enforcement:
//   - Read:   any authenticated user (frontend scopes: a customer sees only
//             their own receipts, an agent their own collections).
//   - Create/Update: admin or agent (field agents record payments).
//   - Delete: admin only.
//   Customers can never write collections.

class CollectionController extends ResourceController
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

        if ($method === 'POST' || $method === 'PATCH' || $method === 'PUT') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can record collections', 403);
            }
        } elseif ($method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only admins can delete collections', 403);
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
                COALESCE(c.customer_name, cu.full_name, 'Unknown') AS customer_name,
                COALESCE(c.agent_name, a.full_name, 'Unknown Agent') AS agent_name,
                c.agent_id,
                c.collection_amount AS amount,
                c.created_at AS collected_at,
                cu.latitude,
                cu.longitude,
                1 AS collected
            FROM collections c
            LEFT JOIN customers cu ON cu.id = c.customer_id
            LEFT JOIN profiles a ON a.id = c.agent_id
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
                COUNT(*) AS collected_count,
                COUNT(DISTINCT c.agent_id) AS active_agents,
                COALESCE(SUM(c.collection_amount), 0) AS total_collected
            FROM collections c
            LEFT JOIN customers cu ON cu.id = c.customer_id
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

    /**
     * Field map is intentionally scoped to today's collections. Agents only
     * see their own rows; admins see everything.
     */
    private function mapScope(string $role, string $userId): array
    {
        $clauses = ['WHERE c.collection_date = CURDATE()'];
        $binds = [];

        if ($role === 'agent' && $userId !== '') {
            $clauses[] = 'AND c.agent_id = ?';
            $binds[] = $userId;
        }

        if (isset($_GET['agent_id']) && $_GET['agent_id'] !== '' && $_GET['agent_id'] !== 'all' && $role === 'admin') {
            $clauses[] = 'AND c.agent_id = ?';
            $binds[] = (string)$_GET['agent_id'];
        }

        return [' ' . implode(' ', $clauses), $binds];
    }
}
