<?php
// Entry point → ChitActionController. Chit operations that are transactions
// rather than CRUD: recording a contribution, rebuilding a draw sheet.
//   POST /backend/chit.php?action=collect
//   POST /backend/chit.php?action=generate_schedule
require_once __DIR__ . '/bootstrap.php';
send_cors();

(new ChitActionController())->handle();
