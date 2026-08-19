<?php
class PromoPopupController extends ResourceController
{
    public function handle(): void
    {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'GET') {
            $this->index();
            return;
        }

        $claims = $this->requireAuth();
        $role = strtolower(trim($claims['role'] ?? ''));
        if (!$role && !empty($claims['sub'])) {
            $p = Profile::firstRaw(' WHERE id = ?', [$claims['sub']]);
            if ($p) $role = strtolower(trim($p['role'] ?? ''));
        }
        if ($role !== 'admin' && $role !== 'agent') {
            json_error('Only admins or staff can manage promotional popups', 403);
        }

        parent::handle();
    }
}
