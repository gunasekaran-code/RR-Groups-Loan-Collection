<?php
// ============================================================
//  Account Book & Net Balance Entry Point
//  Provides direct access to account ledger actions and records.
//  Endpoints:
//    - GET /backend/account_book.php?action=summary   (or net_balance)
//    - GET /backend/account_book.php?action=stream    (or transactions)
//    - GET /backend/account_book.php                  (standard query/filter)
//    - POST/PATCH/DELETE                              (CRUD operations for admin)
// ============================================================

require_once __DIR__ . '/bootstrap.php';
send_cors();

$controller = new AccountLedgerController(AccountLedger::class);
$controller->handle();
