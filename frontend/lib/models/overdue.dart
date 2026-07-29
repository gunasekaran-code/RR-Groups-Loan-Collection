/// Overdue account — a derived/computed record from GET /backend/overdue.php.
/// There is no overdue_id; loan_id is the natural key since overdue accounts
/// are 1:1 with loans that have unpaid past-due installments.
class OverdueAccount {
  OverdueAccount({
    required this.loanId,
    required this.loanNumber,
    required this.customerId,
    required this.customerName,
    required this.loanAmount,
    required this.emi,
    required this.outstandingBalance,
    required this.status,
    required this.overdueInstallments,
    required this.overdueAmount,
    required this.earliestDueDate,
    required this.daysOverdue,
    this.agentName,
    this.assignedAgent,
    this.mobile,
    this.address,
    this.followUpNote,
    this.followUpDate,
  });

  final int loanId;
  final String loanNumber;
  final int? customerId;
  final String customerName;
  final double loanAmount;
  final double emi;
  final double outstandingBalance;
  final String status;
  final int overdueInstallments;
  final double overdueAmount;
  final DateTime? earliestDueDate;
  final int daysOverdue;
  final String? agentName;
  final String? assignedAgent;
  final String? mobile;
  final String? address;

  // NOTE: not persisted by the backend (no columns/endpoint for these yet).
  // Kept as local, in-memory state only. See OverdueApiService docs below.
  String? followUpNote;
  DateTime? followUpDate;

  bool get isCritical => daysOverdue > 30;

  String get phone => mobile ?? '';

  String get initials {
    final parts = customerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory OverdueAccount.fromJson(Map<String, dynamic> json) {
    return OverdueAccount(
      loanId: _asInt(json['loan_id']),
      loanNumber: json['loan_number']?.toString() ?? '',
      customerId: json['customer_id'] == null ? null : _asInt(json['customer_id']),
      customerName: json['customer_name']?.toString() ?? 'Unknown',
      loanAmount: _asDouble(json['loan_amount']),
      emi: _asDouble(json['emi']),
      outstandingBalance: _asDouble(json['outstanding_balance']),
      status: json['status']?.toString() ?? '',
      overdueInstallments: _asInt(json['overdue_installments']),
      overdueAmount: _asDouble(json['overdue_amount']),
      earliestDueDate: _asDate(json['earliest_due_date']),
      daysOverdue: _asInt(json['days_overdue']),
      agentName: json['agent_name']?.toString(),
      assignedAgent: json['assigned_agent']?.toString(),
      mobile: json['mobile']?.toString(),
      address: json['address']?.toString(),
    );
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}