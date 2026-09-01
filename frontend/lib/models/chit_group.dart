enum ChitGroupStatus { active, completed, upcoming }

class ChitGroup {
  ChitGroup({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    required this.totalMembers,
    required this.durationMonths,
    required this.groupValue,
    required this.monthlyContribution,
    required this.startDate,
    required this.collectedAmount,
  });

  final String id;
  final String code;
  final String name;
  final ChitGroupStatus status;
  final int totalMembers;
  final int durationMonths;
  final double groupValue;
  final double monthlyContribution;
  final DateTime startDate;
  final double collectedAmount;

  double get pendingAmount => groupValue - collectedAmount;
  int get collectedPercent =>
      groupValue <= 0 ? 0 : ((collectedAmount / groupValue) * 100).round();
  bool get isFullyCollected => groupValue > 0 && collectedAmount >= groupValue;

  factory ChitGroup.fromJson(Map<String, dynamic> json) {
    return ChitGroup(
      id: '${json['id']}',
      code: json['group_number'] ?? '',
      name: json['group_name'] ?? '',
      status: _statusFromString(json['status']),
      totalMembers: int.tryParse('${json['total_members']}') ?? 0,
      durationMonths: int.tryParse('${json['duration']}') ?? 0,
      groupValue: double.tryParse('${json['group_value']}') ?? 0,
      monthlyContribution:
          double.tryParse('${json['monthly_contribution']}') ?? 0,
      startDate: DateTime.tryParse('${json['start_date']}') ?? DateTime.now(),
      collectedAmount: double.tryParse('${json['collected_amount']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_number': code,
      'group_name': name,
      'status': _statusToString(status),
      'total_members': totalMembers,
      'duration': durationMonths,
      'group_value': groupValue,
      'monthly_contribution': monthlyContribution,
      'start_date': startDate.toIso8601String().split('T').first,
      'collected_amount': collectedAmount,
    };
  }

  static String _statusToString(ChitGroupStatus status) {
    switch (status) {
      case ChitGroupStatus.active:
        return 'active';
      case ChitGroupStatus.completed:
        return 'closed';
      case ChitGroupStatus.upcoming:
        return 'pending';
    }
  }

  static ChitGroupStatus _statusFromString(dynamic v) {
    switch ('$v'.toLowerCase()) {
      case 'closed':
      case 'completed':
        return ChitGroupStatus.completed;
      case 'pending':
      case 'upcoming':
        return ChitGroupStatus.upcoming;
      default:
        return ChitGroupStatus.active;
    }
  }
}