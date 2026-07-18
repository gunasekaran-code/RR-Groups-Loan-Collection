<?php
// Entry point → AuthController.  POST ?action=login | GET ?action=me
require_once __DIR__ . '/bootstrap.php';
send_cors();

(new AuthController())->handle($_GET['action'] ?? 'login');
