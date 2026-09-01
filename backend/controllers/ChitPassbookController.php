<?php
// The stored per-member chit passbook (chit_passbook).
//
//   - Read:   any authenticated user. A customer is pinned to their own
//             customer_id server-side — this is the table the passbook screen
//             reads, and one member must never be able to enumerate another
//             member's statement.
//   - Write:  admin only. The rows are derived by ChitPassbookService from the
//             draw schedule and the recorded contributions, so hand-editing
//             them is a correction, not a normal operation.
class ChitPassbookController extends ResourceController
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

        if ($method !== 'GET' && $role !== 'admin') {
            json_error('Only administrators can amend a chit passbook', 403);
        }

        if ($method === 'GET') {
            if ($role === 'customer') {
                $this->scopeToOwnCustomer($claims);
            }
            $this->refreshRequested();
        }

        parent::handle();
    }

    /**
     * Force customer_id=eq.<own> onto the query whatever the client asked for.
     */
    private function scopeToOwnCustomer(array $claims): void
    {
        $profile    = Profile::findPublic($claims['sub'] ?? '');
        $customerId = $profile['customer_id'] ?? null;
        if (!$customerId) {
            json_out([]);   // a login with no linked customer owns no passbook
        }
        $_GET['customer_id'] = 'eq.' . $customerId;
    }

    /**
     * Recompute before answering, so opening the passbook always shows the
     * live position rather than whatever the last write happened to leave.
     *
     * A member read is cheap (one row per draw) and is recomputed every time.
     * A whole-group read is only built when the group has no passbook yet —
     * after that the rows are maintained by the writes that can change them,
     * and rebuilding 30 members on every 30-second poll would be waste.
     */
    private function refreshRequested(): void
    {
        try {
            $customerId = self::eqValue($_GET['customer_id'] ?? null);

            $memberId = self::eqValue($_GET['member_id'] ?? null);
            if ($memberId !== null) {
                // A customer read carries the forced customer_id filter, so a
                // hand-crafted member_id cannot make us touch someone else's
                // statement — not even to recompute it.
                if ($customerId === null || self::memberBelongsTo($memberId, $customerId)) {
                    ChitPassbookService::syncMember($memberId, true);
                }
                return;
            }

            $groupId = self::eqValue($_GET['group_id'] ?? null);
            if ($groupId !== null && !self::hasRows('group_id', $groupId)) {
                ChitPassbookService::syncGroup($groupId, true);
                return;
            }

            if ($customerId !== null && !self::hasRows('customer_id', $customerId)) {
                self::syncCustomer($customerId);
            }
        } catch (\Throwable $e) {
            // Serve what is stored rather than failing the read.
            error_log('ChitPassbookController refresh failed: ' . $e->getMessage());
        }
    }

    /** The literal behind a PostgREST-style ?col=eq.<value> filter. */
    private static function eqValue($raw): ?string
    {
        if (!is_string($raw) || strpos($raw, 'eq.') !== 0) return null;
        $v = substr($raw, 3);
        return $v === '' ? null : $v;
    }

    private static function memberBelongsTo(string $memberId, string $customerId): bool
    {
        $stmt = Database::pdo()->prepare(
            'SELECT 1 FROM `chit_members` WHERE `id` = ? AND `customer_id` = ? LIMIT 1'
        );
        $stmt->execute([$memberId, $customerId]);
        return (bool)$stmt->fetchColumn();
    }

    private static function hasRows(string $column, string $value): bool
    {
        $stmt = Database::pdo()->prepare(
            "SELECT 1 FROM `chit_passbook` WHERE `$column` = ? AND `delflag` = 0 LIMIT 1"
        );
        $stmt->execute([$value]);
        return (bool)$stmt->fetchColumn();
    }

    private static function syncCustomer(string $customerId): void
    {
        $stmt = Database::pdo()->prepare(
            'SELECT id FROM `chit_members` WHERE `customer_id` = ? AND `delflag` = 0'
        );
        $stmt->execute([$customerId]);
        ChitPassbookService::syncMembers($stmt->fetchAll(PDO::FETCH_COLUMN, 0) ?: [], true);
    }
}
