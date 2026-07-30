import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // adjust path if needed

enum NotificationType { reminder, info, emiDue, overdue, approval }

extension NotificationTypeX on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.info:
        return 'Info';
      case NotificationType.emiDue:
        return 'EMI Due';
      case NotificationType.overdue:
        return 'Overdue';
      case NotificationType.approval:
        return 'Approval';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.info:
        return Icons.info_outline_rounded;
      case NotificationType.emiDue:
        return Icons.event_note_rounded;
      case NotificationType.overdue:
        return Icons.error_outline_rounded;
      case NotificationType.approval:
        return Icons.task_alt_rounded;
    }
  }

  Color get iconColor {
    switch (this) {
      case NotificationType.reminder:
        return const Color(0xFF7C3AED);
      case NotificationType.info:
        return AppColors.kTextMuted;
      case NotificationType.emiDue:
        return AppColors.kWarning;
      case NotificationType.overdue:
        return AppColors.kDanger;
      case NotificationType.approval:
        return AppColors.kInfo;
    }
  }

  Color get iconBg {
    switch (this) {
      case NotificationType.reminder:
        return const Color(0xFFEDE9FE);
      case NotificationType.info:
        return const Color(0xFFF1EFE8);
      case NotificationType.emiDue:
        return const Color(0xFFFEF3C7);
      case NotificationType.overdue:
        return const Color(0xFFFEE2E2);
      case NotificationType.approval:
        return const Color(0xFFDCEAFE);
    }
  }

  Color get badgeBg => iconBg;

  Color get badgeFg {
    switch (this) {
      case NotificationType.reminder:
        return const Color(0xFF7C3AED);
      case NotificationType.info:
        return AppColors.kTextMuted;
      case NotificationType.emiDue:
        return AppColors.kWarning;
      case NotificationType.overdue:
        return AppColors.kDanger;
      case NotificationType.approval:
        return AppColors.kInfo;
    }
  }
}

NotificationType _typeFromString(String v) {
  switch (v) {
    case 'reminder':
      return NotificationType.reminder;
    case 'emiDue':
    case 'emi_due':
      return NotificationType.emiDue;
    case 'overdue':
      return NotificationType.overdue;
    case 'approval':
      return NotificationType.approval;
    default:
      return NotificationType.info;
  }
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  bool read;

factory AppNotification.fromJson(Map<String, dynamic> json) {
  return AppNotification(
    id: json['id'].toString(),
    type: _typeFromString(json['type']?.toString() ?? 'info'),
    title: json['title']?.toString() ?? '',
    body: json['message']?.toString() ?? '',  
    timestamp: DateTime.tryParse(
          (json['created_at'] ?? json['timestamp'] ?? '').toString(),
        ) ??
        DateTime.now(),
    read: json['read'] == 1 ||
        json['read'] == true ||
        json['read']?.toString() == '1',
  );
}

Map<String, dynamic> toCreateJson() => {
      'type': type.name,
      'title': title,
      'message': body,
      'read': read ? 1 : 0,
    };
}

String formatNotificationTime(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final dd = d.day.toString().padLeft(2, '0');
  final hour24 = d.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';
  return '$dd ${months[d.month - 1]} ${d.year} at $hour12:$minute $period';
}