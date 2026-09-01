<?php
/**
 * Chit actions that are transactions, not CRUD.
 *
 *   POST /backend/chit.php?action=collect
 *        { group_id, member_id, amount, payment_method, payment_date, notes }
 *        → { payment, passbook, member, group }
 *
 *   POST /backend/chit.php?action=generate_schedule
 *        { group_id }
 *        → the rebuilt chit_schedules rows
 *
 * Both used to be sequences of writes issued by the browser. Recording a
 * collection took six round trips, allocated the draw in JavaScript, and left a
 * cash-book receipt behind with no payment against it if the tab closed midway.
 * The rules now live on the server, in one request each.
 */
class ChitActionController extends Controller
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));
        $action = $_GET['action'] ?? '';

        if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
            json_error('Method not allowed', 405);
        }
        if ($role !== 'admin' && $role !== 'agent') {
            json_error('Only admins or agents can act on a chit group', 403);
        }

        switch ($action) {
            case 'collect':
                json_out(ChitPassbookService::collect($this->body(), $claims));
                break;

            case 'generate_schedule':
                $groupId = trim((string)($this->body()['group_id'] ?? ''));
                if ($groupId === '') json_error('Which group?', 400);
                json_out(ChitPassbookService::regenerateSchedule($groupId));
                break;

            default:
                json_error("Unknown chit action: $action", 404);
        }
    }
}
