import 'chit_member.dart' show ChitPaymentStatus;

enum ChitScheduleDateType { autoScheduled, customOverridden }

/// One draw's payment position across the whole group — folded from every
/// member's `chit_passbook` row for that installment number, rather than a
/// single member's. Backs the "PAYMENT STATUS" column on the admin's
/// Installment Schedule tab (as opposed to a member's own passbook, which
/// only ever shows their own single status).
class ChitScheduleStatusSummary {
  ChitScheduleStatusSummary({
    required this.installmentNo,
    required this.paidMembers,
    required this.totalMembers,
    required this.paidAmount,
    required this.status,
  });

  final int installmentNo;
  final int paidMembers;
  final int totalMembers;
  final double paidAmount;
  final ChitPaymentStatus status;
}

class ChitSchedule {
  ChitSchedule({
    required this.id,
    required this.groupId,
    required this.installmentNo,
    required this.dueDate,
    required this.payableAmount,
    required this.poolAmount,
    required this.dateType,
    this.overrideNotes,
  });

  final String id;
  final String groupId;
  final int installmentNo;
  final DateTime dueDate;
  final double payableAmount;
  final double poolAmount;
  final ChitScheduleDateType dateType;
  final String? overrideNotes;

  factory ChitSchedule.fromJson(Map<String, dynamic> json) {
    return ChitSchedule(
      id: json['id'].toString(),
      groupId: json['group_id'].toString(),
      installmentNo: int.tryParse(json['installment_no'].toString()) ?? 0,
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? '') ??
          DateTime.now(),
      payableAmount:
          double.tryParse(json['payable_amount'].toString()) ?? 0,
      poolAmount: double.tryParse(json['pool_amount'].toString()) ?? 0,
      dateType: (json['is_custom'] == true ||
              json['is_custom'] == 1 ||
              json['is_custom'].toString() == '1')
          ? ChitScheduleDateType.customOverridden
          : ChitScheduleDateType.autoScheduled,
      overrideNotes: json['override_notes']?.toString(),
    );
  }
}
