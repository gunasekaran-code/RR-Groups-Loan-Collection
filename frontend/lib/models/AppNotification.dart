import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NotificationType { info, reminder, emiDue, overdue, approval }

extension NotificationTypeX on NotificationType {
  static NotificationType fromDb(String? value) {
    switch (value) {
      case 'reminder':
        return NotificationType.reminder;
      case 'emi_due':
        return NotificationType.emiDue;
      case 'overdue':
        return NotificationType.overdue;
      case 'approval':
        return NotificationType.approval;
      case 'info':
      default:
        return NotificationType.info;
    }
  }

  String get label {
    switch (this) {
      case NotificationType.info:
        return 'Info';
      case NotificationType.reminder:
        return 'Reminder';
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
      case NotificationType.info:
        return Icons.info_outline_rounded;
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.emiDue:
        return Icons.calendar_today_rounded;
      case NotificationType.overdue:
        return Icons.error_outline_rounded;
      case NotificationType.approval:
        return Icons.check_circle_outline_rounded;
    }
  }

  Color get iconBg {
    switch (this) {
      case NotificationType.info:
        return const Color(0xFFDCEAFE);
      case NotificationType.reminder:
        return const Color(0xFFFEF3C7);
      case NotificationType.emiDue:
        return const Color(0xFFEDE9FE);
      case NotificationType.overdue:
        return const Color(0xFFFEE2E2);
      case NotificationType.approval:
        return const Color(0xFFD1FAE5);
    }
  }

  Color get iconColor {
    switch (this) {
      case NotificationType.info:
        return AppColors.kInfo;
      case NotificationType.reminder:
        return AppColors.kGold;
      case NotificationType.emiDue:
        return const Color(0xFF7C3AED);
      case NotificationType.overdue:
        return AppColors.kDanger;
      case NotificationType.approval:
        return const Color(0xFF059669);
    }
  }

  Color get badgeBg => iconBg;
  Color get badgeFg => iconColor;
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  bool read;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.timestamp,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['message']?.toString() ?? '',
      type: NotificationTypeX.fromDb(json['type']?.toString()),
      read: json['read'] == 1 || json['read'] == true || json['read'] == '1',
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

String formatNotificationTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}