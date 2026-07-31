<?php
// Entry point → GroupUpdateController. Chit-group activity computed live from
// chit_members + chit_groups, driven by Settings ▸ Groups Updates.
//   GET  /backend/group_updates.php   → { items: [ …members with due contributions… ] }
//   POST /backend/group_updates.php   → dispatch contribution-due alerts (admin/agent)
require_once __DIR__ . '/bootstrap.php';
send_cors();

(new GroupUpdateController())->handle();
