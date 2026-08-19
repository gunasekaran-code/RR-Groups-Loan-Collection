<?php
// Agent cash/UPI handovers with role enforcement:
//   - Read:   any authenticated user (frontend scopes: agent → own, admin → all).
//   - Create: agent (own handover only) or admin.
//   - Verify (PATCH) / Delete: admin only.
//   An agent can never verify their own handover or set received_by.

class HandoverController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        $sub    = $claims['sub'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'PATCH' || $method === 'PUT' || $method === 'DELETE') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can manage handovers', 403);
            }
        }

        parent::handle();
    }
}
