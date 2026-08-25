enum AgentCollectionStatus { overdue, dueToday, pending, paid }

class AgentCollectionItem {
  final String id;
  final String? scheduleId;
  final String loanId;
  final String loanType;
  final String loanName;
  final String? customerId;
  final String customerName;
  final String loanNumber;
  final double dueAmount;
  final double installmentAmount;
  final double penaltyAmount;
  final DateTime? dueDate;
  final String rawStatus;
  final String? contactPhone;
  final String? agentId;
  final String? agentName;

  // --- Added for grouped customer view / map integration ---
  final String? address;
  final double? latitude;
  final double? longitude;
  // Full outstanding balance on the loan (may differ from the amount due
  // for the current installment). Falls back to [dueAmount] when the
  // backend doesn't provide it.
  final double? outstandingBalance;

  const AgentCollectionItem({
    required this.id,
    this.scheduleId,
    required this.loanId,
    required this.loanType,
    required this.loanName,
    this.customerId,
    required this.customerName,
    required this.loanNumber,
    required this.dueAmount,
    this.installmentAmount = 0,
    this.penaltyAmount = 0,
    this.dueDate,
    required this.rawStatus,
    this.contactPhone,
    this.agentId,
    this.agentName,
    this.address,
    this.latitude,
    this.longitude,
    this.outstandingBalance,
  });

  factory AgentCollectionItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic raw) {
      if (raw == null) return 0;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString()) ?? 0;
    }

    double? parseDoubleOrNull(dynamic raw) {
      if (raw == null) return null;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString());
    }

    final dueAmount = parseDouble(
      json['due_amount'] ?? json['balance'] ?? json['emi_amount'],
    );

    return AgentCollectionItem(
      id: (json['id'] ?? '').toString(),
      scheduleId: json['schedule_id']?.toString(),
      loanId: (json['loan_id'] ?? '').toString(),
      loanType: (json['loan_type'] ?? json['collection_type'] ?? 'Monthly')
          .toString(),
      loanName: (json['loan_name'] ??
              json['scheme_name'] ??
              json['collection_name'] ??
              json['loan_number'] ??
              '-')
          .toString(),
      customerId: json['customer_id']?.toString(),
      customerName: (json['customer_name'] ?? '-').toString(),
      loanNumber: (json['loan_number'] ?? '-').toString(),
      dueAmount: dueAmount,
      installmentAmount: parseDouble(json['emi_amount']),
      penaltyAmount: parseDouble(json['penalty_amount']),
      dueDate: _parseDate(json['due_date']),
      rawStatus: (json['status'] ?? 'pending').toString().toLowerCase(),
      contactPhone: (json['contact_phone'] ?? json['phone'])?.toString(),
      agentId: json['agent_id']?.toString(),
      agentName: json['agent_name']?.toString(),
      address: (json['address'] ??
              json['customer_address'] ??
              json['location_address'])
          ?.toString(),
      latitude: parseDoubleOrNull(json['latitude'] ?? json['lat']),
      longitude:
          parseDoubleOrNull(json['longitude'] ?? json['lng'] ?? json['lon']),
      outstandingBalance: parseDoubleOrNull(
        json['outstanding_balance'] ?? json['loan_balance'],
      ),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  String get initials => _initialsFor(customerName);

  String get displayLoanType {
    final value = loanType.trim();
    if (value.isEmpty) return 'Loan';
    final lower = value.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  String get displayLoanName {
    final value = loanName.trim();
    if (value.isNotEmpty && value != '-') return value;
    return loanNumber;
  }

  String get uniqueName =>
      '$customerName • $displayLoanType • $displayLoanName';

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
      if (dueOnly.isAtSameMomentAs(today)) {
        return AgentCollectionStatus.dueToday;
      }
    }
    return AgentCollectionStatus.pending;
  }

  String get statusLabel => _labelFor(status);

  String get formattedDueAmount => formatAmount(dueAmount);

  String get formattedPenaltyAmount => formatAmount(penaltyAmount);

  String get formattedTotalDue => formatAmount(dueAmount + penaltyAmount);

  String get formattedDueDate => formatDate(dueDate);

  static String formatDate(DateTime? d) {
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

  static String formatAmount(double value) {
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

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

String _labelFor(AgentCollectionStatus status) {
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

/// Groups every unpaid [AgentCollectionItem] belonging to the same customer
/// so the collections list can show one card per customer (per your unique
/// User/Loan ID) instead of one card per installment.
class AgentCustomerGroup {
  final String customerId;
  final String customerName;
  final String loanId;
  final String loanType;
  final String loanName;
  final String? contactPhone;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<AgentCollectionItem> items;

  const AgentCustomerGroup({
    required this.customerId,
    required this.customerName,
    required this.loanId,
    required this.loanType,
    required this.loanName,
    required this.items,
    this.contactPhone,
    this.address,
    this.latitude,
    this.longitude,
  });

  /// Distinct loan numbers this customer has due installments for.
  List<String> get loanNumbers =>
      items.map((e) => e.loanNumber).toSet().toList();

  String get displayLoanType {
    final value = loanType.trim();
    if (value.isEmpty) return 'Loan';
    final lower = value.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  String get displayLoanName {
    final value = loanName.trim();
    if (value.isNotEmpty && value != '-') return value;
    return loanNumbers.isNotEmpty ? loanNumbers.first : '-';
  }

  String get uniqueName =>
      '$customerName • $displayLoanType • $displayLoanName';

  /// Distinct loan ids (used when a collection needs to be split across
  /// more than one loan for the same customer).
  List<String> get loanIds => items.map((e) => e.loanId).toSet().toList();

  /// Sum of every currently-payable installment for this customer — this is
  /// what gets prefilled into the Collect form.
  double get totalDue => items.fold(0.0, (sum, i) => sum + i.dueAmount);

  double get totalPenalty =>
      items.fold(0.0, (sum, i) => sum + i.penaltyAmount);

  double get totalDueWithPenalty => totalDue + totalPenalty;

  /// Sum of the full outstanding loan balance(s), de-duplicated per loan.
  /// Falls back to [totalDue] if the backend doesn't send a balance figure.
  double get totalOutstanding {
    final seenLoans = <String>{};
    double sum = 0;
    bool any = false;
    for (final i in items) {
      if (i.outstandingBalance == null) continue;
      if (!seenLoans.add(i.loanId)) continue;
      any = true;
      sum += i.outstandingBalance!;
    }
    return any ? sum : totalDue;
  }

  DateTime? get nearestDueDate {
    final dates = items.map((e) => e.dueDate).whereType<DateTime>().toList();
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  bool get hasOverdue =>
      items.any((i) => i.status == AgentCollectionStatus.overdue);
  bool get hasDueToday =>
      items.any((i) => i.status == AgentCollectionStatus.dueToday);

  AgentCollectionStatus get status {
    if (hasOverdue) return AgentCollectionStatus.overdue;
    if (hasDueToday) return AgentCollectionStatus.dueToday;
    return AgentCollectionStatus.pending;
  }

  String get statusLabel => _labelFor(status);

  String get initials => _initialsFor(customerName);

  bool get hasLocation =>
      (latitude != null && longitude != null) ||
      (address != null && address!.trim().isNotEmpty);

  /// Simple case-insensitive filter across the customer's name, unique
  /// customer id, and every loan number/id they have due.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (customerName.toLowerCase().contains(q)) return true;
    if (customerId.toLowerCase().contains(q)) return true;
    if (loanId.toLowerCase().contains(q)) return true;
    if (loanType.toLowerCase().contains(q)) return true;
    if (loanName.toLowerCase().contains(q)) return true;
    return items.any((i) =>
        i.loanNumber.toLowerCase().contains(q) ||
        i.loanId.toLowerCase().contains(q) ||
        i.loanType.toLowerCase().contains(q) ||
        i.loanName.toLowerCase().contains(q));
  }

  static List<AgentCustomerGroup> groupItems(List<AgentCollectionItem> items) {
    final map = <String, List<AgentCollectionItem>>{};
    for (final item in items) {
      final customerKey =
          (item.customerId != null && item.customerId!.isNotEmpty)
              ? item.customerId!
              : item.customerName;
      final loanKey = item.loanId.isNotEmpty ? item.loanId : item.loanNumber;
      final key = '$customerKey|$loanKey';
      map.putIfAbsent(key, () => []).add(item);
    }

    final groups = map.entries.map((entry) {
      final groupItems = [...entry.value]..sort((a, b) {
          final aDate = a.dueDate ?? DateTime(2100);
          final bDate = b.dueDate ?? DateTime(2100);
          return aDate.compareTo(bDate);
        });
      final first = groupItems.first;
      final withAddress = groupItems.firstWhere(
        (i) => i.address != null && i.address!.trim().isNotEmpty,
        orElse: () => first,
      );
      final withPhone = groupItems.firstWhere(
        (i) => i.contactPhone != null && i.contactPhone!.trim().isNotEmpty,
        orElse: () => first,
      );
      return AgentCustomerGroup(
        customerId: first.customerId ?? first.customerName,
        customerName: first.customerName,
        loanId: first.loanId,
        loanType: first.loanType,
        loanName: first.loanName,
        items: groupItems,
        contactPhone: withPhone.contactPhone,
        address: withAddress.address,
        latitude: withAddress.latitude,
        longitude: withAddress.longitude,
      );
    }).toList();

    groups.sort((a, b) {
      int rank(AgentCollectionStatus s) {
        if (s == AgentCollectionStatus.overdue) return 0;
        if (s == AgentCollectionStatus.dueToday) return 1;
        return 2;
      }

      final rankCompare = rank(a.status).compareTo(rank(b.status));
      if (rankCompare != 0) return rankCompare;
      final aDate = a.nearestDueDate ?? DateTime(2100);
      final bDate = b.nearestDueDate ?? DateTime(2100);
      return aDate.compareTo(bDate);
    });

    return groups;
  }
}
