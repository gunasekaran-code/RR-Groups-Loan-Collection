import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart'; // adjust path if your app_theme.dart lives elsewhere
import '../../widgets/app_shell.dart';
import '../../theme/confirm_dialog.dart';
import '../../theme/glass_toast.dart';

/// -----------------------------------------------------------------------
/// MODEL
/// -----------------------------------------------------------------------
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

  Color get badgeBg {
    switch (this) {
      case NotificationType.reminder:
        return const Color(0xFFEDE9FE);
      case NotificationType.info:
        return const Color(0xFFE5E7EB);
      case NotificationType.emiDue:
        return const Color(0xFFFEF3C7);
      case NotificationType.overdue:
        return const Color(0xFFFEE2E2);
      case NotificationType.approval:
        return const Color(0xFFDCEAFE);
    }
  }

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
}

/// -----------------------------------------------------------------------
/// HELPERS
/// -----------------------------------------------------------------------
String formatNotificationTime(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final dd = d.day.toString().padLeft(2, '0');
  final hour24 = d.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';
  return '$dd ${months[d.month - 1]} ${d.year} at $hour12:$minute $period';
}

/// -----------------------------------------------------------------------
/// FILTERS
/// -----------------------------------------------------------------------
enum NotificationFilter { all, unread, emiDue, overdue, approvals, reminders }

extension NotificationFilterX on NotificationFilter {
  String get label {
    switch (this) {
      case NotificationFilter.all:
        return 'All';
      case NotificationFilter.unread:
        return 'Unread';
      case NotificationFilter.emiDue:
        return 'EMI Due';
      case NotificationFilter.overdue:
        return 'Overdue';
      case NotificationFilter.approvals:
        return 'Approvals';
      case NotificationFilter.reminders:
        return 'Reminders';
    }
  }
}

/// -----------------------------------------------------------------------
/// SCREEN
/// -----------------------------------------------------------------------
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter _filter = NotificationFilter.all;
  // Fixes the web scrollbar exception seen in your console
  final ScrollController _scrollController = ScrollController();

  // TODO(backend): replace with GET /api/notifications via ApiService.
  final List<AppNotification> _notifications = [
    AppNotification(
      id: '1',
      type: NotificationType.reminder,
      title: 'Follow-up call to Lakshmi Iyer',
      body: 'Call placed to 9988776654 for overdue loan LN-DE34F5.',
      timestamp: DateTime(2026, 7, 13, 10, 8),
      read: false,
    ),
    AppNotification(
      id: '2',
      type: NotificationType.reminder,
      title: 'Follow-up SMS to Lakshmi Iyer',
      body: 'SMS sent to 9988776654 for overdue loan LN-DE34F5.',
      timestamp: DateTime(2026, 7, 13, 10, 8),
      read: false,
    ),
    AppNotification(
      id: '3',
      type: NotificationType.info,
      title: 'New Collection Received',
      body: 'Agent Arjun Mehta collected ₹4,349.42 from Lakshmi Iyer.',
      timestamp: DateTime(2026, 7, 13, 9, 40),
      read: true,
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose(); // Clean up the controller
    super.dispose();
  }

  int get _totalCount => _notifications.length;
  int get _unreadCount => _notifications.where((n) => !n.read).length;
  int get _overdueCount =>
      _notifications.where((n) => n.type == NotificationType.overdue).length;

  int _countFor(NotificationFilter f) {
    switch (f) {
      case NotificationFilter.all:
        return _totalCount;
      case NotificationFilter.unread:
        return _unreadCount;
      case NotificationFilter.emiDue:
        return _notifications
            .where((n) => n.type == NotificationType.emiDue)
            .length;
      case NotificationFilter.overdue:
        return _overdueCount;
      case NotificationFilter.approvals:
        return _notifications
            .where((n) => n.type == NotificationType.approval)
            .length;
      case NotificationFilter.reminders:
        return _notifications
            .where((n) => n.type == NotificationType.reminder)
            .length;
    }
  }

  List<AppNotification> get _filtered {
    switch (_filter) {
      case NotificationFilter.all:
        return _notifications;
      case NotificationFilter.unread:
        return _notifications.where((n) => !n.read).toList();
      case NotificationFilter.emiDue:
        return _notifications
            .where((n) => n.type == NotificationType.emiDue)
            .toList();
      case NotificationFilter.overdue:
        return _notifications
            .where((n) => n.type == NotificationType.overdue)
            .toList();
      case NotificationFilter.approvals:
        return _notifications
            .where((n) => n.type == NotificationType.approval)
            .toList();
      case NotificationFilter.reminders:
        return _notifications
            .where((n) => n.type == NotificationType.reminder)
            .toList();
    }
  }

void _markAllRead() {
    if (_unreadCount == 0) return;

    setState(() {
      for (var n in _notifications) {
        n.read = true; // Fixed: changed 'isRead' to 'read'
      }
    }); // Automatically updates the counts via getters

    ToastService.show(
      title: 'All notifications cleared',
      message: 'Everything has been marked as read.',
      type: ToastType.success,
    );
  }

  void _deleteNotification(AppNotification n) async {
    // Invoke your custom bottom edge-to-edge iOS layout dialog helper
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Notification',
      message:
          'Are you sure you want to delete "${n.title}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );

    // Update state only if user explicitly provides confirmation intent
    if (confirmed == true && mounted) {
      setState(() => _notifications.removeWhere((x) => x.id == n.id));

      ToastService.show(
        title: 'Notification removed',
        message: n.title,
        type: ToastType.success,
      );
    }
  }

void _markRead(AppNotification notification) { // Fixed: changed 'NotificationModel' to 'AppNotification'
    // Prevent toast spam if it's already read
    if (notification.read) return; // Fixed: changed 'isRead' to 'read'

    setState(() {
      notification.read = true; // Fixed: changed 'isRead' to 'read'
    }); // Automatically updates the counts via getters

    ToastService.show(
      title: 'Marked as read',
      type: ToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return AppShell(
      currentRoute: AppRoutes.notifications,
      title: 'Notifications',
      body: ListView(
        controller:
            _scrollController, // Connected to prevent web console errors
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const SizedBox(height: 6),
          const Text(
            'Stay on top of dues, approvals, and reminders',
            style: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
          ),

          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 150,
              child: OutlinedButton.icon(
                onPressed: _unreadCount == 0 ? null : _markAllRead,
                // Changed from Icons.person_add_alt_1_outlined to double checkmarks
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Mark all read'),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.notifications_none_rounded,
                  iconBg: const Color(0xFFDCEAFE),
                  iconColor: AppColors.kInfo,
                  label: 'TOTAL',
                  value: '$_totalCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.notifications_off_outlined,
                  iconBg: const Color(0xFFEDE9FE),
                  iconColor: const Color(0xFF7C3AED),
                  label: 'UNREAD',
                  value: '$_unreadCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.error_outline_rounded,
                  iconBg: const Color(0xFFFEE2E2),
                  iconColor: AppColors.kDanger,
                  label: 'OVERDUE',
                  value: '$_overdueCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: NotificationFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final f = NotificationFilter.values[index];
                final isSelected = f == _filter;
                return _FilterPill(
                  label: f.label,
                  count: _countFor(f),
                  selected: isSelected,
                  onTap: () => setState(() => _filter = f),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'No notifications here.',
                  style: TextStyle(color: AppColors.kTextMuted),
                ),
              ),
            )
          else
            ...filtered.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _NotificationCard(
                  notification: n,
                  onTap: () => _markRead(n),
                  onDelete: () => _deleteNotification(n),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// STAT CARD
/// -----------------------------------------------------------------------
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.kTextMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// FILTER PILL
/// -----------------------------------------------------------------------
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.kGold : AppColors.kSurface,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: selected ? AppColors.kGold : AppColors.kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.kTextDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.25)
                    : const Color(0xFFF1EFE8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.kTextMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// NOTIFICATION CARD
/// -----------------------------------------------------------------------
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: n.read
                  ? AppColors.kBorder
                  : AppColors.kGold.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: n.type.iconBg,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(n.type.icon, color: n.type.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!n.read) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.kInfo, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          n.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: n.type.badgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      n.type.label,
                      style: TextStyle(
                        color: n.type.badgeFg,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(n.body,
                      style: const TextStyle(
                          color: AppColors.kTextDark,
                          fontSize: 14,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Text(
                    formatNotificationTime(n.timestamp),
                    style: const TextStyle(
                        color: AppColors.kTextMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.kTextMuted, size: 20),
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}
