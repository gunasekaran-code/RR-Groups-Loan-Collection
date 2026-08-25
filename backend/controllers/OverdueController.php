<?php
// Overdue accounts — a computed view over loans + repayment_schedule.
//   GET  → reconcile loan statuses, then return the live overdue list.
//   POST → force a reconcile only (admin/agent).
// Reads are open to any authenticated user; the frontend scopes what each role
// sees. Writes here only touch loans.status via the model's recompute().

class OverdueController extends Controller
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        try {
            switch ($method) {
                case 'GET':
                    // Keep loan statuses current so time-based overdues appear live.
                    try {
                        Overdue::recompute();
                    } catch (Throwable $e) {
                        error_log('Overdue::recompute warning: ' . $e->getMessage());
                    }
                    $data = Overdue::accounts();
                    json_out($data);
                    break;
                case 'POST':
                    if ($role !== 'admin' && $role !== 'agent') {
                        json_error('Only admins or agents can recompute overdues', 403);
                    }
                    $changed = Overdue::recompute();
                    json_out(['ok' => true, 'loans_updated' => $changed]);
                    break;
                default:
                    json_error('Method not allowed', 405);
            }
        } catch (Throwable $e) {
            error_log('OverdueController error: ' . $e->getMessage());
            json_error('Failed to load overdue accounts: ' . $e->getMessage(), 500);
        }
    }
}
