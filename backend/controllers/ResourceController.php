<?php
// Generic JWT-protected CRUD for any whitelisted table, delegating to its Model.

class ResourceController extends Controller
{
    /** @var class-string<Model> */
    private string $model;

    public function __construct(string $modelClass)
    {
        $this->model = $modelClass;
    }

    public function handle(): void
    {
        $this->requireAuth();
        switch ($_SERVER['REQUEST_METHOD'] ?? 'GET') {
            case 'GET':    $this->index();   break;
            case 'POST':   $this->store();   break;
            case 'PATCH':
            case 'PUT':    $this->update();  break;
            case 'DELETE': $this->destroy(); break;
            default:       json_error('Method not allowed', 405);
        }
    }

    private function index(): void
    {
        $model = $this->model;
        $columns = $model::columns();
        [$where, $binds] = QueryParser::where($columns);
        json_out($model::select($where, $binds, QueryParser::order($columns), QueryParser::limit()));
    }

    private function store(): void
    {
        $model = $this->model;
        $body = $this->body();
        $isList = $body !== [] && array_keys($body) === range(0, count($body) - 1);
        $rows = $isList ? $body : [$body];
        $upsert = ($_GET['upsert'] ?? '') === '1';
        try {
            json_out($model::insertRows($rows, $upsert), 201);
        } catch (PDOException $e) {
            json_error('Insert failed: ' . $e->getMessage(), 400);
        }
    }

    private function update(): void
    {
        $model = $this->model;
        [$where, $binds] = QueryParser::where($model::columns());
        if ($where === '') {
            json_error('Refusing to update without a filter', 400);
        }
        try {
            json_out($model::updateWhere($this->body(), $where, $binds));
        } catch (PDOException $e) {
            json_error('Update failed: ' . $e->getMessage(), 400);
        }
    }

    private function destroy(): void
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
