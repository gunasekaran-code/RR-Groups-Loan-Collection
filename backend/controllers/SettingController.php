<?php
// Company / system settings with role enforcement:
//   - Read:   any authenticated user (the app reads branding — name, logo,
//             address, GST — on every screen).
//   - Create/Update/Delete: admin only.

class SettingController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if (in_array($method, ['POST', 'PATCH', 'PUT', 'DELETE'], true) && $role !== 'admin') {
            json_error('Only admins can change settings', 403);
        }

        parent::handle();
    }
}
