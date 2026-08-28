/// Chit member — one customer's contribution slot within a chit group.
/// Mirrors the `chit_members` table.
///
/// Save as: lib/models/chit_member.dart

enum ChitPaymentStatus { paid, partial, overdue, pending }

class ChitMember {
  ChitMember({
    required this.id,
    required this.groupId,
    this.customerId,
    required this.memberName,
    this.phone,
    required this.contributionAmount,
    this.dueDate,
    required this.status,
  });

  final String id;
  final String groupId;
  final String? customerId;
  final String memberName;
  final String? phone;
  final double contributionAmount;
  final DateTime? dueDate;
  final ChitPaymentStatus status;

  factory ChitMember.fromJson(Map<String, dynamic> json) {
    return ChitMember(
      id: '${json['id']}',
      groupId: '${json['group_id']}',
      customerId: json['customer_id'] == null ? null : '${json['customer_id']}',
      memberName:
          (json['member_name'] ?? json['customer_name'] ?? '').toString(),
      // `phone` is not a chit_members column — kept in case the backend
      // joins customers to return one. Falls back to null if absent.
      phone: (json['phone'] ?? json['customer_phone'] ?? json['mobile'])
          ?.toString(),
      contributionAmount:
          double.tryParse('${json['contribution_amount']}') ?? 0,
      dueDate: json['due_date'] == null
          ? null
          : DateTime.tryParse('${json['due_date']}'),
      status: _statusFromString(json['payment_status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      if (customerId != null) 'customer_id': customerId,
      'member_name': memberName,
      'contribution_amount': contributionAmount,
      if (dueDate != null)
        'due_date': dueDate!.toIso8601String().split('T').first,
      'payment_status': statusToString(status),
    };
  }

  ChitMember copyWith({String? phone}) {
    return ChitMember(
      id: id,
      groupId: groupId,
      customerId: customerId,
      memberName: memberName,
      phone: phone ?? this.phone,
      contributionAmount: contributionAmount,
      dueDate: dueDate,
      status: status,
    );
  }

  static ChitPaymentStatus _statusFromString(dynamic v) {
    switch ('$v'.toLowerCase()) {
      case 'paid':
        return ChitPaymentStatus.paid;
      case 'partial':
        return ChitPaymentStatus.partial;
      case 'overdue':
        return ChitPaymentStatus.overdue;
      default:
        return ChitPaymentStatus.pending;
    }
  }

  static String statusToString(ChitPaymentStatus s) {
    switch (s) {
      case ChitPaymentStatus.paid:
        return 'paid';
      case ChitPaymentStatus.partial:
        return 'partial';
      case ChitPaymentStatus.overdue:
        return 'overdue';
      case ChitPaymentStatus.pending:
        return 'pending';
    }
  }
}

/// Customer profile shown in the Add Member dropdown.
class ChitCustomerOption {
  ChitCustomerOption({
    required this.id,
    required this.name,
    required this.role,
    this.phone,
  });

  final String id;
  final String name;
  final String role;
  final String? phone;

  String get displayLabel =>
      phone == null || phone!.trim().isEmpty ? name : '$name — $phone';

  factory ChitCustomerOption.fromJson(Map<String, dynamic> json) {
    return ChitCustomerOption(
      // Chit members use the linked customer row id. Fall back to the profile
      // id when an older profile does not have a customer_id yet.
      id: '${json['customer_id'] ?? json['id']}',
      name: (json['full_name'] ?? json['name'] ?? json['customer_name'] ?? '')
          .toString(),
      role: (json['role'] ?? 'customer').toString(),
      phone:
          (json['phone'] ?? json['mobile'] ?? json['phone_number'])?.toString(),
    );
  }
}
