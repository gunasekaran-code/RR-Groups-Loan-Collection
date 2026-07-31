<?php
// Payment reminders — a computed view driven by Settings ▸ Payment Reminders.
//   GET  → EMIs due within the configured window (+ overdue), for any authed user.
//   POST → dispatch reminder notifications to customers (admin/agent only).

class ReminderController extends Controller
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        $settings = Setting::current();
        $days     = (int)($settings['reminder_days'] ?? 3);

        switch ($method) {
            case 'GET':
                json_out([
                    'auto_reminders_enabled' => (bool)($settings['auto_reminders_enabled'] ?? true),
                    'reminder_days'          => $days,
                    'reminder_time'          => $settings['reminder_time'] ?? '09:00',
                    'items'                  => Reminder::due($days),
                ]);
                break;
            case 'POST':
                if ($role !== 'admin' && $role !== 'agent') {
                    json_error('Only admins or agents can dispatch reminders', 403);
                }
                json_out(['ok' => true] + Reminder::dispatch($settings));
                break;
            default:
                json_error('Method not allowed', 405);
        }
    }
}
