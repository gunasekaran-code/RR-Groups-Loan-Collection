<?php
// Entry point → UserController.  Admin-only create/update of login accounts.
require_once __DIR__ . '/bootstrap.php';
send_cors();

(new UserController())->handle();
