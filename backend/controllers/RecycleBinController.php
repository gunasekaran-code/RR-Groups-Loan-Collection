<?php
// Admin-only recycle bin.
//   - Read:   admin only. The payload holds full row snapshots (including
//             password hashes), so this must never widen beyond admins.
//   - POST ?action=restore&id=<bin id>  -> put the record (and its cascaded
//             children) back into its original table.
//   - DELETE  -> purge permanently. ?id=eq.<id> for one, ?all=1 to empty it.
//   Nothing else may write here; entries are created by RecycleBinService
//   when a delete happens elsewhere.

class RecycleBinController extends ResourceController
{
    public function handle(): void
    {
        $this->requireAdmin();
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if ($method === 'POST') {
            $action = $_GET['action'] ?? '';
            if ($action !== 'restore') {
                json_error('Recycle bin entries are created automatically, not posted', 400);
            }
            $this->restore();
            return;
        }

        if ($method === 'PATCH' || $method === 'PUT') {
            json_error('Recycle bin entries cannot be edited', 400);
        }

        if ($method === 'DELETE' && ($_GET['all'] ?? '') === '1') {
            Database::pdo()->exec("DELETE FROM recycle_bin");
            json_out([]);
        }

        parent::handle();
    }

    private function restore(): void
    {
        $id = $_GET['id'] ?? ($this->body()['id'] ?? '');
        $id = preg_replace('/^eq\./', '', (string)$id);
        if ($id === '') {
            json_error('Which entry should be restored?', 400);
        }

        $entry = RecycleBin::firstRaw(' WHERE id = ?', [$id]);
        if (!$entry) {
            json_error('That recycle bin entry no longer exists', 404);
        }
        if (!empty($entry['restored_at'])) {
            json_error('That record has already been restored', 409);
        }

        [$ok, $message] = RecycleBinService::restore($entry);
        if (!$ok) {
            json_error($message, 409);
        }

        json_out(['restored' => true, 'table_name' => $entry['table_name'], 'record_id' => $entry['record_id']]);
    }

    /**
     * A purge is the one delete that must NOT be archived — otherwise emptying
     * the bin would refill it.
     */
    protected function destroy(): void
    {
        $model = $this->model;
        [$where, $binds] = QueryParser::where($model::columns());
        if ($where === '') {
            json_error('Refusing to delete without a filter', 400);
        }
        $model::deleteWhere($where, $binds);
        json_out([]);
    }
}
