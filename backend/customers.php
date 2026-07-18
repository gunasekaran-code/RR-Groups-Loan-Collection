<?php
// Entry point → CustomerController.  Admin-only create/update of a customer
// record plus its optional linked login account.
require_once __DIR__ . '/bootstrap.php';
send_cors();

(new CustomerController())->handle();
