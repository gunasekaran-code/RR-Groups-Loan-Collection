import 'chit_group.dart';
import 'chit_member.dart';

enum ChitDrawStatus { paid, partial, overdue, pending }

ChitDrawStatus _drawStatusFromString(dynamic v) {
  switch ('$v'.toLowerCase()) {
    case 'paid':
      return ChitDrawStatus.paid;
    case 'partial':
      return ChitDrawStatus.partial;
    case 'overdue':
      return ChitDrawStatus.overdue;
    default:
      return ChitDrawStatus.pending;
  }
}

class ChitDraw {
  ChitDraw({
    required this.drawNumber,
    required this.scheduledDate,
    required this.payableContribution,
    required this.dividendPoolValue,
    required this.status,
    this.amountPaid = 0,
    this.balance = 0,
    this.paidDate,
  });

  final int drawNumber;
  final DateTime scheduledDate;
  final double payableContribution;
  final double dividendPoolValue;
  final ChitDrawStatus status;
  final double amountPaid;
  final double balance;
  final DateTime? paidDate;

  /// Remaining amount still owed against this specific draw — stored on the
  /// backend passbook row rather than recomputed here, so it always matches
  /// what the office actually recorded.
  double get amountDue => balance;

  /// This is the row a customer or agent is asked to pay next: anything not
  /// yet fully settled, whichever of partial / overdue / pending it is.
  bool get isSettled => status == ChitDrawStatus.paid;

  factory ChitDraw.fromJson(Map<String, dynamic> json) {
    final payable =
        double.tryParse('${json['payable_contribution'] ?? json['payable_amount']}') ??
            0;
    final paid = double.tryParse('${json['amount_paid'] ?? json['paid_amount'] ?? 0}') ?? 0;
    return ChitDraw(
      drawNumber: int.tryParse('${json['draw_number'] ?? json['installment_no']}') ?? 0,
      scheduledDate: DateTime.tryParse(
              '${json['scheduled_date'] ?? json['due_date']}') ??
          DateTime.now(),
      payableContribution: payable,
      dividendPoolValue: double.tryParse(
              '${json['dividend_pool_value'] ?? json['pool_amount']}') ??
          0,
      status: _drawStatusFromString(json['payment_status']),
      amountPaid: paid,
      balance: double.tryParse('${json['balance'] ?? (payable - paid)}') ?? 0,
      paidDate: json['paid_date'] == null
          ? null
          : DateTime.tryParse('${json['paid_date']}'),
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

  /// Built from a `chit_payments` row — the authoritative per-contribution
  /// ledger the backend now writes and settles against a draw, rather than
  /// a chit contribution guessed out of the general account-book receipts.
  factory ChitPaymentReceipt.fromJson(Map<String, dynamic> json) {
    final installmentNo = json['installment_no'];
    final drawLabel = installmentNo != null && '$installmentNo' != '0'
        ? 'Draw #$installmentNo · '
        : '';
    return ChitPaymentReceipt(
      id: '${json['id']}',
      title: json['title']?.toString() ??
          'Chit Contribution: ${json['customer_name'] ?? json['group_name'] ?? ''}'
              .trim(),
      subtitle: json['subtitle']?.toString() ??
          '$drawLabel${(json['payment_method'] ?? 'cash').toString().toUpperCase()}',
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
      date: DateTime.tryParse(
              '${json['payment_date'] ?? json['created_at']}') ??
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

  /// First draw that hasn't been fully settled yet — partial, overdue or
  /// pending all still owe money against this draw.
  ChitDraw? get nextDueDraw {
    for (final d in draws) {
      if (!d.isSettled) return d;
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

/// Response of chit.php?action=collect: the receipt, the settled member and
/// group, and the member's rebuilt passbook rows — everything one collection
/// touches, computed and returned by the server in a single request.
class ChitCollectionResult {
  ChitCollectionResult({
    required this.member,
    required this.group,
    required this.passbookRows,
  });

  final ChitMember member;
  final ChitGroup group;
  final List<Map<String, dynamic>> passbookRows;

  factory ChitCollectionResult.fromJson(Map<String, dynamic> json) {
    final passbook = (json['passbook'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return ChitCollectionResult(
      member: ChitMember.fromJson(
          Map<String, dynamic>.from(json['member'] as Map? ?? const {})),
      group: ChitGroup.fromJson(
          Map<String, dynamic>.from(json['group'] as Map? ?? const {})),
      passbookRows: passbook,
    );
  }
}
