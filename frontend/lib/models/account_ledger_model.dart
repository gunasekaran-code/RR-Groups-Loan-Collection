import 'package:intl/intl.dart';

class LedgerEntryType {
  static const cashIn = 'cash_in';
  static const capitalInjection = 'capital';
  static const officeExpense = 'expense';
  static const cashOut = 'cash_out';

  static const moneyLent = 'lent_out';
  static const activeDebtAdjustment = 'lent_active';
  static const overdueDebtAdjustment = 'lent_overdue';
  static const debtRecovered = 'lent_collected';

  static const cashInHandTypes = {
    cashIn,
    capitalInjection,
    officeExpense,
    cashOut,
  };

  static const outstandingLentTypes = {
    moneyLent,
    activeDebtAdjustment,
    overdueDebtAdjustment,
    debtRecovered,
  };

  static const negativeTypes = {
    officeExpense,
    cashOut,
    moneyLent,
    debtRecovered, // money recovered leaves "outstanding", handled per-section
  };

  static const Map<String, String> labels = {
    cashIn: 'Cash In',
    capitalInjection: 'Capital Injection',
    officeExpense: 'Office Expense',
    cashOut: 'Cash Out',
    moneyLent: 'Money Lent',
    activeDebtAdjustment: 'Active Debt Adjustment',
    overdueDebtAdjustment: 'Overdue Debt Adjustment',
    debtRecovered: 'Debt Recovered',
  };

  static String labelFor(String type) => labels[type] ?? type;

  static bool isCashInHand(String type) => cashInHandTypes.contains(type);

  static String normalize(String type) {
    switch (type) {
      case 'capital_injection':
        return capitalInjection;
      case 'office_expense':
        return officeExpense;
      case 'money_lent':
        return moneyLent;
      case 'active_debt_adjustment':
        return activeDebtAdjustment;
      case 'overdue_debt_adjustment':
        return overdueDebtAdjustment;
      case 'debt_recovered':
        return debtRecovered;
      default:
        return type;
    }
  }
}

class AccountLedgerEntry {
  final String id;
  final String entryType;
  final String title;
  final double amount;
  final String category;
  final DateTime? entryDate;
  final String? notes;
  final DateTime? createdAt;

  const AccountLedgerEntry({
    required this.id,
    required this.entryType,
    required this.title,
    required this.amount,
    this.category = 'General',
    this.entryDate,
    this.notes,
    this.createdAt,
  });

  String get section => LedgerEntryType.isCashInHand(entryType)
      ? 'Cash In Hand'
      : 'Outstanding Lent';
  bool get isPositive => !LedgerEntryType.negativeTypes.contains(entryType);
  String get typeLabel => LedgerEntryType.labelFor(entryType);
  String get displayAmount {
    final formatted = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
    return '${isPositive ? '+' : '-'} $formatted';
  }
  String get displayDate =>
      entryDate == null ? '' : DateFormat('d MMM yyyy').format(entryDate!);

  factory AccountLedgerEntry.fromJson(Map<String, dynamic> json) {
    return AccountLedgerEntry(
      id: json['id']?.toString() ?? '',
      entryType: LedgerEntryType.normalize(
        json['entry_type']?.toString() ?? LedgerEntryType.cashIn,
      ),
      title: json['title']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      category: json['category']?.toString() ?? 'General',
      entryDate: _toDate(json['entry_date']),
      notes: json['notes']?.toString(),
      createdAt: _toDate(json['created_at']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'entry_type': entryType,
      'title': title,
      'amount': amount,
      'category': category,
      'entry_date': entryDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(entryDate!),
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'id': id,
      ...toCreateJson(),
    };
  }

  AccountLedgerEntry copyWith({
    String? entryType,
    String? title,
    double? amount,
    String? category,
    DateTime? entryDate,
    String? notes,
  }) {
    return AccountLedgerEntry(
      id: id,
      entryType: entryType ?? this.entryType,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      entryDate: entryDate ?? this.entryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}


class AccountLedgerSummary {
  const AccountLedgerSummary({
    required this.loanCollections,
    required this.fundDeposits,
    required this.chitCollected,
    required this.customCashIn,
    required this.customCashOut,
    required this.cashInHand,
    required this.totalLoanOutstanding,
    required this.chitPendingAmount,
    required this.fundPendingAmount,
    required this.customLentNet,
    required this.outstandingMoneyLent,
    required this.netBalance,
  });

  final double loanCollections;
  final double fundDeposits;
  final double chitCollected;
  final double customCashIn;
  final double customCashOut;
  final double cashInHand;
  final double totalLoanOutstanding;
  final double chitPendingAmount;
  final double fundPendingAmount;
  final double customLentNet;
  final double outstandingMoneyLent;
  final double netBalance;

  double get customCashNet => customCashIn - customCashOut;

  factory AccountLedgerSummary.fromJson(Map<String, dynamic> json) {
    return AccountLedgerSummary(
      loanCollections: _value(json, 'loanCollections'),
      fundDeposits: _value(json, 'fundDeposits'),
      chitCollected: _value(json, 'chitCollected'),
      customCashIn: _value(json, 'customCashIn'),
      customCashOut: _value(json, 'customCashOut'),
      cashInHand: _value(json, 'cashInHand'),
      totalLoanOutstanding: _value(json, 'totalLoanOutstanding'),
      chitPendingAmount: _value(json, 'chitPendingAmount'),
      fundPendingAmount: _value(json, 'fundPendingAmount'),
      customLentNet: _value(json, 'customLentNet'),
      outstandingMoneyLent: _value(json, 'outstandingMoneyLent'),
      netBalance: _value(json, 'netBalance'),
    );
  }

  static double _value(Map<String, dynamic> json, String key) {
    // Accept snake_case too, which keeps the app tolerant of proxy/API
    // serializers that convert the PHP response field names.
    final snakeKey = key.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
    final value = json[key] ?? json[snakeKey];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
