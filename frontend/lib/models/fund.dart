// models/fund.dart

enum FundStatus { active, matured, settled }

extension FundStatusX on FundStatus {
  String get label {
    switch (this) {
      case FundStatus.active:
        return 'active';
      case FundStatus.matured:
        return 'matured';
      case FundStatus.settled:
        return 'settled';
    }
  }

  static FundStatus fromString(String? v) {
    switch (v) {
      case 'matured':
        return FundStatus.matured;
      case 'settled':
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
  final String? method;
  final bool paid;

  FundEntry({
    required this.week,
    required this.date,
    required this.amount,
    this.method,
    required this.paid,
  });

  factory FundEntry.fromJson(Map<String, dynamic> json) {
    return FundEntry(
      week: (json['week'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['due_date']?.toString() ?? '') ??
          DateTime.now(),
      amount: _toDouble(json['amount']),
      method: json['method']?.toString(),
      paid: (json['paid'] == true || json['paid'] == 1 || json['paid'] == '1'),
    );
  }
}

class Fund {
  final String id;
  final String code;
  final String customerId;
  final String customerName;
  final FundStatus status;
  final double weeklyAmount;
  final int numberOfWeeks;
  final double maturityBonus;
  final DateTime startDate;
  final DateTime maturityDate;
  final double depositedAmount;
  final int entriesPaid;

  Fund({
    required this.id,
    required this.code,
    required this.customerId,
    required this.customerName,
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

  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      id: json['id'].toString(),
      code: json['code']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Unknown Customer',
      status: FundStatusX.fromString(json['status']?.toString()),
      weeklyAmount: _toDouble(json['weekly_amount']),
      numberOfWeeks: (json['number_of_weeks'] as num?)?.toInt() ?? 0,
      maturityBonus: _toDouble(json['maturity_bonus']),
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ??
          DateTime.now(),
      maturityDate:
          DateTime.tryParse(json['maturity_date']?.toString() ?? '') ??
              DateTime.now(),
      depositedAmount: _toDouble(json['deposited_amount']),
      entriesPaid: (json['entries_paid'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'customer_id': customerId,
      'weekly_amount': weeklyAmount,
      'number_of_weeks': numberOfWeeks,
      'maturity_bonus': maturityBonus,
      'start_date':
          '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
    };
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