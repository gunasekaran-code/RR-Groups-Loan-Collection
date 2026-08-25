// models/fund.dart

enum FundStatus { active, matured, settled }

// models/fund.dart
extension FundStatusX on FundStatus {
  String get label {
    switch (this) {
      case FundStatus.active:
        return 'active';
      case FundStatus.matured:
        return 'matured';
      case FundStatus.settled:
        return 'closed'; // was 'settled'
    }
  }

  static FundStatus fromString(String? v) {
    switch (v) {
      case 'matured':
        return FundStatus.matured;
      case 'closed': // was 'settled'
        return FundStatus.settled;
      default:
        return FundStatus.active;
    }
  }
}

class FundEntry {
  final int week;
  final DateTime date;
  final double amount;
  final double? balanceAfter;
  final String? method;
  final bool paid;

  FundEntry({
    required this.week,
    required this.date,
    required this.amount,
    this.balanceAfter,
    this.method,
    required this.paid,
  });

  factory FundEntry.fromJson(Map<String, dynamic> json) {
    // Backend `fund_payments` table uses `week_no`, `payment_date`,
    // `payment_method` and `amount`. Some older responses may vary,
    // so fall back to alternative keys when present.
    final weekVal = (json['week_no'] ?? json['week']) as dynamic;
    final dateStr = (json['payment_date'] ??
            json['due_date'] ??
            json['payment_at'] ??
            json['created_at'])
        ?.toString();
    final amt = _toDouble(json['amount'] ?? json['payment_amount']);
    final methodVal = (json['payment_method'] ?? json['method'])?.toString();
    final paidFlag =
        (json['paid'] == true || json['paid'] == 1 || json['paid'] == '1');

    return FundEntry(
        week: weekVal is num
          ? weekVal.toInt()
          : int.tryParse(weekVal?.toString() ?? '') ?? 0,
      date: DateTime.tryParse(dateStr ?? '') ?? DateTime.now(),
      amount: amt,
      balanceAfter: _toDoubleOrNull(json['balance_after']),
      method: methodVal,
      // Treat an entry as paid when a payment_date exists, amount > 0,
      // or an explicit paid flag is present.
      paid: paidFlag || (amt > 0) || (dateStr != null && dateStr.isNotEmpty),
    );
  }
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class Fund {
  final String id;
  final String code;
  final String customerId;
  final String customerName;
  final String? assignedAgentId;
  final String? agentName;
  final double units;
  final FundStatus status;
  final double weeklyAmount;
  final int numberOfWeeks;
  final double maturityBonus;
  final DateTime startDate;
  final DateTime maturityDate;

  /// Amount actually collected so far (backend column: collected_amount).
  final double depositedAmount;
  final int entriesPaid;

  Fund({
    required this.id,
    required this.code,
    required this.customerId,
    required this.customerName,
    this.assignedAgentId,
    this.agentName,
    this.units = 1,
    required this.status,
    required this.weeklyAmount,
    required this.numberOfWeeks,
    required this.maturityBonus,
    required this.startDate,
    required this.maturityDate,
    required this.depositedAmount,
    required this.entriesPaid,
  });

  double get totalDeposit => weeklyAmount * numberOfWeeks;
  double get maturityPayout => totalDeposit + maturityBonus;
  double get remainingToSettle => totalDeposit - depositedAmount;
  double get depositedPercent =>
      totalDeposit == 0 ? 0 : (depositedAmount / totalDeposit) * 100;

  /// Maps directly onto the `funds` table:
  /// id, fund_number, customer_id, customer_name, weekly_amount, weeks,
  /// bonus, deposit_amount, total_amount, collected_amount, start_date,
  /// maturity_date, status, created_at
  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      id: json['id'].toString(),
      code: json['fund_number']?.toString() ?? json['code']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Unknown Customer',
      assignedAgentId: json['assigned_agent']?.toString(),
      agentName: json['agent_name']?.toString(),
      units: _toDouble(json['units']) == 0 ? 1 : _toDouble(json['units']),
      status: FundStatusX.fromString(json['status']?.toString()),
      weeklyAmount: _toDouble(json['weekly_amount']),
      numberOfWeeks: (json['weeks'] as num?)?.toInt() ??
          (json['number_of_weeks'] as num?)?.toInt() ??
          0,
      maturityBonus: _toDouble(json['bonus'] ?? json['maturity_bonus']),
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ??
          DateTime.now(),
      maturityDate:
          DateTime.tryParse(json['maturity_date']?.toString() ?? '') ??
              DateTime.now(),
      depositedAmount:
          _toDouble(json['collected_amount'] ?? json['deposited_amount']),
      entriesPaid: (json['entries_paid'] as num?)?.toInt() ?? 0,
    );
  }

  /// Used for both create and update payloads — matches backend column names.
  Map<String, dynamic> toCreateJson() {
    return {
      'fund_number': code,
      'customer_id': customerId,
      'customer_name': customerName,
      'assigned_agent': assignedAgentId,
      'agent_name': agentName,
      'units': units,
      'weekly_amount': weeklyAmount,
      'weeks': numberOfWeeks,
      'bonus': maturityBonus,
      'deposit_amount': totalDeposit,
      'total_amount': maturityPayout,
      'start_date':
          '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'maturity_date':
          '${maturityDate.year.toString().padLeft(4, '0')}-${maturityDate.month.toString().padLeft(2, '0')}-${maturityDate.day.toString().padLeft(2, '0')}',
    };
  }

  Fund copyWith({
    String? id,
    String? code,
    String? customerId,
    String? customerName,
    String? assignedAgentId,
    String? agentName,
    double? units,
    FundStatus? status,
    double? weeklyAmount,
    int? numberOfWeeks,
    double? maturityBonus,
    DateTime? startDate,
    DateTime? maturityDate,
    double? depositedAmount,
    int? entriesPaid,
  }) {
    return Fund(
      id: id ?? this.id,
      code: code ?? this.code,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
      agentName: agentName ?? this.agentName,
      units: units ?? this.units,
      status: status ?? this.status,
      weeklyAmount: weeklyAmount ?? this.weeklyAmount,
      numberOfWeeks: numberOfWeeks ?? this.numberOfWeeks,
      maturityBonus: maturityBonus ?? this.maturityBonus,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      depositedAmount: depositedAmount ?? this.depositedAmount,
      entriesPaid: entriesPaid ?? this.entriesPaid,
    );
  }
}

class FundsSummary {
  final int totalFunds;
  final int activeFunds;
  final double maturityPayoutTotal;
  final double collectedTotal;

  FundsSummary({
    required this.totalFunds,
    required this.activeFunds,
    required this.maturityPayoutTotal,
    required this.collectedTotal,
  });

  factory FundsSummary.fromJson(Map<String, dynamic> json) {
    return FundsSummary(
      totalFunds: (json['total_funds'] as num?)?.toInt() ?? 0,
      activeFunds: (json['active_funds'] as num?)?.toInt() ?? 0,
      maturityPayoutTotal: _toDouble(json['maturity_payout_total']),
      collectedTotal: _toDouble(json['collected_total']),
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
