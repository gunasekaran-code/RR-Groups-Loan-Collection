<?php
// ============================================================
//  AccountLedger Model — Executive Account Book & Net Balance
//  Provides real-time financial aggregation across all modules:
//    - Loans (disbursements, active/overdue outstanding balances, collections)
//    - Chits (chit groups, collections, pending balances)
//    - Funds (savings funds, collections, pending balances)
//    - Handovers & Custom Ledger adjustments (capital, expenses, custom lent)
// ============================================================

class AccountLedger extends Model
{
    protected static string $table = 'account_ledger';

    // Entry Types
    public const TYPE_CASH_IN        = 'cash_in';
    public const TYPE_CAPITAL        = 'capital';
    public const TYPE_CASH_OUT       = 'cash_out';
    public const TYPE_EXPENSE        = 'expense';
    public const TYPE_LENT_OUT       = 'lent_out';
    public const TYPE_LENT_ACTIVE    = 'lent_active';
    public const TYPE_LENT_OVERDUE   = 'lent_overdue';
    public const TYPE_LENT_COLLECTED = 'lent_collected';

    public const CASH_TYPES = [
        self::TYPE_CASH_IN,
        self::TYPE_CAPITAL,
        self::TYPE_CASH_OUT,
        self::TYPE_EXPENSE,
    ];

    public const LENT_TYPES = [
        self::TYPE_LENT_OUT,
        self::TYPE_LENT_ACTIVE,
        self::TYPE_LENT_OVERDUE,
        self::TYPE_LENT_COLLECTED,
    ];

    public const ALL_TYPES = [
        self::TYPE_CASH_IN,
        self::TYPE_CAPITAL,
        self::TYPE_CASH_OUT,
        self::TYPE_EXPENSE,
        self::TYPE_LENT_OUT,
        self::TYPE_LENT_ACTIVE,
        self::TYPE_LENT_OVERDUE,
        self::TYPE_LENT_COLLECTED,
    ];

    /**
     * Compute full, live real-time financial position directly from the database.
     * Guaranteed single-source-of-truth for Account Book & Net Balance.
     */
    public static function getRealtimeSummary(): array
    {
        $pdo = Database::pdo();

        // 1. Loan Collections Received
        $stmt = $pdo->prepare("SELECT COALESCE(SUM(collection_amount), 0) FROM collections");
        $stmt->execute();
        $loanCollections = (float)$stmt->fetchColumn();

        // 2. Fund Deposits Received
        $stmt = $pdo->prepare("SELECT COALESCE(SUM(amount), 0) FROM fund_payments");
        $stmt->execute();
        $fundDeposits = (float)$stmt->fetchColumn();

        // 3. Chit Members Collections Received (paid or partial)
        $stmt = $pdo->prepare("SELECT COALESCE(SUM(contribution_amount), 0) FROM chit_members WHERE payment_status IN ('paid', 'partial')");
        $stmt->execute();
        $chitCollected = (float)$stmt->fetchColumn();

        // 4. Custom Cash In / Capital additions from ledger
        $stmt = $pdo->prepare("SELECT COALESCE(SUM(amount), 0) FROM account_ledger WHERE entry_type IN ('cash_in', 'capital')");
        $stmt->execute();
        $customCashIn = (float)$stmt->fetchColumn();

        // 5. Custom Cash Out / Expenses from ledger
        $stmt = $pdo->prepare("SELECT COALESCE(SUM(amount), 0) FROM account_ledger WHERE entry_type IN ('cash_out', 'expense')");
        $stmt->execute();
        $customCashOut = (float)$stmt->fetchColumn();

        // Cash In Hand Total (கையிருப்பு)
        $cashInHand = max(0, $loanCollections + $fundDeposits + $chitCollected + $customCashIn - $customCashOut);

        // 6. Active Loans Outstanding
        $stmt = $pdo->prepare("SELECT COUNT(*) as count, COALESCE(SUM(outstanding_balance), 0) as outstanding FROM loans WHERE status = 'active'");
        $stmt->execute();
        $activeLoansRow = $stmt->fetch(PDO::FETCH_ASSOC) ?: ['count' => 0, 'outstanding' => 0];
        $activeLoansCount = (int)($activeLoansRow['count'] ?? 0);
        $activeLoanOutstanding = (float)($activeLoansRow['outstanding'] ?? 0);

        // 7. Overdue Loans Outstanding
        $stmt = $pdo->prepare("SELECT COUNT(*) as count, COALESCE(SUM(outstanding_balance), 0) as outstanding FROM loans WHERE status = 'overdue'");
        $stmt->execute();
        $overdueLoansRow = $stmt->fetch(PDO::FETCH_ASSOC) ?: ['count' => 0, 'outstanding' => 0];
        $overdueLoansCount = (int)($overdueLoansRow['count'] ?? 0);
        $overdueLoanOutstanding = (float)($overdueLoansRow['outstanding'] ?? 0);

        $totalLoanOutstanding = $activeLoanOutstanding + $overdueLoanOutstanding;

        // Total Loans Principal Disbursed
        $stmt = $pdo->prepare("SELECT COALESCE(SUM(loan_amount), 0) FROM loans WHERE status IN ('active', 'overdue', 'closed')");
        $stmt->execute();
        $totalLoansGiven = (float)$stmt->fetchColumn();

        // 8. Chit Groups (Active)
        $stmt = $pdo->prepare("SELECT COUNT(*) as count, COALESCE(SUM(group_value), 0) as group_val, COALESCE(SUM(collected_amount), 0) as coll, COALESCE(SUM(pending_amount), 0) as pend FROM chit_groups WHERE status = 'active'");
        $stmt->execute();
        $chitRow = $stmt->fetch(PDO::FETCH_ASSOC) ?: ['count' => 0, 'group_val' => 0, 'coll' => 0, 'pend' => 0];
        $activeChitsCount = (int)($chitRow['count'] ?? 0);
        $chitGroupValue = (float)($chitRow['group_val'] ?? 0);
        $chitCollectedAmount = (float)($chitRow['coll'] ?? 0);
        $chitPendingAmount = (float)($chitRow['pend'] ?? 0);

        // 9. Savings Funds (Active)
        $stmt = $pdo->prepare("SELECT COUNT(*) as count, COALESCE(SUM(IFNULL(deposit_amount, total_amount)), 0) as total_dep, COALESCE(SUM(collected_amount), 0) as coll FROM funds WHERE status = 'active'");
        $stmt->execute();
        $fundRow = $stmt->fetch(PDO::FETCH_ASSOC) ?: ['count' => 0, 'total_dep' => 0, 'coll' => 0];
        $activeFundsCount = (int)($fundRow['count'] ?? 0);
        $fundTotalDeposit = (float)($fundRow['total_dep'] ?? 0);
        $fundCollectedAmount = (float)($fundRow['coll'] ?? 0);
        $fundPendingAmount = max(0, $fundTotalDeposit - $fundCollectedAmount);

        // 10. Custom Lent Out & Recovered
        $stmt = $pdo->prepare("SELECT COALESCE(SUM(amount), 0) FROM account_ledger WHERE entry_type IN ('lent_out', 'lent_active', 'lent_overdue')");
        $stmt->execute();
        $customLentOut = (float)$stmt->fetchColumn();

        $stmt = $pdo->prepare("SELECT COALESCE(SUM(amount), 0) FROM account_ledger WHERE entry_type = 'lent_collected'");
        $stmt->execute();
        $customLentCollected = (float)$stmt->fetchColumn();
        $customLentNet = max(0, $customLentOut - $customLentCollected);

        // Total Outstanding Money Lent (வெளி கடன்)
        $outstandingMoneyLent = $totalLoanOutstanding + $chitPendingAmount + $fundPendingAmount + $customLentNet;

        // Total Net Balance / Working Capital Position (மொத்த இருப்பு)
        $netBalance = $cashInHand + $outstandingMoneyLent;

        return [
            // Cash In Hand
            'loanCollections'        => $loanCollections,
            'fundDeposits'           => $fundDeposits,
            'chitCollected'          => $chitCollected,
            'customCashIn'           => $customCashIn,
            'customCashOut'          => $customCashOut,
            'cashInHand'             => $cashInHand,

            // Loans
            'activeLoansCount'       => $activeLoansCount,
            'activeLoanOutstanding'  => $activeLoanOutstanding,
            'overdueLoansCount'      => $overdueLoansCount,
            'overdueLoanOutstanding' => $overdueLoanOutstanding,
            'totalLoanOutstanding'   => $totalLoanOutstanding,
            'totalLoansGiven'        => $totalLoansGiven,

            // Chits
            'activeChitsCount'       => $activeChitsCount,
            'chitGroupValue'         => $chitGroupValue,
            'chitCollectedAmount'    => $chitCollectedAmount,
            'chitPendingAmount'      => $chitPendingAmount,

            // Funds
            'activeFundsCount'       => $activeFundsCount,
            'fundTotalDeposit'       => $fundTotalDeposit,
            'fundCollectedAmount'    => $fundCollectedAmount,
            'fundPendingAmount'      => $fundPendingAmount,

            // Custom Lent
            'customLentOut'          => $customLentOut,
            'customLentCollected'    => $customLentCollected,
            'customLentNet'          => $customLentNet,

            // Totals
            'outstandingMoneyLent'   => $outstandingMoneyLent,
            'netBalance'             => $netBalance,
        ];
    }

    /**
     * Fetch a unified, chronologically ordered transaction stream across all financial operations.
     */
    public static function getUnifiedTransactions(int $limit = 500, int $offset = 0, ?string $filterType = null): array
    {
        $pdo = Database::pdo();
        $queries = [];

        // 1. Account Ledger Entries.
        //    A chit contribution lives here too, so the module has to come from
        //    the category — hardcoding 'ledger' filed every chit receipt under
        //    Custom/Expenses and left the Chit Groups filter empty.
        $queries[] = "
            SELECT 
                id,
                entry_date as txn_date,
                entry_date,
                title,
                CASE
                    WHEN LOWER(category) LIKE '%chit%' THEN 'chit'
                    WHEN LOWER(category) LIKE '%fund%' THEN 'fund'
                    WHEN LOWER(category) LIKE '%loan%' THEN 'loan'
                    ELSE 'ledger'
                END as module,
                category,
                entry_type as txn_type,
                entry_type,
                amount,
                notes,
                agent_name as collector,
                1 as is_custom,
                created_at
            FROM account_ledger
        ";

        // 2. Loan Collections
        $queries[] = "
            SELECT 
                id,
                DATE(COALESCE(collection_date, created_at)) as txn_date,
                DATE(COALESCE(collection_date, created_at)) as entry_date,
                CONCAT('Loan Collection: ', IFNULL(customer_name, 'Customer'), ' (', IFNULL(loan_number, ''), ')') as title,
                'loan' as module,
                'Loan Collection' as category,
                'cash_in' as txn_type,
                'cash_in' as entry_type,
                collection_amount as amount,
                CONCAT('Receipt: ', IFNULL(receipt_number, 'N/A'), ' | Method: ', UPPER(IFNULL(payment_method, 'CASH')), ' | Collector: ', IFNULL(agent_name, 'Direct')) as notes,
                agent_name as collector,
                0 as is_custom,
                created_at
            FROM collections
        ";

        // 3. Fund Payments / Deposits
        $queries[] = "
            SELECT 
                id,
                DATE(COALESCE(payment_date, created_at)) as txn_date,
                DATE(COALESCE(payment_date, created_at)) as entry_date,
                CONCAT('Fund Deposit: ', IFNULL(customer_name, 'Customer'), ' (', IFNULL(fund_number, ''), ' - W', IFNULL(week_no, 1), ')') as title,
                'fund' as module,
                'Fund Deposit' as category,
                'cash_in' as txn_type,
                'cash_in' as entry_type,
                amount,
                CONCAT('Method: ', UPPER(IFNULL(payment_method, 'CASH')), ' | Collector: ', IFNULL(agent_name, 'Direct')) as notes,
                agent_name as collector,
                0 as is_custom,
                created_at
            FROM fund_payments
        ";

        // Combine
        $unionSql = implode(" UNION ALL ", $queries);
        $sql = "SELECT * FROM ($unionSql) as combined_stream ";

        $params = [];
        if ($filterType === 'cash') {
            $sql .= " WHERE txn_type IN ('cash_in', 'capital', 'cash_out', 'expense')";
        } elseif ($filterType === 'lent') {
            $sql .= " WHERE txn_type IN ('lent_out', 'lent_active', 'lent_overdue', 'lent_collected')";
        }

        $sql .= " ORDER BY txn_date DESC, created_at DESC LIMIT " . (int)$limit . " OFFSET " . (int)$offset;

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return array_map(function ($row) {
            $row['amount'] = (float)$row['amount'];
            $row['is_custom'] = (bool)($row['is_custom'] ?? 0);
            return $row;
        }, $rows);
    }

    /**
     * Fetch all outstanding debtors / balances across Loans, Chit Groups, Funds, and Custom Money Lent.
     */
    public static function getOutstandingDebtors(): array
    {
        $pdo = Database::pdo();
        $outstanding = [];

        // 1. Outstanding Loans
        $loans = $pdo->query("
            SELECT 
                id,
                loan_number as ref_number,
                customer_name as debtor_name,
                'loan' as module,
                'Loan Outstanding' as category,
                loan_amount as total_disbursed,
                total_repayment,
                (total_repayment - outstanding_balance) as amount_paid,
                outstanding_balance,
                start_date,
                status,
                agent_name as collector_name,
                created_at
            FROM loans
            WHERE outstanding_balance > 0 AND status IN ('active', 'overdue')
            ORDER BY outstanding_balance DESC
        ")->fetchAll(PDO::FETCH_ASSOC);

        foreach ($loans as $l) {
            $outstanding[] = [
                'id' => $l['id'],
                'title' => ($l['debtor_name'] ?? 'Customer') . ' (' . $l['ref_number'] . ')',
                'debtor_name' => $l['debtor_name'] ?? 'Unknown Customer',
                'ref_number' => $l['ref_number'],
                'module' => 'loan',
                'category' => 'Loan Outstanding',
                'section' => 'lent',
                'entry_type' => $l['status'] === 'overdue' ? 'lent_overdue' : 'lent_active',
                'total_amount' => (float)$l['total_repayment'],
                'paid_amount' => (float)$l['amount_paid'],
                'amount' => (float)$l['outstanding_balance'],
                'status' => $l['status'],
                'collector' => $l['collector_name'] ?? 'Direct',
                'entry_date' => $l['start_date'] ?? substr($l['created_at'], 0, 10),
                'notes' => 'Loan Repayment: ' . $l['total_repayment'] . ' | Paid: ' . $l['amount_paid'] . ' | Balance: ' . $l['outstanding_balance'],
                'is_custom' => false
            ];
        }

        // 2. Chit Pending Groups
        $chits = $pdo->query("
            SELECT 
                g.id,
                g.group_number as ref_number,
                g.group_name as debtor_name,
                'chit' as module,
                'Chit Pending' as category,
                g.group_value as total_given,
                g.collected_amount as amount_paid,
                g.pending_amount as outstanding_amount,
                g.start_date,
                g.status,
                'Office' as collector_name,
                g.created_at
            FROM chit_groups g
            WHERE g.pending_amount > 0 AND g.status = 'active'
            ORDER BY g.pending_amount DESC
        ")->fetchAll(PDO::FETCH_ASSOC);

        foreach ($chits as $c) {
            $outstanding[] = [
                'id' => $c['id'],
                'title' => 'Chit Group: ' . $c['debtor_name'] . ' (' . $c['ref_number'] . ')',
                'debtor_name' => $c['debtor_name'],
                'ref_number' => $c['ref_number'],
                'module' => 'chit',
                'category' => 'Chit Pending',
                'section' => 'lent',
                'entry_type' => 'lent_active',
                'total_amount' => (float)$c['total_given'],
                'paid_amount' => (float)$c['amount_paid'],
                'amount' => (float)$c['outstanding_amount'],
                'status' => $c['status'],
                'collector' => 'Office',
                'entry_date' => $c['start_date'] ?? substr($c['created_at'], 0, 10),
                'notes' => 'Total Value: ' . $c['total_given'] . ' | Collected: ' . $c['amount_paid'] . ' | Pending: ' . $c['outstanding_amount'],
                'is_custom' => false
            ];
        }

        // 3. Funds Pending
        $funds = $pdo->query("
            SELECT 
                f.id,
                f.fund_number as ref_number,
                f.customer_name as debtor_name,
                'fund' as module,
                'Fund Remaining' as category,
                f.deposit_amount as total_given,
                f.collected_amount as amount_paid,
                (f.deposit_amount - f.collected_amount) as outstanding_amount,
                f.start_date,
                f.status,
                f.agent_name as collector_name,
                f.created_at
            FROM funds f
            WHERE f.status = 'active' AND (f.deposit_amount - f.collected_amount) > 0
            ORDER BY (f.deposit_amount - f.collected_amount) DESC
        ")->fetchAll(PDO::FETCH_ASSOC);

        foreach ($funds as $f) {
            $outstanding[] = [
                'id' => $f['id'],
                'title' => 'Fund Pending: ' . ($f['debtor_name'] ?? 'Customer') . ' (' . $f['ref_number'] . ')',
                'debtor_name' => $f['debtor_name'] ?? 'Customer',
                'ref_number' => $f['ref_number'],
                'module' => 'fund',
                'category' => 'Fund Remaining',
                'section' => 'lent',
                'entry_type' => 'lent_active',
                'total_amount' => (float)$f['total_given'],
                'paid_amount' => (float)$f['amount_paid'],
                'amount' => (float)$f['outstanding_amount'],
                'status' => $f['status'],
                'collector' => $f['collector_name'] ?? 'Direct',
                'entry_date' => $f['start_date'] ?? substr($f['created_at'], 0, 10),
                'notes' => 'Target: ' . $f['total_given'] . ' | Deposited: ' . $f['amount_paid'] . ' | Remaining: ' . $f['outstanding_amount'],
                'is_custom' => false
            ];
        }

        // 4. Custom Money Lent in account_ledger
        $customLent = $pdo->query("
            SELECT 
                id,
                'CUSTOM' as ref_number,
                title as debtor_name,
                'ledger' as module,
                category,
                amount as total_given,
                0 as amount_paid,
                amount as outstanding_amount,
                entry_date as start_date,
                entry_type as status,
                'Admin' as collector_name,
                notes,
                created_at
            FROM account_ledger
            WHERE entry_type IN ('lent_out', 'lent_active', 'lent_overdue')
            ORDER BY entry_date DESC
        ")->fetchAll(PDO::FETCH_ASSOC);

        foreach ($customLent as $cl) {
            $outstanding[] = [
                'id' => $cl['id'],
                'title' => $cl['debtor_name'],
                'debtor_name' => $cl['debtor_name'],
                'ref_number' => $cl['ref_number'],
                'module' => 'ledger',
                'category' => $cl['category'] ?? 'Money Lent',
                'section' => 'lent',
                'entry_type' => $cl['status'],
                'total_amount' => (float)$cl['total_given'],
                'paid_amount' => 0.0,
                'amount' => (float)$cl['outstanding_amount'],
                'status' => $cl['status'],
                'collector' => 'Admin',
                'entry_date' => $cl['start_date'] ?? substr($cl['created_at'], 0, 10),
                'notes' => $cl['notes'] ?? 'Custom money lent entry',
                'is_custom' => true
            ];
        }

        return $outstanding;
    }

    /**
     * Validate an account ledger entry payload before saving.
     */
    public static function validateEntry(array $data): array
    {
        $errors = [];

        $title = trim($data['title'] ?? '');
        if ($title === '') {
            $errors[] = 'Title is required';
        }

        $amount = (float)($data['amount'] ?? 0);
        if ($amount <= 0) {
            $errors[] = 'Amount must be greater than zero';
        }

        $entryType = trim($data['entry_type'] ?? '');
        if ($entryType === '' || !in_array($entryType, self::ALL_TYPES, true)) {
            $errors[] = 'Valid entry type is required';
        }

        return $errors;
    }
}
