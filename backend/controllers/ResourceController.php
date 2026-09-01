<?php
// Generic JWT-protected CRUD for any whitelisted table, delegating to its Model.

class ResourceController extends Controller
{
    /** @var class-string<Model> */
    protected string $model;

    public function __construct(string $modelClass)
    {
        $this->model = $modelClass;
    }

    public function handle(): void
    {
        $this->requireAuth();
        ensure_sequential_codes();
        switch ($_SERVER['REQUEST_METHOD'] ?? 'GET') {
            case 'GET':    $this->index();   break;
            case 'POST':   $this->store();   break;
            case 'PATCH':
            case 'PUT':    $this->update();  break;
            case 'DELETE': $this->destroy(); break;
            default:       json_error('Method not allowed', 405);
        }
    }

    protected function index(): void
    {
        $model = $this->model;
        $this->applySoftDeleteFilter();
        $columns = $model::columns();
        [$where, $binds] = QueryParser::where($columns);
        json_out($model::select($where, $binds, QueryParser::order($columns), QueryParser::limit()));
    }

    protected function store(): void
    {
        $model = $this->model;
        $body = $this->body();
        $isList = $body !== [] && array_keys($body) === range(0, count($body) - 1);
        $rows = $isList ? $body : [$body];
        $upsert = ($_GET['upsert'] ?? '') === '1';
        try {
            $saved = $model::insertRows($rows, $upsert);
        } catch (PDOException $e) {
            json_error('Insert failed: ' . $e->getMessage(), 400);
            return;
        }
        $this->afterWrite('POST', $saved);
        json_out($saved, 201);
    }

    protected function update(): void
    {
        $model = $this->model;
        [$where, $binds] = QueryParser::where($model::columns());
        if ($where === '') {
            json_error('Refusing to update without a filter', 400);
        }
        try {
            $saved = $model::updateWhere($this->body(), $where, $binds);
        } catch (PDOException $e) {
            json_error('Update failed: ' . $e->getMessage(), 400);
            return;
        }
        $this->afterWrite('PATCH', $saved);
        json_out($saved);
    }

    protected function destroy(): void
    {
        $model = $this->model;
        [$where, $binds] = QueryParser::where($model::columns());
        if ($where === '') {
            json_error('Refusing to delete without a filter', 400);
        }
        // Snapshot the rows first — a subclass hook may need what they pointed at.
        $doomed = $model::select($where, $binds);
        // Every delete in the app funnels through here, so this is the one
        // place the recycle bin has to hook into. It re-reads the rows raw
        // and follows cascading foreign keys before anything is destroyed.
        //
        // Only archive when the request targets a specific record by id.
        // Deleting by a parent key (…&loan_id=eq.X) is how this app rebuilds
        // child rows — regenerating a repayment schedule wipes ~30 rows and
        // reinserts them — and archiving those buried the bin in unnamed
        // fragments of a single edit. The parent's own delete still captures
        // its cascaded children, so nothing restorable is lost.
        if (self::targetsSingleRecord()) {
            RecycleBinService::capture($model::table(), $doomed, $this->requireAuth());
        }

        // Soft delete wherever the table supports it. Nothing is removed:
        // a customer's loans, a loan's collections and a chit member's
        // contributions all reference rows above them, and destroying the
        // parent would either orphan or erase real financial history.
        if (table_has_delflag($model::table()) && self::targetsSingleRecord()) {
            $claims = $this->requireAuth();
            $this->beforeSoftDelete($doomed);
            $model::updateWhere(
                [
                    'delflag'    => 1,
                    'deleted_at' => date('Y-m-d H:i:s'),
                    'deleted_by' => $claims['sub'] ?? null,
                ],
                $where,
                $binds
            );
            // Mirror what ON DELETE CASCADE used to do for us.
            soft_delete_cascade($model::table(), $doomed, $claims['sub'] ?? null);
        } else {
            // Either the table has no flag, or this is a bulk rebuild by a
            // parent key — regenerating a repayment schedule replaces its rows,
            // and leaving flagged copies behind would keep inflating the loan's
            // outstanding balance on every recalculation.
            $model::deleteWhere($where, $binds);
        }

        $this->afterWrite('DELETE', $doomed);
        json_out([]);
    }

    /**
     * Hide soft-deleted rows from every read, for every table that has the
     * flag, in one place.
     *
     * Doing this per screen would mean ~40 query sites each remembering a
     * filter — and one omission puts a deleted customer back in the loan
     * picker. An admin can opt in with ?include_deleted=1; the flag is ignored
     * for everyone else so a crafted request cannot expose hidden rows.
     */
    protected function applySoftDeleteFilter(): void
    {
        $model = $this->model;
        if (!table_has_delflag($model::table())) {
            unset($_GET['include_deleted']);
            return;
        }

        $wantsDeleted = ($_GET['include_deleted'] ?? '') === '1';
        unset($_GET['include_deleted']);

        $claims = $this->tryAuth();
        $role   = strtolower(trim($claims['role'] ?? ''));

        if ($wantsDeleted && $role === 'admin') {
            // Admin asked for them on purpose; leave any delflag filter they
            // sent (e.g. delflag=eq.1 for "show deleted only") alone.
            return;
        }
        $_GET['delflag'] = 'eq.0';
    }

    /**
     * Hook for tables where flagging a row is not enough on its own —
     * a UNIQUE column has to be released so the value can be used again.
     */
    protected function beforeSoftDelete(array $rows): void
    {
        release_unique_columns($this->model::table(), $rows);
    }

    /**
     * True when the delete names one record (?id=eq.<uuid>), as every
     * user-facing "delete this" button does. Anything filtered by another
     * column is a bulk rebuild performed by the app itself.
     */
    private static function targetsSingleRecord(): bool
    {
        $id = $_GET['id'] ?? null;
        return is_string($id) && $id !== '' && strpos($id, 'in.') !== 0;
    }

    /**
     * Hook that runs after a successful write but *before* the response is
     * sent, so a client that refetches immediately reads the settled state.
     * $rows are the rows written (or, for DELETE, the rows just removed).
     */
    protected function afterWrite(string $method, array $rows): void
    {
        // no-op by default
    }
}
