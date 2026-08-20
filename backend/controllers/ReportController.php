<?php
// ============================================================
//  ReportController — server-side aggregated report data.
//
//  Actions:
//    daily   — collections + new loans for a single date
//    monthly — aggregated summaries + monthly trends
//    agent   — per-agent performance stats
//
//  All queries use parameterised dates so the DB does the heavy
//  lifting instead of downloading all rows to the browser.
// ============================================================

class ReportController extends Controller
{
    public function handle(): void
    {
        $this->requireAuth();
        $action = $_GET['action'] ?? '';

        switch ($action) {
            case 'daily':
                $this->daily();
                break;
            case 'monthly':
                $this->monthly();
                break;
            case 'agent':
                $this->agent();
                break;
            case 'net_balance':
                $this->netBalance();
                break;
            default:
                json_error('Invalid report action. Use: daily, monthly, agent, net_balance', 400);
        }
    }

    // ────────────────────────────────────────────────────────────
    //  DAILY REPORT
    // ────────────────────────────────────────────────────────────
    private function daily(): void
    {
        $date = $_GET['date'] ?? date('Y-m-d');
        $pdo  = Database::pdo();

        // --- Today's loan collections ---
        $stmt = $pdo->prepare("
            SELECT c.id, c.receipt_number, c.loan_id, c.customer_id,
                   c.customer_name, c.loan_number, c.collection_amount,
                   c.payment_method, c.collection_date, c.agent_id,
                   c.agent_name, c.notes, c.created_at
            FROM collections c
            WHERE c.collection_date = :d OR DATE(c.created_at) = :d2
            ORDER BY c.created_at DESC
        ");
        $stmt->execute([':d' => $date, ':d2' => $date]);
        $collections = $stmt->fetchAll();
        // Cast numeric fields
        foreach ($collections as &$row) {
            $row['collection_amount'] = (float)($row['collection_amount'] ?? 0);
        }
        unset($row);

        // --- Today's fund payments ---
        $stmt = $pdo->prepare("
            SELECT fp.id, fp.fund_id, fp.fund_number, fp.customer_id,
                   fp.customer_name, fp.week_no, fp.amount,
                   fp.balance_after, fp.payment_method, fp.payment_date,
                   fp.agent_id, fp.agent_name, fp.notes, fp.created_at
            FROM fund_payments fp
            WHERE fp.payment_date = :d OR DATE(fp.created_at) = :d2
            ORDER BY fp.created_at DESC
        ");
        $stmt->execute([':d' => $date, ':d2' => $date]);
        $fundPayments = $stmt->fetchAll();
        foreach ($fundPayments as &$row) {
            $row['amount']        = (float)($row['amount'] ?? 0);
            $row['balance_after'] = (float)($row['balance_after'] ?? 0);
        }
        unset($row);

        // --- New loans created today ---
        $stmt = $pdo->prepare("
            SELECT l.id, l.loan_number, l.customer_id, l.customer_name,
                   l.loan_amount, l.interest_percentage, l.loan_type,
                   l.status, l.assigned_agent, l.agent_name, l.emi,
                   l.total_interest, l.total_repayment, l.outstanding_balance,
                   l.created_at
            FROM loans l
            WHERE DATE(l.created_at) = :d
            ORDER BY l.created_at DESC
        ");
        $stmt->execute([':d' => $date]);
        $newLoans = $stmt->fetchAll();
        foreach ($newLoans as &$row) {
            $row['loan_amount']         = (float)($row['loan_amount'] ?? 0);
            $row['interest_percentage'] = (float)($row['interest_percentage'] ?? 0);
            $row['emi']                 = (float)($row['emi'] ?? 0);
            $row['total_interest']      = (float)($row['total_interest'] ?? 0);
            $row['total_repayment']     = (float)($row['total_repayment'] ?? 0);
            $row['outstanding_balance'] = (float)($row['outstanding_balance'] ?? 0);
        }
        unset($row);

        // --- Aggregated summary ---
        $stmt = $pdo->prepare("
            SELECT COALESCE(SUM(collection_amount), 0) AS total_collected,
                   COUNT(*) AS collection_count
            FROM collections
            WHERE collection_date = :d OR DATE(created_at) = :d2
        ");
        $stmt->execute([':d' => $date, ':d2' => $date]);
        $collSummary = $stmt->fetch();

        $stmt = $pdo->prepare("
            SELECT COALESCE(SUM(amount), 0) AS total_fund_collected,
                   COUNT(*) AS fund_payment_count
            FROM fund_payments
            WHERE payment_date = :d OR DATE(created_at) = :d2
        ");
        $stmt->execute([':d' => $date, ':d2' => $date]);
        $fundSummary = $stmt->fetch();

        $stmt = $pdo->prepare("
            SELECT COALESCE(SUM(loan_amount), 0) AS total_disbursed,
                   COUNT(*) AS new_loan_count
            FROM loans
            WHERE DATE(created_at) = :d
        ");
        $stmt->execute([':d' => $date]);
        $loanSummary = $stmt->fetch();

        // Overdue count as of today
        $stmt = $pdo->prepare("
            SELECT COUNT(*) AS overdue_count
            FROM loans
            WHERE status = 'overdue'
        ");
        $stmt->execute();
        $overdueRow = $stmt->fetch();

        json_out([
            'date'            => $date,
            'collections'     => $collections,
            'fund_payments'   => $fundPayments,
            'new_loans'       => $newLoans,
            'summary'         => [
                'total_collected'      => (float)$collSummary['total_collected'],
                'collection_count'     => (int)$collSummary['collection_count'],
                'total_fund_collected' => (float)$fundSummary['total_fund_collected'],
                'fund_payment_count'   => (int)$fundSummary['fund_payment_count'],
                'total_disbursed'      => (float)$loanSummary['total_disbursed'],
                'new_loan_count'       => (int)$loanSummary['new_loan_count'],
                'overdue_count'        => (int)$overdueRow['overdue_count'],
            ],
        ]);
    }

    // ────────────────────────────────────────────────────────────
    //  MONTHLY REPORT
    // ────────────────────────────────────────────────────────────
    private function monthly(): void
    {
        $start = $_GET['start'] ?? date('Y-m-01');
        $end   = $_GET['end']   ?? date('Y-m-d');
        $pdo   = Database::pdo();

        // --- Range summary ---
        $stmt = $pdo->prepare("
            SELECT COALESCE(SUM(loan_amount), 0)     AS disbursement,
                   COALESCE(SUM(total_interest), 0)   AS interest
            FROM loans
            WHERE DATE(created_at) BETWEEN :s AND :e
        ");
        $stmt->execute([':s' => $start, ':e' => $end]);
        $loanAgg = $stmt->fetch();

        $stmt = $pdo->prepare("
            SELECT COALESCE(SUM(collection_amount), 0) AS collected,
                   COUNT(*) AS collection_count
            FROM collections
            WHERE (collection_date BETWEEN :s AND :e)
               OR (collection_date IS NULL AND DATE(created_at) BETWEEN :s2 AND :e2)
        ");
        $stmt->execute([':s' => $start, ':e' => $end, ':s2' => $start, ':e2' => $end]);
        $collAgg = $stmt->fetch();

        $stmt = $pdo->prepare("
            SELECT COUNT(*) AS new_customers
            FROM customers
            WHERE DATE(created_at) BETWEEN :s AND :e
        ");
        $stmt->execute([':s' => $start, ':e' => $end]);
        $custAgg = $stmt->fetch();

        // Active / overdue loan counts
        $stmt = $pdo->prepare("SELECT COUNT(*) AS c FROM loans WHERE status = 'active'");
        $stmt->execute();
        $activeLoans = (int)$stmt->fetchColumn();

        $stmt = $pdo->prepare("SELECT COUNT(*) AS c FROM loans WHERE status = 'overdue'");
        $stmt->execute();
        $overdueLoans = (int)$stmt->fetchColumn();

        // --- Collection trend (last 8 months) ---
        $collectionTrend = [];
        for ($i = 7; $i >= 0; $i--) {
            $mStart = date('Y-m-01', strtotime("-$i months"));
            $mEnd   = date('Y-m-t',  strtotime("-$i months"));
            $label  = date('M y',    strtotime("-$i months"));

            $stmt = $pdo->prepare("
                SELECT COALESCE(SUM(collection_amount), 0) AS total
                FROM collections
                WHERE (collection_date BETWEEN :s AND :e)
                   OR (collection_date IS NULL AND DATE(created_at) BETWEEN :s2 AND :e2)
            ");
            $stmt->execute([':s' => $mStart, ':e' => $mEnd, ':s2' => $mStart, ':e2' => $mEnd]);
            $collectionTrend[] = [
                'label' => $label,
                'value' => (float)$stmt->fetchColumn(),
            ];
        }

        // --- Disbursement by month (last 6 months) ---
        $disbursementTrend = [];
        for ($i = 5; $i >= 0; $i--) {
            $mStart = date('Y-m-01', strtotime("-$i months"));
            $mEnd   = date('Y-m-t',  strtotime("-$i months"));
            $label  = date('M y',    strtotime("-$i months"));

            $stmt = $pdo->prepare("
                SELECT COALESCE(SUM(loan_amount), 0) AS total
                FROM loans
                WHERE DATE(created_at) BETWEEN :s AND :e
            ");
            $stmt->execute([':s' => $mStart, ':e' => $mEnd]);
            $disbursementTrend[] = [
                'label' => $label,
                'value' => (float)$stmt->fetchColumn(),
            ];
        }

        json_out([
            'start'   => $start,
            'end'     => $end,
            'summary' => [
                'disbursement'    => (float)$loanAgg['disbursement'],
                'interest'        => (float)$loanAgg['interest'],
                'collected'       => (float)$collAgg['collected'],
                'collection_count'=> (int)$collAgg['collection_count'],
                'new_customers'   => (int)$custAgg['new_customers'],
                'active_loans'    => $activeLoans,
                'overdue_loans'   => $overdueLoans,
            ],
            'collection_trend'    => $collectionTrend,
            'disbursement_trend'  => $disbursementTrend,
        ]);
    }

    // ────────────────────────────────────────────────────────────
    //  AGENT PERFORMANCE
    // ────────────────────────────────────────────────────────────
    private function agent(): void
    {
        $start = $_GET['start'] ?? date('Y-m-01');
        $end   = $_GET['end']   ?? date('Y-m-d');
        $pdo   = Database::pdo();

        // Get all agents
        $stmt = $pdo->prepare("
            SELECT id, full_name
            FROM profiles
            WHERE role = 'agent' AND status = 'active'
            ORDER BY full_name ASC
        ");
        $stmt->execute();
        $agents = $stmt->fetchAll();

        $rows = [];
        foreach ($agents as $ag) {
            $agentId = $ag['id'];

            // Assigned customers
            $stmt = $pdo->prepare("SELECT COUNT(*) FROM customers WHERE assigned_agent = :a");
            $stmt->execute([':a' => $agentId]);
            $assigned = (int)$stmt->fetchColumn();

            // Collections in date range
            $stmt = $pdo->prepare("
                SELECT COUNT(*) AS cnt, COALESCE(SUM(collection_amount), 0) AS total
                FROM collections
                WHERE agent_id = :a
                  AND ((collection_date BETWEEN :s AND :e)
                    OR (collection_date IS NULL AND DATE(created_at) BETWEEN :s2 AND :e2))
            ");
            $stmt->execute([':a' => $agentId, ':s' => $start, ':e' => $end, ':s2' => $start, ':e2' => $end]);
            $collRow = $stmt->fetch();

            // Total loans assigned
            $stmt = $pdo->prepare("SELECT COUNT(*) FROM loans WHERE assigned_agent = :a");
            $stmt->execute([':a' => $agentId]);
            $totalLoans = (int)$stmt->fetchColumn();

            // Closed/paid loans
            $stmt = $pdo->prepare("
                SELECT COUNT(*) FROM loans
                WHERE assigned_agent = :a AND (status = 'closed' OR outstanding_balance <= 0)
            ");
            $stmt->execute([':a' => $agentId]);
            $paidLoans = (int)$stmt->fetchColumn();

            // Overdue loans
            $stmt = $pdo->prepare("
                SELECT COUNT(*) FROM loans
                WHERE assigned_agent = :a AND status = 'overdue'
            ");
            $stmt->execute([':a' => $agentId]);
            $overdueLoans = (int)$stmt->fetchColumn();

            $efficiency = $totalLoans > 0 ? round(($paidLoans / $totalLoans) * 100) : 0;

            $rows[] = [
                'id'           => $agentId,
                'name'         => $ag['full_name'],
                'assigned'     => $assigned,
                'coll_count'   => (int)$collRow['cnt'],
                'coll_sum'     => (float)$collRow['total'],
                'total_loans'  => $totalLoans,
                'paid_loans'   => $paidLoans,
                'overdue_loans'=> $overdueLoans,
                'efficiency'   => $efficiency,
            ];
        }

        // Sort by collection sum descending
        usort($rows, fn($a, $b) => $b['coll_sum'] <=> $a['coll_sum']);

        // Agent collection chart data
        $chart = array_map(fn($r) => [
            'label' => explode(' ', $r['name'])[0],
            'value' => $r['coll_sum'],
        ], $rows);

        json_out([
            'start' => $start,
            'end'   => $end,
            'agents' => $rows,
            'chart'  => $chart,
        ]);
    }

    // ────────────────────────────────────────────────────────────
    //  NET BALANCE AGGREGATES
    // ────────────────────────────────────────────────────────────
    private function netBalance(): void
    {
        json_out(AccountLedger::getRealtimeSummary());
    }
}
