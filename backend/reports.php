
<?php
// ============================================================
//  Reports API entry point.
//  Serves pre-aggregated report data for the frontend
//  ReportsScreen (daily / monthly / agent performance).
//
//  Usage:
//    GET reports.php?action=daily&date=2026-07-30
//    GET reports.php?action=monthly&start=2026-07-01&end=2026-07-30
//    GET reports.php?action=agent&start=2026-07-01&end=2026-07-30
// ============================================================

require_once __DIR__ . '/bootstrap.php';
send_cors();

$controller = new ReportController();
$controller->handle();
