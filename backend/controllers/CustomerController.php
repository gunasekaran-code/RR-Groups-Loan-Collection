<?php
// Admin-only customer management: creates the customers business record and,
// optionally, a linked customer login (role=customer, linked via customer_id).

class CustomerController extends Controller
{
    public function handle(): void
    {
        $this->requireAdmin();
        switch ($_SERVER['REQUEST_METHOD'] ?? '') {
            case 'POST':  $this->store();  break;
            case 'PATCH':
            case 'PUT':   $this->update(); break;
            default:      json_error('Method not allowed', 405);
        }
    }

    private static function clean($v): ?string
    {
        $v = is_string($v) ? trim($v) : '';
        return $v === '' ? null : $v;
    }

    private static function genCode(): string
    {
        return 'CUST-' . random_int(100000, 999999);
    }

    /** Fields shared by the customers row. */
    private function customerData(array $b): array
    {
        return [
            'full_name'      => self::clean($b['full_name'] ?? null),
            'mobile'         => self::clean($b['mobile'] ?? null),
            'address'        => self::clean($b['address'] ?? null),
            'aadhaar'        => self::clean($b['aadhaar'] ?? null),
            'pan'            => self::clean($b['pan'] ?? null),
            'occupation'     => self::clean($b['occupation'] ?? null),
            'photo_url'      => self::clean($b['photo_url'] ?? null),
            'assigned_agent' => self::clean($b['assigned_agent'] ?? null),
        ];
    }

    private function store(): void
    {
        $b = $this->body();
        $data = $this->customerData($b);
        if (!$data['full_name']) json_error('Full name is required', 400);

        $email = strtolower((string)(self::clean($b['email'] ?? null) ?? ''));
        $password = (string)($b['password'] ?? '');
        $wantsLogin = $email !== '' || $password !== '';

        // Validate credentials up front so we never create a half-linked record.
        if ($wantsLogin) {
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) json_error('A valid email is required for login', 400);
            if (strlen($password) < 6) json_error('Password must be at least 6 characters', 400);
            if (Profile::emailTaken($email)) json_error('That email is already registered', 409);
        }

        $data['customer_id'] = self::clean($b['customer_id'] ?? null) ?? self::genCode();
        $rows = Customer::insertRows([$data]);
        $customer = $rows[0] ?? null;
        if (!$customer) json_error('Failed to create customer', 500);

        if ($wantsLogin) {
            $this->createLogin($customer['id'], $email, $password, $data);
        }
        json_out($customer, 201);
    }

    private function update(): void
    {
        $id = $_GET['id'] ?? '';
        if ($id === '') json_error('Missing customer id', 400);
        $existingCustomer = Customer::select(' WHERE id = ?', [$id], '', ' LIMIT 1')[0] ?? null;
        if (!$existingCustomer) json_error('Customer not found', 404);

        $b = $this->body();
        $data = $this->customerData($b);
        if (array_key_exists('full_name', $b) && !$data['full_name']) {
            json_error('Full name cannot be empty', 400);
        }
        Customer::updateWhere($data, ' WHERE id = ?', [$id]);

        // Optional login handling.
        $email = strtolower((string)(self::clean($b['email'] ?? null) ?? ''));
        $password = (string)($b['password'] ?? '');
        $login = Profile::findByCustomerId($id);

        if ($login) {
            $set = [];
            if ($email !== '') {
                if (!filter_var($email, FILTER_VALIDATE_EMAIL)) json_error('A valid email is required', 400);
                if (Profile::emailTaken($email, $login['id'])) json_error('That email is already registered', 409);
                $set['email'] = $email;
            }
            if ($password !== '') {
                if (strlen($password) < 6) json_error('Password must be at least 6 characters', 400);
                $set['password_hash'] = password_hash($password, PASSWORD_BCRYPT);
            }
            if (array_key_exists('full_name', $b)) $set['full_name'] = $data['full_name'];
            if (array_key_exists('mobile', $b))    $set['mobile'] = $data['mobile'];
            if ($set) Profile::updateWhere($set, ' WHERE id = ?', [$login['id']]);
        } elseif ($email !== '' || $password !== '') {
            // No login yet — create one (needs both).
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) json_error('A valid email is required to create a login', 400);
            if (strlen($password) < 6) json_error('Password must be at least 6 characters', 400);
            if (Profile::emailTaken($email)) json_error('That email is already registered', 409);
            $this->createLogin($id, $email, $password, $data);
        }

        $customer = Customer::select(' WHERE id = ?', [$id])[0] ?? null;
        json_out($customer);
    }

    private function createLogin(string $customerId, string $email, string $password, array $data): void
    {
        Profile::insertRows([[
            'email'         => $email,
            'password_hash' => password_hash($password, PASSWORD_BCRYPT),
            'full_name'     => $data['full_name'],
            'mobile'        => $data['mobile'] ?? null,
            'role'          => 'customer',
            'customer_id'   => $customerId,
            'avatar_url'    => $data['photo_url'] ?? null,
            'status'        => 'active',
        ]]);
    }
}
