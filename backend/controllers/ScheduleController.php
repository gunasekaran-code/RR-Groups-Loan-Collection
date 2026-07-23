<?php
// Repayment schedule (installment plan) with role enforcement:
//   - Read:   any authenticated user (customers see their own installments).
//   - Create: admin or agent (generated when a loan is activated).
//   - Update: admin or agent (the real-time paid/balance/status sync after each
//             collection runs in agent/admin context).
//   - Delete: admin only.
//   Customers can never write the schedule.

class ScheduleController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST' || $method === 'PATCH' || $method === 'PUT') {
            if ($role !== 'admin' && $role !== 'agent') {
                json_error('Only admins or agents can change the repayment schedule', 403);
            }
        } elseif ($method === 'DELETE') {
            if ($role !== 'admin') {
                json_error('Only admins can delete schedule rows', 403);
            }
        }

        parent::handle();
    }
}
