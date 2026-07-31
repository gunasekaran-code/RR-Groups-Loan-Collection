/// -----------------------------------------------------------------------
/// REPORT MODELS
/// Maps 1:1 to the JSON shapes returned by ReportController (reports.php)
/// -----------------------------------------------------------------------
library report_model;

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String _toStr(dynamic v) => v?.toString() ?? '';

/// A single labelled data point used by both the line and bar charts
/// (collection trend, disbursement trend, collections-by-agent chart).
class MonthPoint {
  const MonthPoint(this.label, this.value);
  final String label;
  final double value;

  factory MonthPoint.fromJson(Map<String, dynamic> json) => MonthPoint(
        _toStr(json['label']),
        _toDouble(json['value']),
      );
}

/// -----------------------------------------------------------------------
/// DAILY REPORT
/// -----------------------------------------------------------------------
class CollectionEntry {
  const CollectionEntry({
    required this.id,
    required this.receiptNumber,
    required this.loanId,
    required this.customerId,
    required this.customerName,
    required this.loanNumber,
    required this.collectionAmount,
    required this.paymentMethod,
    required this.collectionDate,
    required this.agentId,
    required this.agentName,
    required this.notes,
    required this.createdAt,
  });

  final int id;
  final String receiptNumber;
  final int loanId;
  final int customerId;
  final String customerName;
  final String loanNumber;
  final double collectionAmount;
  final String paymentMethod;
  final String collectionDate;
  final int? agentId;
  final String? agentName;
  final String? notes;
  final String createdAt;

  factory CollectionEntry.fromJson(Map<String, dynamic> json) => CollectionEntry(
        id: _toInt(json['id']),
        receiptNumber: _toStr(json['receipt_number']),
        loanId: _toInt(json['loan_id']),
        customerId: _toInt(json['customer_id']),
        customerName: _toStr(json['customer_name']),
        loanNumber: _toStr(json['loan_number']),
        collectionAmount: _toDouble(json['collection_amount']),
        paymentMethod: _toStr(json['payment_method']),
        collectionDate: _toStr(json['collection_date']),
        agentId: json['agent_id'] == null ? null : _toInt(json['agent_id']),
        agentName: json['agent_name']?.toString(),
        notes: json['notes']?.toString(),
        createdAt: _toStr(json['created_at']),
      );
}

class FundPaymentEntry {
  const FundPaymentEntry({
    required this.id,
    required this.fundId,
    required this.fundNumber,
    required this.customerId,
    required this.customerName,
    required this.weekNo,
    required this.amount,
    required this.balanceAfter,
    required this.paymentMethod,
    required this.paymentDate,
    required this.agentId,
    required this.agentName,
    required this.notes,
    required this.createdAt,
  });

  final int id;
  final int fundId;
  final String fundNumber;
  final int customerId;
  final String customerName;
  final int weekNo;
  final double amount;
  final double balanceAfter;
  final String paymentMethod;
  final String paymentDate;
  final int? agentId;
  final String? agentName;
  final String? notes;
  final String createdAt;

  factory FundPaymentEntry.fromJson(Map<String, dynamic> json) => FundPaymentEntry(
        id: _toInt(json['id']),
        fundId: _toInt(json['fund_id']),
        fundNumber: _toStr(json['fund_number']),
        customerId: _toInt(json['customer_id']),
        customerName: _toStr(json['customer_name']),
        weekNo: _toInt(json['week_no']),
        amount: _toDouble(json['amount']),
        balanceAfter: _toDouble(json['balance_after']),
        paymentMethod: _toStr(json['payment_method']),
        paymentDate: _toStr(json['payment_date']),
        agentId: json['agent_id'] == null ? null : _toInt(json['agent_id']),
        agentName: json['agent_name']?.toString(),
        notes: json['notes']?.toString(),
        createdAt: _toStr(json['created_at']),
      );
}

class NewLoanEntry {
  const NewLoanEntry({
    required this.id,
    required this.loanNumber,
    required this.customerId,
    required this.customerName,
    required this.loanAmount,
    required this.interestPercentage,
    required this.loanType,
    required this.status,
    required this.assignedAgent,
    required this.agentName,
    required this.emi,
    required this.totalInterest,
    required this.totalRepayment,
    required this.outstandingBalance,
    required this.createdAt,
  });

  final int id;
  final String loanNumber;
  final int customerId;
  final String customerName;
  final double loanAmount;
  final double interestPercentage;
  final String loanType;
  final String status;
  final int? assignedAgent;
  final String? agentName;
  final double emi;
  final double totalInterest;
  final double totalRepayment;
  final double outstandingBalance;
  final String createdAt;

  factory NewLoanEntry.fromJson(Map<String, dynamic> json) => NewLoanEntry(
        id: _toInt(json['id']),
        loanNumber: _toStr(json['loan_number']),
        customerId: _toInt(json['customer_id']),
        customerName: _toStr(json['customer_name']),
        loanAmount: _toDouble(json['loan_amount']),
        interestPercentage: _toDouble(json['interest_percentage']),
        loanType: _toStr(json['loan_type']),
        status: _toStr(json['status']),
        assignedAgent: json['assigned_agent'] == null ? null : _toInt(json['assigned_agent']),
        agentName: json['agent_name']?.toString(),
        emi: _toDouble(json['emi']),
        totalInterest: _toDouble(json['total_interest']),
        totalRepayment: _toDouble(json['total_repayment']),
        outstandingBalance: _toDouble(json['outstanding_balance']),
        createdAt: _toStr(json['created_at']),
      );
}

class DailyReportSummary {
  const DailyReportSummary({
    required this.totalCollected,
    required this.collectionCount,
    required this.totalFundCollected,
    required this.fundPaymentCount,
    required this.totalDisbursed,
    required this.newLoanCount,
    required this.overdueCount,
  });

  final double totalCollected;
  final int collectionCount;
  final double totalFundCollected;
  final int fundPaymentCount;
  final double totalDisbursed;
  final int newLoanCount;
  final int overdueCount;

  factory DailyReportSummary.fromJson(Map<String, dynamic> json) => DailyReportSummary(
        totalCollected: _toDouble(json['total_collected']),
        collectionCount: _toInt(json['collection_count']),
        totalFundCollected: _toDouble(json['total_fund_collected']),
        fundPaymentCount: _toInt(json['fund_payment_count']),
        totalDisbursed: _toDouble(json['total_disbursed']),
        newLoanCount: _toInt(json['new_loan_count']),
        overdueCount: _toInt(json['overdue_count']),
      );
}

class DailyReport {
  const DailyReport({
    required this.date,
    required this.collections,
    required this.fundPayments,
    required this.newLoans,
    required this.summary,
  });

  final String date;
  final List<CollectionEntry> collections;
  final List<FundPaymentEntry> fundPayments;
  final List<NewLoanEntry> newLoans;
  final DailyReportSummary summary;

  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
        date: _toStr(json['date']),
        collections: (json['collections'] as List? ?? [])
            .map((e) => CollectionEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        fundPayments: (json['fund_payments'] as List? ?? [])
            .map((e) => FundPaymentEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        newLoans: (json['new_loans'] as List? ?? [])
            .map((e) => NewLoanEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        summary: DailyReportSummary.fromJson(
            (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}

/// -----------------------------------------------------------------------
/// MONTHLY REPORT
/// -----------------------------------------------------------------------
class MonthlyReportSummary {
  const MonthlyReportSummary({
    required this.disbursement,
    required this.interest,
    required this.collected,
    required this.collectionCount,
    required this.newCustomers,
    required this.activeLoans,
    required this.overdueLoans,
  });

  final double disbursement;
  final double interest;
  final double collected;
  final int collectionCount;
  final int newCustomers;
  final int activeLoans;
  final int overdueLoans;

  factory MonthlyReportSummary.fromJson(Map<String, dynamic> json) => MonthlyReportSummary(
        disbursement: _toDouble(json['disbursement']),
        interest: _toDouble(json['interest']),
        collected: _toDouble(json['collected']),
        collectionCount: _toInt(json['collection_count']),
        newCustomers: _toInt(json['new_customers']),
        activeLoans: _toInt(json['active_loans']),
        overdueLoans: _toInt(json['overdue_loans']),
      );
}

class MonthlyReport {
  const MonthlyReport({
    required this.start,
    required this.end,
    required this.summary,
    required this.collectionTrend,
    required this.disbursementTrend,
  });

  final String start;
  final String end;
  final MonthlyReportSummary summary;
  final List<MonthPoint> collectionTrend;
  final List<MonthPoint> disbursementTrend;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) => MonthlyReport(
        start: _toStr(json['start']),
        end: _toStr(json['end']),
        summary: MonthlyReportSummary.fromJson(
            (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {}),
        collectionTrend: (json['collection_trend'] as List? ?? [])
            .map((e) => MonthPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        disbursementTrend: (json['disbursement_trend'] as List? ?? [])
            .map((e) => MonthPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// -----------------------------------------------------------------------
/// AGENT PERFORMANCE REPORT
/// -----------------------------------------------------------------------
class AgentPerformanceEntry {
  const AgentPerformanceEntry({
    required this.id,
    required this.name,
    required this.assigned,
    required this.collCount,
    required this.collSum,
    required this.totalLoans,
    required this.paidLoans,
    required this.overdueLoans,
    required this.efficiency,
  });

  final String id;
  final String name;
  final int assigned;
  final int collCount;
  final double collSum;
  final int totalLoans;
  final int paidLoans;
  final int overdueLoans;
  final int efficiency;

  factory AgentPerformanceEntry.fromJson(Map<String, dynamic> json) => AgentPerformanceEntry(
        id: _toStr(json['id']),
        name: _toStr(json['name']),
        assigned: _toInt(json['assigned']),
        collCount: _toInt(json['coll_count']),
        collSum: _toDouble(json['coll_sum']),
        totalLoans: _toInt(json['total_loans']),
        paidLoans: _toInt(json['paid_loans']),
        overdueLoans: _toInt(json['overdue_loans']),
        efficiency: _toInt(json['efficiency']),
      );
}

class AgentReport {
  const AgentReport({
    required this.start,
    required this.end,
    required this.agents,
    required this.chart,
  });

  final String start;
  final String end;
  final List<AgentPerformanceEntry> agents;
  final List<MonthPoint> chart;

  factory AgentReport.fromJson(Map<String, dynamic> json) => AgentReport(
        start: _toStr(json['start']),
        end: _toStr(json['end']),
        agents: (json['agents'] as List? ?? [])
            .map((e) => AgentPerformanceEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        chart: (json['chart'] as List? ?? [])
            .map((e) => MonthPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}