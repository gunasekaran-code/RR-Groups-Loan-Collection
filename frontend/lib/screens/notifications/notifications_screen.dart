import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/confirm_dialog.dart';
import '../../theme/glass_toast.dart';
import '../../models/AppNotification.dart';
import '../../models/app_user.dart';
import '../../services/NotificationService.dart';
import '../../services/session_service.dart'; // adjust import to your actual SessionService location
import '../../services/customer_api_service.dart'; // adjust import to your actual CustomerApiService location
import 'notification_state.dart';

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

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter _filter = NotificationFilter.all;
  final ScrollController _scrollController = ScrollController();

  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

Future<void> _loadNotifications() async {
  setState(() {
    _loading = true;
    _error = null;
  });
  try {
    final user = SessionService.instance.currentUser;
    final candidateIds = <String>{
      (user?.customerId ?? '').trim(),
      (user?.userId ?? '').trim(),
    }..removeWhere((e) => e.isEmpty);

    if (candidateIds.isEmpty) {
      setState(() {
        _error = 'No logged-in user found';
        _loading = false;
      });
      return;
    }

    final list = await NotificationService.fetchAllForUser(
      candidateIds: candidateIds.toList(),
    );
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (!mounted) return;
    setState(() => _notifications = list);
    NotificationState.instance.setCount(list.where((n) => !n.read).length);
  } catch (e) {
    if (!mounted) return;
    setState(() => _error = 'Failed to load notifications');
    ToastService.show(
      title: 'Could not load notifications',
      message: e.toString(),
      type: ToastType.error,
    );
  } finally {
    if (mounted) setState(() => _loading = false);
  }
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

  void _markAllRead() async {
    final unreadIds =
        _notifications.where((n) => !n.read).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;

    final previousStates = {for (var n in _notifications) n.id: n.read};

    setState(() {
      for (var n in _notifications) {
        n.read = true;
      }
    });

    try {
      await NotificationService.markAllRead(unreadIds);
      if (!mounted) return;
      NotificationState.instance.setCount(0);
      ToastService.show(
        title: 'All notifications cleared',
        message: 'Everything has been marked as read.',
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        for (var n in _notifications) {
          n.read = previousStates[n.id] ?? n.read;
        }
      });
      ToastService.show(
        title: 'Failed to update',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  void _deleteNotification(AppNotification n) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Notification',
      message:
          'Are you sure you want to delete "${n.title}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed != true || !mounted) return;

    final index = _notifications.indexOf(n);
    setState(() => _notifications.removeWhere((x) => x.id == n.id));

    try {
      await NotificationService.delete(n.id);
      if (!mounted) return;
      NotificationState.instance
          .setCount(_notifications.where((x) => !x.read).length);
      ToastService.show(
        title: 'Notification removed',
        message: n.title,
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _notifications.insert(index.clamp(0, _notifications.length), n),
      );
      ToastService.show(
        title: 'Failed to delete',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  void _markRead(AppNotification notification) async {
    if (notification.read) return;

    setState(() => notification.read = true);

    try {
      await NotificationService.markRead(notification.id);
      if (!mounted) return;
      NotificationState.instance
          .setCount(_notifications.where((n) => !n.read).length);
      ToastService.show(title: 'Marked as read', type: ToastType.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => notification.read = false);
      ToastService.show(
        title: 'Failed to mark as read',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  /// -----------------------------------------------------------------------
  /// SEND NOTIFICATION SHEET (bottom-up, matching Passbook / Funds style)
  /// -----------------------------------------------------------------------
  Widget _sheetFrame({required Widget child}) {
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final double maxSheetHeight = MediaQuery.of(context).size.height * 0.85;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: const BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(top: false, child: SingleChildScrollView(child: child)),
      ),
    );
  }

  Future<void> _openSendDialog() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _sheetFrame(child: const _SendNotificationDialog()),
    );
    if (sent == true) _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShell(
        currentRoute: AppRoutes.notifications,
        title: 'Notifications',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _notifications.isEmpty) {
      return AppShell(
        currentRoute: AppRoutes.notifications,
        title: 'Notifications',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  style: const TextStyle(color: AppColors.kTextMuted)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadNotifications,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filtered;

    return AppShell(
      currentRoute: AppRoutes.notifications,
      title: 'Notifications',
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const SizedBox(height: 6),
            const Text(
              'Stay on top of dues, approvals, and reminders',
              style: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _unreadCount == 0 ? null : _markAllRead,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Mark all read'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openSendDialog,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
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
          border: Border.all(
              color: selected ? AppColors.kGold : AppColors.kBorder),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    final AppUser? user = SessionService.instance.currentUser;
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
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
                    'user_id: ${n.userId}  |  customer_id: ${user?.customerId ?? '-'}',
                    style: const TextStyle(
                        color: AppColors.kTextMuted, fontSize: 11),
                  ),
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

/// -----------------------------------------------------------------------
/// SEND NOTIFICATION DIALOG (bottom sheet content)
/// -----------------------------------------------------------------------
class _SendNotificationDialog extends StatefulWidget {
  const _SendNotificationDialog();

  @override
  State<_SendNotificationDialog> createState() =>
      _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<_SendNotificationDialog> {
  bool _allCustomers = true;
  List<Map<String, String>> _customers = []; // {id, name, email}
  Map<String, String> _customerUserIds = {}; // customer_id -> profile id
  final Set<String> _selectedIds = {};
  String _search = '';
  String _type = 'info';
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _loadingCustomers = true;
  bool _sending = false;

  final _types = const [
    {'value': 'info', 'label': 'Info'},
    {'value': 'reminder', 'label': 'Reminder'},
    {'value': 'emi_due', 'label': 'EMI Due'},
    {'value': 'overdue', 'label': 'Overdue'},
    {'value': 'approval', 'label': 'Approval'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final api = CustomerApiService();
      final list = await api.fetchAllLite();
      final logins = await api.fetchCustomerLogins();
      if (!mounted) return;
      setState(() {
        _customers = list;
        _customerUserIds = {
          for (final row in logins)
            if ((row['customer_id'] ?? '').isNotEmpty) row['customer_id']!: row['id']!,
        };
        _loadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCustomers = false);
      ToastService.show(
        title: 'Could not load customers',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  List<Map<String, String>> get _filteredCustomers {
    if (_search.trim().isEmpty) return _customers;
    final q = _search.toLowerCase();
    return _customers
        .where((c) =>
            (c['name'] ?? '').toLowerCase().contains(q) ||
            (c['email'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  int get _recipientCount =>
      _allCustomers
          ? _customers.where((c) => _customerUserIds[c['id']] != null).length
          : _selectedIds.length;

  Future<void> _handleSend() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ToastService.show(title: 'Title required', type: ToastType.error);
      return;
    }
    if (_allCustomers && _customers.isEmpty) {
      ToastService.show(
          title: 'No customers found', type: ToastType.error);
      return;
    }
    if (_allCustomers && _customerUserIds.isEmpty) {
      ToastService.show(
          title: 'No linked customer logins found', type: ToastType.error);
      return;
    }
    if (!_allCustomers && _selectedIds.isEmpty) {
      ToastService.show(
          title: 'Select at least one recipient', type: ToastType.error);
      return;
    }

    final recipientIds = _allCustomers
        ? _customers
            .map((c) => _customerUserIds[c['id']])
            .whereType<String>()
            .toList()
        : _selectedIds.toList();

    setState(() => _sending = true);
    try {
      await NotificationService.send(
        userIds: recipientIds,
        type: _type,
        title: _titleCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );
      if (!mounted) return;
      ToastService.show(
        title: 'Notification sent',
        message: '$_recipientCount recipient(s)',
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ToastService.show(
          title: 'Send failed', message: e.toString(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.send_rounded,
                    color: AppColors.kGold, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Send Notification',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark)),
                    SizedBox(height: 2),
                    Text('Notify your customers instantly',
                        style: TextStyle(
                            color: AppColors.kTextMuted, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('RECIPIENTS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ToggleChip(
                  icon: Icons.groups_outlined,
                  label: 'All Customers',
                  trailing: '${_customerUserIds.length}',
                  selected: _allCustomers,
                  onTap: () => setState(() => _allCustomers = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ToggleChip(
                  icon: Icons.person_search_outlined,
                  label: 'Select',
                  selected: !_allCustomers,
                  onTap: () => setState(() => _allCustomers = false),
                ),
              ),
            ],
          ),
          if (!_allCustomers) ...[
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Search customers...',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _loadingCustomers
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _filteredCustomers.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('No customers found.',
                                style:
                                    TextStyle(color: AppColors.kTextMuted)),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _filteredCustomers.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: AppColors.kBorder),
                          itemBuilder: (context, i) {
                            final c = _filteredCustomers[i];
                            final id = c['id']!;
                            final checked = _selectedIds.contains(id);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selectedIds.add(id);
                                } else {
                                  _selectedIds.remove(id);
                                }
                              }),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              title: Text(c['name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.kTextDark)),
                              subtitle: Text(c['email'] ?? '',
                                  style: const TextStyle(
                                      color: AppColors.kTextMuted,
                                      fontSize: 12)),
                              activeColor: AppColors.kGold,
                            );
                          },
                        ),
            ),
          ],
          const SizedBox(height: 20),
          const Text('TYPE',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((t) {
              final selected = _type == t['value'];
              return ChoiceChip(
                label: Text(t['label']!),
                selected: selected,
                onSelected: (_) => setState(() => _type = t['value']!),
                selectedColor: AppColors.kGold,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.kTextDark,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: const Color(0xFFF3F4F6),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('TITLE',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextMuted)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
                isDense: true, hintText: 'e.g. EMI due tomorrow'),
          ),
          const SizedBox(height: 16),
          const Text('MESSAGE',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextMuted)),
          const SizedBox(height: 8),
          TextField(
            controller: _messageCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                isDense: true, hintText: 'Write your message...'),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 420;
            final recipientLabel = Text(
              _recipientCount == 0
                  ? 'No recipients selected'
                  : '$_recipientCount recipient(s) selected',
              style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
            );
            final actionButtons = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: _sending ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _sending ? null : _handleSend,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send'),
                ),
              ],
            );
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  recipientLabel,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: actionButtons),
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [recipientLabel, actionButtons],
            );
          }),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFEF3C7) : AppColors.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.kGold : AppColors.kBorder),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppColors.kGold : AppColors.kTextMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.kGold : AppColors.kTextDark)),
            ),
            if (trailing != null)
              Text(trailing!, style: const TextStyle(color: AppColors.kTextMuted)),
          ],
        ),
      ),
    );
  }
}
