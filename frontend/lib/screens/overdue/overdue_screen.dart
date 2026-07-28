import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../widgets/app_shell.dart';
import '../../theme/confirm_dialog.dart';

/// -----------------------------------------------------------------------
/// MODEL
/// -----------------------------------------------------------------------
class OverdueAccount {
  OverdueAccount({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.loanNo,
    required this.dueAmount,
    required this.daysOverdue,
    required this.startedDate,
    this.followUpNote,
    this.followUpDate,
  });

  final String id;
  final String customerName;
  final String phone;
  final String loanNo;
  final double dueAmount;
  final int daysOverdue;
  final DateTime startedDate;
  String? followUpNote;
  DateTime? followUpDate;

  bool get isCritical => daysOverdue > 30;

  String get initials {
    final parts = customerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// -----------------------------------------------------------------------
/// HELPERS
/// -----------------------------------------------------------------------
String formatIndianCurrency(num value, {bool withSymbol = true}) {
  final isNegative = value < 0;
  final intVal = value.abs().round();
  final str = intVal.toString();

  String formatted;
  if (str.length <= 3) {
    formatted = str;
  } else {
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      final posFromEnd = rest.length - i;
      buffer.write(rest[i]);
      if (posFromEnd > 1 && posFromEnd % 2 == 1) {
        buffer.write(',');
      }
    }
    formatted = '${buffer.toString()},$lastThree';
  }

  return '${withSymbol ? '₹' : ''}${isNegative ? '-' : ''}$formatted';
}

String formatDate(DateTime d) {
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
  return '$dd ${months[d.month - 1]} ${d.year}';
}

/// -----------------------------------------------------------------------
/// SCREEN
/// -----------------------------------------------------------------------
class OverdueScreen extends StatefulWidget {
  const OverdueScreen({super.key});

  @override
  State<OverdueScreen> createState() => _OverdueScreenState();
}

class _OverdueScreenState extends State<OverdueScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Fixes web scrollbar controller exceptions
  String _filter = 'All overdue';

  // TODO(backend): replace with GET /api/overdue via ApiService.
  final List<OverdueAccount> _accounts = [
    OverdueAccount(
      id: '1',
      customerName: 'Lakshmi Iyer',
      phone: '9988776654',
      loanNo: 'LN-DE34F5',
      dueAmount: 197301,
      daysOverdue: 499,
      startedDate: DateTime(2025, 3, 1),
    ),
  ];

  List<OverdueAccount> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _accounts.where((a) {
      final matchesQuery = query.isEmpty ||
          a.customerName.toLowerCase().contains(query) ||
          a.loanNo.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        'Critical (>30d)' => a.isCritical,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  double get _totalOverdueAmount =>
      _accounts.fold(0, (sum, a) => sum + a.dueAmount);

  double get _avgDaysOverdue {
    if (_accounts.isEmpty) return 0;
    return _accounts.fold<int>(0, (sum, a) => sum + a.daysOverdue) /
        _accounts.length;
  }

  int get _criticalCount => _accounts.where((a) => a.isCritical).length;

  Future<void> _confirmMessage(OverdueAccount account) async {
    // Displays the smooth bottom-sheet style confirmation dialog
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Send Message Reminder',
      message:
          'Send an automated overdue reminder to ${account.customerName} (${account.phone})?',
      confirmLabel: 'Send',
      confirmButtonColor:
          AppColors.kInfo, // Info/blue brand color fits messaging actions well
    );

    // Execute the sending logic only if confirmed
    if (confirmed == true && mounted) {
      ToastService.show(
        title: 'Message sent',
        message: account.customerName,
        type: ToastType.success,
      );
    }
  }

  Future<void> _confirmCall(OverdueAccount account) async {
    // Call your custom edge-to-edge iOS-style bottom dialog helper asynchronously
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Call Customer',
      message: '${account.customerName}\n${account.phone}',
      confirmLabel: 'Call',
      confirmButtonColor: AppColors
          .kGoldDark, // Using your vibrant brand color for a friendly prompt
    );

    // Execute the calling sequence only if confirmed
    if (confirmed == true && mounted) {
      ToastService.show(
        title: 'Calling...',
        message: account.phone,
        type: ToastType.info,
      );
    }
  }

  Future<void> _openAssignFollowUp(OverdueAccount account) async {
    final double maxSheetHeight = MediaQuery.of(context).size.height * 0.75;
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    final result = await showModalBottomSheet<_FollowUpResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardPadding),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            decoration: const BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: _AssignFollowUpDialog(account: account),
              ),
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        account.followUpNote = result.note;
        account.followUpDate = result.date;
      });
      ToastService.show(
        title: 'Follow-up assigned',
        message: account.customerName,
        type: ToastType.success,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // Properly dispose the scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 720;

    return AppShell(
      currentRoute: AppRoutes.overdue,
      title: 'Overdue Management',
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text(
            'Track and follow up on overdue loan accounts',
            style: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_accounts.length} overdue',
                style: const TextStyle(
                  color: AppColors.kDanger,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: isWide ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _StatCard(
                icon: Icons.error_outline_rounded,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: AppColors.kDanger,
                label: 'TOTAL OVERDUE',
                value: '${_accounts.length}',
                sub: 'accounts',
              ),
              _StatCard(
                icon: Icons.phone_in_talk_outlined,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: AppColors.kDanger,
                label: 'OVERDUE AMOUNT',
                value: formatIndianCurrency(_totalOverdueAmount),
                sub: 'outstanding',
              ),
              _StatCard(
                icon: Icons.notifications_active_outlined,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: AppColors.kWarning,
                label: 'AVG DAYS OVERDUE',
                value: '${_avgDaysOverdue.round()} d',
                sub: 'across accounts',
              ),
              _StatCard(
                icon: Icons.error_outline_rounded,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: AppColors.kDanger,
                label: 'CRITICAL (>30D)',
                value: '$_criticalCount',
                sub: 'needs attention',
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search customer or loan number...',
              prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
              filled: true,
              fillColor: AppColors.kSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filter,
                isExpanded: true,
                icon: const Icon(Icons.unfold_more_rounded,
                    color: AppColors.kTextMuted),
                style:
                    const TextStyle(color: AppColors.kTextDark, fontSize: 15),
                items: const [
                  DropdownMenuItem(
                      value: 'All overdue', child: Text('All overdue')),
                  DropdownMenuItem(
                      value: 'Critical (>30d)', child: Text('Critical (>30d)')),
                ],
                onChanged: (v) => setState(() => _filter = v ?? 'All overdue'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'No overdue accounts match your search.',
                  style: TextStyle(color: AppColors.kTextMuted),
                ),
              ),
            )
          else
            ...filtered.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _OverdueCard(
                  account: a,
                  onMessage: () => _confirmMessage(a),
                  onCall: () => _confirmCall(a),
                  onAssignFollowUp: () => _openAssignFollowUp(a),
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
    required this.sub,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.kTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.kTextDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(sub,
              style:
                  const TextStyle(color: AppColors.kTextMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// OVERDUE ACCOUNT CARD
/// -----------------------------------------------------------------------
class _OverdueCard extends StatelessWidget {
  const _OverdueCard({
    required this.account,
    required this.onMessage,
    required this.onCall,
    required this.onAssignFollowUp,
  });

  final OverdueAccount account;
  final VoidCallback onMessage;
  final VoidCallback onCall;
  final VoidCallback onAssignFollowUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.kInfo,
                child: Text(
                  account.initials,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextDark,
                      ),
                    ),
                    Text(account.phone,
                        style: const TextStyle(
                            color: AppColors.kTextMuted, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Overdue',
                  style: TextStyle(
                      color: AppColors.kDanger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _InfoBlock(label: 'Loan No.', value: account.loanNo)),
              Expanded(
                child: _InfoBlock(
                  label: 'Due Amount',
                  value: formatIndianCurrency(account.dueAmount),
                  valueColor: AppColors.kDanger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoBlock(
                    label: 'Days Overdue',
                    value: '${account.daysOverdue} days'),
              ),
              Expanded(
                child: _InfoBlock(
                    label: 'Started', value: formatDate(account.startedDate)),
              ),
            ],
          ),
          if (account.followUpNote != null &&
              account.followUpNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EFE8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FOLLOW-UP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(account.followUpNote!,
                      style: const TextStyle(
                          color: AppColors.kTextDark, fontSize: 13)),
                  if (account.followUpDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Due ${formatDate(account.followUpDate!)}',
                      style: const TextStyle(
                          color: AppColors.kTextMuted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          // Mobile-responsive action row: wraps to a new line on narrow screens.
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final buttons = <Widget>[
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Message',
                  onTap: onMessage,
                  outlined: true,
                ),
                _ActionButton(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  onTap: onCall,
                  outlined: true,
                ),
                _ActionButton(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Assign Follow-up',
                  onTap: onAssignFollowUp,
                  outlined: false,
                ),
              ];

              if (narrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: buttons[0]),
                        const SizedBox(width: 10),
                        Expanded(child: buttons[1]),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: buttons[2]),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: buttons[0]),
                  const SizedBox(width: 10),
                  Expanded(child: buttons[1]),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: buttons[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.kTextDark,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.outlined,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// ASSIGN FOLLOW-UP DIALOG
/// -----------------------------------------------------------------------
class _FollowUpResult {
  _FollowUpResult(this.note, this.date);
  final String note;
  final DateTime date;
}

class _AssignFollowUpDialog extends StatefulWidget {
  const _AssignFollowUpDialog({required this.account});
  final OverdueAccount account;

  @override
  State<_AssignFollowUpDialog> createState() => _AssignFollowUpDialogState();
}

class _AssignFollowUpDialogState extends State<_AssignFollowUpDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteCtrl;
  late DateTime _followUpDate;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.account.followUpNote ?? '');
    _followUpDate = widget.account.followUpDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              Theme.of(context).colorScheme.copyWith(primary: AppColors.kGold),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _followUpDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
        context, _FollowUpResult(_noteCtrl.text.trim(), _followUpDate));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    final dd = _followUpDate.day.toString().padLeft(2, '0');
    final mm = _followUpDate.month.toString().padLeft(2, '0');
    final yyyy = _followUpDate.year.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assign Follow-up',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextDark,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.kBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.kInfo,
                    child: Text(
                      a.initials,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          a.loanNo,
                          style: const TextStyle(
                              color: AppColors.kTextMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Overdue',
                      style: TextStyle(
                          color: AppColors.kDanger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _FieldLabel('FOLLOW-UP NOTE'),
            TextFormField(
              controller: _noteCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'e.g. Called customer, promised to pay by Friday',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 18),
            const _FieldLabel('FOLLOW-UP DATE'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Text('$dd/$mm/$yyyy'),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Started: ${formatDate(a.startedDate)}',
                  style: const TextStyle(
                      color: AppColors.kTextMuted, fontSize: 13),
                ),
                Text(
                  'Outstanding: ${formatIndianCurrency(a.dueAmount)}',
                  style: const TextStyle(
                    color: AppColors.kTextDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.kTextMuted,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
