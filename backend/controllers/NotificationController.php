<?php
// Notifications with role enforcement:
//   - Read:   any authenticated user (frontend scopes rows to the current user).
//   - Create: admin or agent (admin broadcasts; agents raise collection alerts).
//   - Update/Delete: any authenticated user (mark own read / dismiss). The row id
//     in the filter scopes the action to a single notification.
//   Customers can never create notifications, only manage their own.

class NotificationController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can create notifications', 403);
            }
        }

        parent::handle();
    }
}
