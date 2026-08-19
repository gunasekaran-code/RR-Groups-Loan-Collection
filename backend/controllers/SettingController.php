<?php
// Company / system settings:
//   - Read (GET): public / any user so branding loads everywhere.
//   - Write (POST/PATCH/PUT): admin / staff with single-row auto-upsert.

class SettingController extends ResourceController
{
    public function handle(): void
    {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'GET') {
            ensure_sequential_codes();
            $this->index();
            return;
        }

        // Writes require auth
        $claims = $this->requireAuth();
        $role = strtolower(trim($claims['role'] ?? ''));
        if (!$role && !empty($claims['sub'])) {
            $p = Profile::firstRaw(' WHERE id = ?', [$claims['sub']]);
            if ($p) $role = strtolower(trim($p['role'] ?? ''));
        }
        if ($role !== 'admin' && $role !== 'agent') {
            json_error('Only admins or staff can change settings', 403);
        }

        // Ensure single-row settings table exists
        $existing = Database::pdo()->query("SELECT id FROM settings LIMIT 1")->fetch(PDO::FETCH_ASSOC);

        if ($method === 'POST') {
            if ($existing) {
                $_GET['id'] = 'eq.' . $existing['id'];
                $this->update();
            } else {
                $this->store();
            }
            return;
        }

        if ($method === 'PATCH' || $method === 'PUT') {
            if (!$existing) {
                $this->store();
            } else {
                if (empty($_GET['id'])) {
                    $_GET['id'] = 'eq.' . $existing['id'];
                }
                $this->update();
            }
            return;
        }

        if ($method === 'DELETE') {
            $this->destroy();
            return;
        }

        json_error('Method not allowed', 405);
    }
}
