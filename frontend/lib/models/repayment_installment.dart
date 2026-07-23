// Maps 1:1 to the `repayment_schedule` MySQL table.
class RepaymentInstallment {
  final String id;
  final String loanId;
  final int installmentNo;
  final DateTime? dueDate;
  final double emiAmount;
  final double paidAmount;
  final double balance;
  final String status; // 'paid' | 'partial' | 'overdue' | 'pending'
  final DateTime? createdAt;

  RepaymentInstallment({
    required this.id,
    required this.loanId,
    required this.installmentNo,
    required this.dueDate,
    required this.emiAmount,
    required this.paidAmount,
    required this.balance,
    required this.status,
    this.createdAt,
  });

  factory RepaymentInstallment.fromJson(Map<String, dynamic> json) {
    double _num(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    DateTime? _date(dynamic v) {
      if (v == null || v.toString().isEmpty) return null;
      return DateTime.tryParse(v.toString());
    }

    return RepaymentInstallment(
      id: json['id']?.toString() ?? '',
      loanId: json['loan_id']?.toString() ?? '',
      installmentNo: int.tryParse(json['installment_no']?.toString() ?? '') ?? 0,
      dueDate: _date(json['due_date']),
      emiAmount: _num(json['emi_amount']),
      paidAmount: _num(json['paid_amount']),
      balance: _num(json['balance']),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: _date(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'loan_id': loanId,
        'installment_no': installmentNo,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'emi_amount': emiAmount,
        'paid_amount': paidAmount,
        'balance': balance,
        'status': status,
      };

  // UI helpers -------------------------------------------------------

  /// Capitalised label for StatusBadge, e.g. 'paid' -> 'Paid'.
  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partial';
      case 'overdue':
        return 'Overdue';
      default:
        return 'Pending';
    }
  }

  String _fmtCurrency(double v) {
    final rounded = v.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    // Indian digit grouping: last 3 digits, then groups of 2.
    final isNeg = str.startsWith('-');
    final digits = isNeg ? str.substring(1) : str;
    if (digits.length <= 3) {
      buffer.write(digits);
    } else {
      final last3 = digits.substring(digits.length - 3);
      var rest = digits.substring(0, digits.length - 3);
      final parts = <String>[];
      while (rest.length > 2) {
        parts.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) parts.insert(0, rest);
      buffer.write('${parts.join(',')},$last3');
    }
    return '${isNeg ? '-' : ''}\u20B9${buffer.toString()}';
  }

  String get amountDisplay => _fmtCurrency(emiAmount);
  String get paidDisplay => _fmtCurrency(paidAmount);
  String get balanceDisplay => _fmtCurrency(balance);

  String get dueDateDisplay {
    if (dueDate == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dueDate!.day.toString().padLeft(2, '0')} '
        '${months[dueDate!.month - 1]} ${dueDate!.year}';
  }
}