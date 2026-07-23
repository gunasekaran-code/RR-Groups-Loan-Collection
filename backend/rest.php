<?php
// Entry point → ResourceController.  Generic CRUD for ?table=<name>.
require_once __DIR__ . '/bootstrap.php';
send_cors();

$table = $_GET['table'] ?? '';
$model = Model::forTable($table);
if ($model === null) {
    json_error("Unknown table: $table", 404);
}

// Each whitelisted table gets a controller that enforces role-based writes.
// Reads stay open to any authenticated user; the frontend scopes rows per role.
$controllers = [
    'funds'              => FundController::class,
    'fund_payments'      => FundPaymentController::class,
    'handovers'          => HandoverController::class,
    'loans'              => LoanController::class,
    'profiles'           => AgentController::class,
    'customers'          => CustomerRestController::class,
    'collections'        => CollectionController::class,
    'repayment_schedule' => ScheduleController::class,
    'chit_groups'        => ChitGroupController::class,
    'chit_members'       => ChitMemberController::class,
    'notifications'      => NotificationController::class,
    'settings'           => SettingController::class,
    'push_subscriptions' => PushSubscriptionController::class,
];
$controllerClass = $controllers[$table] ?? ResourceController::class;
$controller = new $controllerClass($model);
$controller->handle();
