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
        $role   = $claims['role'] ?? '';
        $sub    = $claims['sub'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST') {
            if ($role !== 'agent' && $role !== 'admin') {
                json_error('Only agents or admins can record handovers', 403);
            }
            if ($role === 'agent') {
                $body = $this->body();
                $aid = $body['agent_id'] ?? '';
                if ($aid !== '' && $aid !== $sub) {
                    json_error('Agents can only hand over their own collections', 403);
                }
                if (($body['status'] ?? '') === 'verified' || !empty($body['received_by'])) {
                    json_error('Agents cannot verify their own handover', 403);
                }
            }
        } elseif ($method === 'PATCH' || $method === 'PUT' || $method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only admins can verify or remove handovers', 403);
            }
        }

        parent::handle();
    }
}
