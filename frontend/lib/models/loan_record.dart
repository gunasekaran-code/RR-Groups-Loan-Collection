class LoanRecord {
  final String id;
  final String loanNumber;
  final String? customerId;
  final String? agentId;
  final double principalAmount;
  final double interestRate; // meaning depends on collectionType
  final int durationUnits; // months / weeks / days depending on collectionType
  final String collectionType; // 'Monthly' | 'Weekly' | 'Daily'
  final String? startDate;
  final double outstandingBalance;
  final double emiAmount;
  final double processingFee;
  final bool penaltyEnabled;
  final double penaltyRatePerDay;
  final double penaltyPerWeek;
  final double penaltyAmount;
  final String status; // 'Active' | 'Overdue' | 'Closed' | 'Pending'
  final String? notes;

  String customerName;
  String agentName;

  LoanRecord({
    required this.id,
    required this.loanNumber,
    this.customerId,
    this.agentId,
    required this.principalAmount,
    required this.interestRate,
    required this.durationUnits,
    required this.collectionType,
    this.startDate,
    required this.outstandingBalance,
    required this.emiAmount,
    required this.processingFee,
    this.penaltyEnabled = false,
    this.penaltyRatePerDay = 0,
    this.penaltyPerWeek = 0,
    this.penaltyAmount = 0,
    required this.status,
    this.notes,
    this.customerName = 'Unknown',
    this.agentName = 'Unassigned',
  });

  factory LoanRecord.fromJson(Map<String, dynamic> j) {
    double asDouble(dynamic v) => v == null
        ? 0.0
        : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int asInt(dynamic v) => v == null
        ? 0
        : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
    bool asBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v?.toString().trim().toLowerCase();
      return s == '1' || s == 'true' || s == 'yes';
    }

    final customerId = (j['customer_id'] ?? j['customerId'])?.toString();
    final agentId =
        (j['assigned_agent'] ?? j['agent_id'] ?? j['agentId'])?.toString();
    final customerName =
        (j['customer_name'] ?? j['customerName'] ?? '').toString().trim();
    final agentName =
        (j['agent_name'] ?? j['agentName'] ?? '').toString().trim();

    final rawCollectionType =
        (j['loan_type'] ?? j['collection_type'] ?? 'monthly').toString().trim();
    final collectionType = rawCollectionType.isEmpty
        ? 'Monthly'
        : '${rawCollectionType[0].toUpperCase()}${rawCollectionType.substring(1).toLowerCase()}';

    final rawStatus = (j['status'] ?? 'pending').toString().trim();
    final status = rawStatus.isEmpty
        ? 'Pending'
        : '${rawStatus[0].toUpperCase()}${rawStatus.substring(1).toLowerCase()}';

    return LoanRecord(
      id: j['id'].toString(),
      loanNumber: (j['loan_number'] ?? j['loanNumber'] ?? j['id']).toString(),
      customerId: customerId,
      agentId: agentId,
      principalAmount: asDouble(j['loan_amount'] ?? j['principal_amount']),
      interestRate: asDouble(j['interest_percentage'] ?? j['interest_rate']),
      durationUnits:
          asInt(j['loan_duration'] ?? j['duration_months'] ?? j['duration']),
      collectionType: collectionType,
      startDate: j['start_date']?.toString(),
      outstandingBalance: asDouble(j['outstanding_balance']),
      emiAmount: asDouble(j['emi'] ?? j['emi_amount']),
      processingFee: asDouble(j['processing_fee']),
      penaltyEnabled: asBool(j['penalty_enabled']),
      penaltyRatePerDay: asDouble(j['penalty_rate_per_day']),
      penaltyPerWeek: asDouble(j['penalty_per_week']),
      penaltyAmount: asDouble(j['penalty_amount']),
      status: status,
      notes: j['notes']?.toString(),
      customerName: customerName.isNotEmpty ? customerName : 'Unknown',
      agentName: agentName.isNotEmpty ? agentName : 'Unassigned',
    );
  }

  Map<String, dynamic> toJson() => {
        'loan_number': loanNumber,
        if (customerId != null) 'customer_id': customerId,
        if (customerName.isNotEmpty) 'customer_name': customerName,
        if (agentId != null) 'assigned_agent': agentId,
        if (agentName.isNotEmpty) 'agent_name': agentName,
        'loan_amount': principalAmount,
        'interest_percentage': interestRate,
        'loan_duration': durationUnits,
        'loan_type': collectionType.toLowerCase(),
        if (startDate != null) 'start_date': startDate,
        'outstanding_balance': outstandingBalance,
        'emi': emiAmount,
        'processing_fee': processingFee,
        'penalty_enabled': penaltyEnabled,
        'penalty_rate_per_day': penaltyRatePerDay,
        'penalty_per_week': penaltyPerWeek,
        'penalty_amount': penaltyAmount,
        'status': status.toLowerCase(),
        if (notes != null) 'notes': notes,
      };

  LoanRecord copyWith({
    String? status,
    double? outstandingBalance,
    double? penaltyAmount,
    String? customerName,
    String? agentName,
  }) => LoanRecord(
        id: id,
        loanNumber: loanNumber,
        customerId: customerId,
        agentId: agentId,
        principalAmount: principalAmount,
        interestRate: interestRate,
        durationUnits: durationUnits,
        collectionType: collectionType,
        startDate: startDate,
        outstandingBalance: outstandingBalance ?? this.outstandingBalance,
        emiAmount: emiAmount,
        processingFee: processingFee,
        penaltyEnabled: penaltyEnabled,
        penaltyRatePerDay: penaltyRatePerDay,
        penaltyPerWeek: penaltyPerWeek,
        penaltyAmount: penaltyAmount ?? this.penaltyAmount,
        status: status ?? this.status,
        notes: notes,
        customerName: customerName ?? this.customerName,
        agentName: agentName ?? this.agentName,
      );

  String get formattedAmount => formatRupees(principalAmount);
  String get formattedEmi => formatRupees(emiAmount);
  String get formattedOutstanding => formatRupees(outstandingBalance);
  String get formattedPenalty => formatRupees(penaltyAmount);
  String get formattedOutstandingWithPenalty =>
      formatRupees(outstandingBalance + penaltyAmount);

  /// Indian-style grouping: 1,00,000 instead of 100,000.
  static String formatRupees(double v) {
    final isNeg = v < 0;
    final s = v.abs().toStringAsFixed(0);
    String grouped;
    if (s.length <= 3) {
      grouped = s;
    } else {
      final tail = s.substring(s.length - 3);
      var head = s.substring(0, s.length - 3);
      final groups = <String>[];
      while (head.length > 2) {
        groups.insert(0, head.substring(head.length - 2));
        head = head.substring(0, head.length - 2);
      }
      if (head.isNotEmpty) groups.insert(0, head);
      grouped = '${groups.join(',')},$tail';
    }
    return '${isNeg ? '-' : ''}₹$grouped';
  }
}
