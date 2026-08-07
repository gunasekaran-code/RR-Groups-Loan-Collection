/// Model for a single payment/receipt record, parsed from the `collections`
/// table (same table AgentCollectionItem reads from — once an agent collects
/// a due installment, that row gets a receipt_number + payment_mode +
/// collected_date and its status flips to paid/collected).
///
/// NOTE: field names below are best-guess based on your existing
/// AgentCollectionItem model + the columns visible in your screenshot.
/// If your actual `collections` table uses different JSON keys, just update
/// the `fromJson` factory below — everything else stays the same.
class PaymentHistoryItem {
  final String id;
  final String? receiptNumber;
  final String loanId;
  final String loanNumber;
  final String? customerId;
  final String customerName;
  final double amount;
  final String? paymentMode; // e.g. Cash, UPI, Card
  final DateTime? collectedDate;
  final String? agentId;
  final String? agentName; // "Collected By"
  final String rawStatus;
  final String? proofImageUrl;

  const PaymentHistoryItem({
    required this.id,
    this.receiptNumber,
    required this.loanId,
    required this.loanNumber,
    this.customerId,
    required this.customerName,
    required this.amount,
    this.paymentMode,
    this.collectedDate,
    this.agentId,
    this.agentName,
    required this.rawStatus,
    this.proofImageUrl,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic raw) {
      if (raw == null) return 0;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString()) ?? 0;
    }

    final amount = parseDouble(
      json['collection_amount'] ??
          json['amount'] ??
          json['paid_amount'] ??
          json['due_amount'],
    );

    return PaymentHistoryItem(
      id: (json['id'] ?? '').toString(),
      receiptNumber: (json['receipt_number'] ?? json['receipt_no'])
          ?.toString(),
      loanId: (json['loan_id'] ?? '').toString(),
      loanNumber: (json['loan_number'] ?? '-').toString(),
      customerId: json['customer_id']?.toString(),
      customerName: (json['customer_name'] ?? '-').toString(),
      amount: amount,
      paymentMode:
          (json['payment_method'] ?? json['payment_mode'] ?? json['mode'])
              ?.toString(),
      collectedDate: _parseDate(
        json['collection_date'] ??
            json['collected_date'] ??
            json['paid_date'] ??
            json['created_at'],
      ),
      agentId: json['agent_id']?.toString(),
      agentName: json['agent_name']?.toString(),
      // The `collections` table has no status column — every row here is
      // already a completed collection, so default to 'paid' unless a
      // status field is ever added server-side.
      rawStatus: (json['status'] ?? 'paid').toString().toLowerCase(),
      proofImageUrl:
          (json['proof_url'] ?? json['proof_image'] ?? json['payment_proof'])
              ?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  /// Only records that represent an actual completed payment.
  bool get isPaidRecord => rawStatus == 'paid' || rawStatus == 'collected';

  String get statusLabel {
    switch (rawStatus) {
      case 'paid':
      case 'collected':
        return 'Paid';
      case 'overdue':
        return 'Overdue';
      default:
        return 'Pending';
    }
  }

  String get displayReceipt => receiptNumber ?? 'RCT-$id';

  String get formattedAmount => _formatAmount(amount);

  String get formattedDate {
    final d = collectedDate;
    if (d == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  String get displayMode => paymentMode ?? '-';

  String get displayCollectedBy => agentName ?? '-';

  static String formatAmount(double value) => _formatAmount(value);

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