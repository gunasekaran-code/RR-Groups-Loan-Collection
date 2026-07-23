/// Wraps a raw `loans` row (see `Loan extends Model` / `LoanController` on
/// the server) together with the customer/agent names resolved client-side,
/// since the generic rest.php endpoint doesn't join tables.
///
/// ASSUMPTION: the column names below (`principal_amount`, `interest_rate`,
/// `duration_months`, `collection_type`, `outstanding_balance`,
/// `emi_amount`, `processing_fee`, `start_date`, `customer_id`, `agent_id`)
/// are guesses at your `loans` schema — rename them in [fromJson]/[toJson]
/// to match your actual columns.
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
    required this.status,
    this.notes,
    this.customerName = 'Unknown',
    this.agentName = 'Unassigned',
  });

  factory LoanRecord.fromJson(Map<String, dynamic> j) {
    double asDouble(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int asInt(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

    final customerId = (j['customer_id'] ?? j['customerId'])?.toString();
    final agentId = (j['assigned_agent'] ?? j['agent_id'] ?? j['agentId'])?.toString();
    final customerName = (j['customer_name'] ?? j['customerName'] ?? '').toString().trim();
    final agentName = (j['agent_name'] ?? j['agentName'] ?? '').toString().trim();

    return LoanRecord(
      id: j['id'].toString(),
      loanNumber: (j['loan_number'] ?? j['id']).toString(),
      customerId: customerId,
      agentId: agentId,
      principalAmount: asDouble(j['principal_amount']),
      interestRate: asDouble(j['interest_rate']),
      durationUnits: asInt(j['duration_months'] ?? j['duration']),
      collectionType: (j['collection_type'] ?? 'Monthly').toString(),
      startDate: j['start_date']?.toString(),
      outstandingBalance: asDouble(j['outstanding_balance']),
      emiAmount: asDouble(j['emi_amount']),
      processingFee: asDouble(j['processing_fee']),
      status: (j['status'] ?? 'Pending').toString(),
      notes: j['notes']?.toString(),
      customerName: customerName.isNotEmpty ? customerName : 'Unknown',
      agentName: agentName.isNotEmpty ? agentName : 'Unassigned',
    );
  }

  Map<String, dynamic> toJson() => {
        'loan_number': loanNumber,
        if (customerId != null) 'customer_id': customerId,
        if (agentId != null) 'agent_id': agentId,
        'principal_amount': principalAmount,
        'interest_rate': interestRate,
        'duration_months': durationUnits,
        'collection_type': collectionType,
        if (startDate != null) 'start_date': startDate,
        'outstanding_balance': outstandingBalance,
        'emi_amount': emiAmount,
        'processing_fee': processingFee,
        'status': status,
        if (notes != null) 'notes': notes,
      };

  String get formattedAmount => formatRupees(principalAmount);
  String get formattedEmi => formatRupees(emiAmount);
  String get formattedOutstanding => formatRupees(outstandingBalance);

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