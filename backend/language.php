<?php
// Entry point → LanguageController. Interface / messaging language stored on the
// settings row (Settings ▸ Language).
//   GET  /backend/language.php              → { current, supported }
//   POST /backend/language.php { language } → set active language (admin)
require_once __DIR__ . '/bootstrap.php';
send_cors();

(new LanguageController())->handle();
