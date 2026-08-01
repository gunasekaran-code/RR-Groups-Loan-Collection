enum AgentCollectionStatus { overdue, dueToday, pending, paid }

class AgentCollectionItem {
  final String id;
  final String? scheduleId;
  final String loanId;
  final String? customerId;
  final String customerName;
  final String loanNumber;
  final double dueAmount;
  final DateTime? dueDate;
  final String rawStatus;
  final String? contactPhone;
  final String? agentId;
  final String? agentName;

  const AgentCollectionItem({
    required this.id,
    this.scheduleId,
    required this.loanId,
    this.customerId,
    required this.customerName,
    required this.loanNumber,
    required this.dueAmount,
    this.dueDate,
    required this.rawStatus,
    this.contactPhone,
    this.agentId,
    this.agentName,
  });

  factory AgentCollectionItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic raw) {
      if (raw == null) return 0;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString()) ?? 0;
    }

    final dueAmount = parseDouble(
      json['due_amount'] ?? json['balance'] ?? json['emi_amount'],
    );

    return AgentCollectionItem(
      id: (json['id'] ?? '').toString(),
      scheduleId: json['schedule_id']?.toString(),
      loanId: (json['loan_id'] ?? '').toString(),
      customerId: json['customer_id']?.toString(),
      customerName: (json['customer_name'] ?? '-').toString(),
      loanNumber: (json['loan_number'] ?? '-').toString(),
      dueAmount: dueAmount,
      dueDate: _parseDate(json['due_date']),
      rawStatus: (json['status'] ?? 'pending').toString().toLowerCase(),
      contactPhone: (json['contact_phone'] ?? json['phone'])?.toString(),
      agentId: json['agent_id']?.toString(),
      agentName: json['agent_name']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  String get initials {
    final parts = customerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  bool get isPaid => rawStatus == 'paid' || rawStatus == 'collected';

  AgentCollectionStatus get status {
    if (isPaid) return AgentCollectionStatus.paid;
    if (rawStatus == 'overdue') return AgentCollectionStatus.overdue;
    final due = dueDate;
    if (due != null) {
      final now = DateTime.now();
      final dueOnly = DateTime(due.year, due.month, due.day);
      final today = DateTime(now.year, now.month, now.day);
      if (dueOnly.isBefore(today)) return AgentCollectionStatus.overdue;
      if (dueOnly.isAtSameMomentAs(today))
        return AgentCollectionStatus.dueToday;
    }
    return AgentCollectionStatus.pending;
  }

  String get statusLabel {
    switch (status) {
      case AgentCollectionStatus.overdue:
        return 'Overdue';
      case AgentCollectionStatus.dueToday:
        return 'Due Today';
      case AgentCollectionStatus.paid:
        return 'Collected';
      case AgentCollectionStatus.pending:
        return 'Active';
    }
  }

  String get formattedDueAmount => _formatAmount(dueAmount);

  String get formattedDueDate {
    final d = dueDate;
    if (d == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  static String _formatAmount(double value) {
    final intValue = value.round();
    final s = intValue.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0) buf.write(',');
    }
    return '₹$buf';
  }
}
