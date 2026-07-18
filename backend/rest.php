<?php
// Entry point → ResourceController.  Generic CRUD for ?table=<name>.
require_once __DIR__ . '/bootstrap.php';
send_cors();

$table = $_GET['table'] ?? '';
$model = Model::forTable($table);
if ($model === null) {
    json_error("Unknown table: $table", 404);
}

if ($table === 'funds') {
    $controller = new FundController($model);
} elseif ($table === 'fund_payments') {
    $controller = new FundPaymentController($model);
} else {
    $controller = new ResourceController($model);
}
$controller->handle();
