<?php
// Entry point → ReminderController. Payment reminders computed live from
// repayment_schedule + loans, driven by Settings ▸ Payment Reminders.
//   GET  /backend/reminders.php   → { reminder_days, items: [ …due EMIs… ] }
//   POST /backend/reminders.php   → dispatch reminder notifications (admin/agent)
require_once __DIR__ . '/bootstrap.php';
send_cors();

(new ReminderController())->handle();
