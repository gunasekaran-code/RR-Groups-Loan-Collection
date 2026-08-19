<?php
// Admin-only user management: create/update login accounts with bcrypt hashing.

class UserController extends Controller
{
    private const ROLES = ['admin', 'agent', 'customer'];

    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        if (!$role && !empty($claims['sub'])) {
            $p = Profile::firstRaw(' WHERE id = ?', [$claims['sub']]);
            if ($p) $role = strtolower(trim($p['role'] ?? ''));
        }
        if ($role !== 'admin' && $role !== 'agent') {
            json_error('Only admins or agents can manage user accounts', 403);
        }
        switch ($_SERVER['REQUEST_METHOD'] ?? '') {
            case 'POST':   $this->store();   break;
            case 'PATCH':
            case 'PUT':    $this->update();  break;
            case 'DELETE': $this->destroy(); break;
            default:       json_error('Method not allowed', 405);
        }
    }

    private static function clean($v): ?string
    {
        $v = is_string($v) ? trim($v) : '';
        return $v === '' ? null : $v;
    }

    private function role($role): string
    {
        $role = $role ?: 'agent';
        if (!in_array($role, self::ROLES, true)) {
            json_error('Invalid role', 400);
        }
        return $role;
    }

    public static function genUserCode(string $role): string
    {
        $pdo = Database::pdo();
        $prefix = ($role === 'admin') ? 'RRG-ADM-' : (($role === 'agent') ? 'RRG-STF-' : 'RRG-CUS-');
        $stmt = $pdo->query("SELECT user_code FROM profiles WHERE user_code LIKE '{$prefix}%'");
        $maxNum = 0;
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            if (preg_match('/' . preg_quote($prefix, '/') . '(\d+)/i', $row['user_code'], $m)) {
                $num = (int)$m[1];
                if ($num > $maxNum) $maxNum = $num;
            }
        }
        if ($maxNum === 0) {
            $maxNum = (int)$pdo->query("SELECT COUNT(*) FROM profiles WHERE role = " . $pdo->quote($role))->fetchColumn();
        }
        return sprintf('%s%04d', $prefix, $maxNum + 1);
    }

    private function store(): void
    {
        $b = $this->body();
        $full_name = self::clean($b['full_name'] ?? null);
        $email = strtolower((string)(self::clean($b['email'] ?? null) ?? ''));
        $password = (string)($b['password'] ?? '');

        if (!$full_name) json_error('Full name is required', 400);
        if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) json_error('A valid email is required', 400);
        if (strlen($password) < 6) json_error('Password must be at least 6 characters', 400);
        if (Profile::emailTaken($email)) json_error('That email is already registered', 409);

        $userRole = $this->role($b['role'] ?? null);
        $userCode = self::clean($b['user_code'] ?? null) ?? self::genUserCode($userRole);

        $rows = Profile::insertRows([[
            'email'         => $email,
            'password_hash' => password_hash($password, PASSWORD_BCRYPT),
            'full_name'     => $full_name,
            'mobile'        => self::clean($b['mobile'] ?? null),
            'role'          => $userRole,
            'user_code'     => $userCode,
            'customer_id'   => self::clean($b['customer_id'] ?? null),
            'address'       => self::clean($b['address'] ?? null),
            'aadhaar'       => self::clean($b['aadhaar'] ?? null),
            'pan'           => self::clean($b['pan'] ?? null),
            'occupation'    => self::clean($b['occupation'] ?? null),
            'status'        => ($b['status'] ?? 'active') === 'inactive' ? 'inactive' : 'active',
            'avatar_url'    => self::clean($b['avatar_url'] ?? null),
        ]]);
        json_out($rows[0] ?? null, 201);
    }

    private function update(): void
    {
        $id = $_GET['id'] ?? '';
        if ($id === '') json_error('Missing user id', 400);
        if (!Profile::findPublic($id)) json_error('User not found', 404);
        $b = $this->body();

        $data = [];
        if (array_key_exists('full_name', $b)) {
            $fn = self::clean($b['full_name']);
            if (!$fn) json_error('Full name cannot be empty', 400);
            $data['full_name'] = $fn;
        }
        foreach (['mobile', 'avatar_url', 'address', 'aadhaar', 'pan', 'occupation'] as $f) {
            if (array_key_exists($f, $b)) $data[$f] = self::clean($b[$f]);
        }
        if (array_key_exists('status', $b)) $data['status'] = $b['status'] === 'inactive' ? 'inactive' : 'active';
        if (array_key_exists('role', $b))   $data['role'] = $this->role($b['role']);

        if (array_key_exists('email', $b)) {
            $email = strtolower((string)(self::clean($b['email']) ?? ''));
            if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) json_error('A valid email is required', 400);
            if (Profile::emailTaken($email, $id)) json_error('That email is already registered', 409);
            $data['email'] = $email;
        }
        if (!empty($b['password'])) {
            if (strlen((string)$b['password']) < 6) json_error('Password must be at least 6 characters', 400);
            $data['password_hash'] = password_hash((string)$b['password'], PASSWORD_BCRYPT);
        }
        if (!$data) json_error('Nothing to update', 400);

        $rows = Profile::updateWhere($data, ' WHERE id = ?', [$id]);
        json_out($rows[0] ?? null);
    }

    private function destroy(): void
    {
        $id = $_GET['id'] ?? '';
        if ($id === '') json_error('Missing user id', 400);
        try {
            Profile::deleteWhere(' WHERE id = ?', [$id]);
            json_out(['success' => true]);
        } catch (\Throwable $e) {
            json_error('Delete failed: ' . $e->getMessage(), 400);
        }
    }
}
