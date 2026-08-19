<?php
// Chit-group updates — a computed view driven by Settings ▸ Groups Updates.
//   GET  → members with a contribution due/overdue, for any authed user.
//   POST → dispatch contribution-due alerts to members (admin/agent only).

class GroupUpdateController extends Controller
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        if (!$role && !empty($claims['sub'])) {
            $p = Profile::firstRaw(' WHERE id = ?', [$claims['sub']]);
            if ($p) $role = strtolower(trim($p['role'] ?? ''));
        }
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        try {
            $settings = Setting::current();
            $days     = (int)($settings['reminder_days'] ?? 3);

            switch ($method) {
                case 'GET':
                    json_out([
                        'group_updates_enabled' => (bool)($settings['group_updates_enabled'] ?? true),
                        'group_auction_alerts'  => (bool)($settings['group_auction_alerts'] ?? true),
                        'group_payment_alerts'  => (bool)($settings['group_payment_alerts'] ?? true),
                        'items'                 => GroupUpdate::pending($days),
                    ]);
                    break;
                case 'POST':
                    if ($role !== 'admin' && $role !== 'agent') {
                        json_error('Only admins or agents can dispatch group updates', 403);
                    }
                    $res = GroupUpdate::dispatch($settings);
                    json_out(['ok' => true] + $res);
                    break;
                default:
                    json_error('Method not allowed', 405);
            }
        } catch (\Throwable $e) {
            json_error('Group updates error: ' . $e->getMessage(), 500);
        }
    }
}
