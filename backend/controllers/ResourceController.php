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
        $model::deleteWhere($where, $binds);
        $this->afterWrite('DELETE', $doomed);
        json_out([]);
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
