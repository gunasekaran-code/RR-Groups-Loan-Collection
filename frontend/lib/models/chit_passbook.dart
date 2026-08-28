enum ChitDrawStatus { paid, pending }

class ChitDraw {
  ChitDraw({
    required this.drawNumber,
    required this.scheduledDate,
    required this.payableContribution,
    required this.dividendPoolValue,
    required this.status,
    this.amountPaid = 0,
  });

  final int drawNumber;
  final DateTime scheduledDate;
  final double payableContribution;
  final double dividendPoolValue;
  final ChitDrawStatus status;
  final double amountPaid;

  /// Remaining amount still owed against this specific draw.
  double get amountDue =>
      (payableContribution - amountPaid).clamp(0, payableContribution);

  factory ChitDraw.fromJson(Map<String, dynamic> json) {
    return ChitDraw(
      drawNumber: int.tryParse('${json['draw_number']}') ?? 0,
      scheduledDate:
          DateTime.tryParse('${json['scheduled_date']}') ?? DateTime.now(),
      payableContribution:
          double.tryParse('${json['payable_contribution']}') ?? 0,
      dividendPoolValue:
          double.tryParse('${json['dividend_pool_value']}') ?? 0,
      status: '${json['payment_status']}'.toLowerCase() == 'paid'
          ? ChitDrawStatus.paid
          : ChitDrawStatus.pending,
      amountPaid: double.tryParse('${json['amount_paid']}') ?? 0,
    );
  }
}

class ChitPaymentReceipt {
  ChitPaymentReceipt({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
  });

  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;

  factory ChitPaymentReceipt.fromJson(Map<String, dynamic> json) {
    return ChitPaymentReceipt(
      id: '${json['id']}',
      title: json['title']?.toString() ??
          'Chit Contribution: ${json['customer_name'] ?? ''}'.trim(),
      subtitle: json['subtitle']?.toString() ??
          '${json['payment_method'] ?? json['payment_mode'] ?? 'Cash'}'
              ' · ${json['receipt_number'] ?? 'Receipt'}',
      amount: double.tryParse(
              '${json['amount'] ?? json['collection_amount'] ?? 0}') ??
          0,
      date: DateTime.tryParse(
              '${json['paid_at'] ?? json['collection_date'] ?? json['created_at']}') ??
          DateTime.now(),
    );
  }
}

class ChitPassbookData {
  ChitPassbookData({
    required this.draws,
    required this.receipts,
    this.totalDraws,
  });

  final List<ChitDraw> draws;
  final List<ChitPaymentReceipt> receipts;
  final int? totalDraws;

  /// First draw that hasn't been fully paid yet.
  ChitDraw? get nextDueDraw {
    for (final d in draws) {
      if (d.status == ChitDrawStatus.pending) return d;
    }
    return null;
  }

  /// Derives a human label ("Every 10 Days" / "Monthly") from the gap
  /// between the first two scheduled draws, since the schedule frequency
  /// itself isn't stored on ChitGroup.
  String get drawScheduleLabel {
    if (draws.length < 2) return 'Monthly';
    final diff =
        draws[1].scheduledDate.difference(draws[0].scheduledDate).inDays;
    if (diff <= 0) return 'Monthly';
    if (diff >= 28 && diff % 30 == 0) {
      final months = diff ~/ 30;
      return months <= 1 ? 'Monthly' : 'Every $months Months';
    }
    return 'Every $diff Days';
  }

  factory ChitPassbookData.fromJson(Map<String, dynamic> json) {
    final drawsJson = (json['draws'] as List? ?? const []);
    final receiptsJson = (json['receipts'] as List? ?? const []);
    return ChitPassbookData(
      draws: drawsJson
          .map((e) => ChitDraw.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      receipts: receiptsJson
          .map((e) =>
              ChitPaymentReceipt.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalDraws: int.tryParse('${json['total_draws'] ?? ''}'),
    );
  }
}