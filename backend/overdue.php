<?php
// Entry point → OverdueController. Live overdue accounts computed from
// loans + repayment_schedule (no stored "overdues" table).
//   GET  /backend/overdue.php   → [ { loan_id, loan_number, customer_name,
//                                     overdue_amount, days_overdue, ... }, … ]
//   POST /backend/overdue.php   → recompute loan statuses (admin/agent)
require_once __DIR__ . '/bootstrap.php';
send_cors();

(new OverdueController())->handle();
