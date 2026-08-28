import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../widgets/app_shell.dart';
import '../../theme/confirm_dialog.dart';
import '../../models/overdue.dart';
import '../../services/overdue_api_service.dart';
import '../../l10n/generated/app_localizations.dart';

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

String formatDate(DateTime? d) {
  if (d == null) return '—';
  const months = [
    'Jan',    'Feb',    'Mar',    'Apr',
    'May',    'Jun',    'Jul',    'Aug',    'Sep',    'Oct',    'Nov',    'Dec',
  ];
  final dd = d.day.toString().padLeft(2, '0');
  return '$dd ${months[d.month - 1]} ${d.year}';
}

String _normalizePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('91') && digits.length == 12) return digits;
  if (digits.startsWith('+91')) return digits.substring(1);
  if (digits.length == 10) return '91$digits';
  return digits.replaceAll('+', '');
}

class OverdueScreen extends StatefulWidget {
  const OverdueScreen({super.key});

  @override
  State<OverdueScreen> createState() => _OverdueScreenState();
}

class _OverdueScreenState extends State<OverdueScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OverdueApiService _api = OverdueApiService();

  String _filter = 'All overdue';
  List<OverdueAccount> _accounts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts({bool recompute = false}) async {
    setState(() {
      if (_accounts.isEmpty) _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = recompute
          ? await _api.recomputeAndFetch()
          : await _api.fetchOverdueAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = data;
        _isLoading = false;
      });
    } on OverdueApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _errorMessage = l10n.overdueGenericError;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadAccounts(recompute: true);
    if (mounted) setState(() => _isRefreshing = false);
  }

  List<OverdueAccount> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _accounts.where((a) {
      final matchesQuery = query.isEmpty ||
          a.customerName.toLowerCase().contains(query) ||
          a.loanNumber.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        'Critical (>30d)' => a.isCritical,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  double get _totalOverdueAmount =>
      _accounts.fold(0, (sum, a) => sum + a.overdueAmount);

  double get _avgDaysOverdue {
    if (_accounts.isEmpty) return 0;
    return _accounts.fold<int>(0, (sum, a) => sum + a.daysOverdue) /
        _accounts.length;
  }

  int get _criticalCount => _accounts.where((a) => a.isCritical).length;

  Future<void> _confirmMessage(OverdueAccount account) async {
    final l10n = AppLocalizations.of(context);
    final phone = account.phone.trim();
    if (phone.isEmpty) {
      ToastService.show(
        title: l10n.overdueNoPhoneTitle,
        message: l10n.overdueNoPhoneMessage,
        type: ToastType.error,
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.overdueSendMessageTitle,
      message: l10n.overdueSendMessageBody(account.customerName, phone),
      confirmLabel: l10n.overdueSendLabel,
      confirmButtonColor: AppColors.kInfo,
    );

    if (confirmed == true && mounted) {
      final normalized = _normalizePhone(phone);
      final text = l10n.overdueWhatsappTemplate(
        account.customerName,
        account.loanNumber,
        account.daysOverdue,
        formatIndianCurrency(account.overdueAmount),
      );
      final uri = Uri.parse(
        'https://wa.me/$normalized?text=${Uri.encodeComponent(text)}',
      );

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ToastService.show(
          title: l10n.overdueWhatsappFailedTitle,
          message: phone,
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _confirmCall(OverdueAccount account) async {
    final l10n = AppLocalizations.of(context);
    final phone = account.phone.trim();
    if (phone.isEmpty) {
      ToastService.show(
        title: l10n.overdueNoPhoneTitle,
        message: l10n.overdueNoPhoneMessage,
        type: ToastType.error,
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.overdueCallTitle,
      message: l10n.overdueCallBody(account.customerName, phone),
      confirmLabel: l10n.overdueCallLabel,
      confirmButtonColor: AppColors.kGoldDark,
    );

    if (confirmed == true && mounted) {
      final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ToastService.show(
          title: l10n.overdueCallFailedTitle,
          message: phone,
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _openAssignFollowUp(OverdueAccount account) async {
    final l10n = AppLocalizations.of(context);
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
      if (!mounted) return;
      ToastService.show(
        title: l10n.overdueFollowUpAssignedTitle,
        message: account.customerName,
        type: ToastType.success,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filtered;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 720;

    return AppShell(
      currentRoute: AppRoutes.overdue,
      title: l10n.overdueManagementTitle,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(filtered, isWide, l10n),
      ),
    );
  }

  Widget _buildBody(
      List<OverdueAccount> filtered, bool isWide, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _accounts.isEmpty) {
      return ListView(
        // Wrapped in ListView so RefreshIndicator's pull-to-refresh works
        // even on an error/empty state.
        children: [
          const SizedBox(height: 120),
          Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.kTextMuted),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.kTextMuted),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: () => _loadAccounts(),
              child: Text(l10n.retry),
            ),
          ),
        ],
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.overdueSubtitle,
                style: const TextStyle(
                    color: AppColors.kTextMuted, fontSize: 14),
              ),
            ),
            if (_isRefreshing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
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
              l10n.overdueCountBadge(_accounts.length),
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
              label: l10n.overdueStatTotalLabel,
              value: '${_accounts.length}',
              sub: l10n.overdueStatTotalSub,
            ),
            _StatCard(
              icon: Icons.phone_in_talk_outlined,
              iconBg: const Color(0xFFFEE2E2),
              iconColor: AppColors.kDanger,
              label: l10n.overdueStatAmountLabel,
              value: formatIndianCurrency(_totalOverdueAmount),
              sub: l10n.overdueStatAmountSub,
            ),
            _StatCard(
              icon: Icons.notifications_active_outlined,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: AppColors.kWarning,
              label: l10n.overdueStatAvgDaysLabel,
              value: l10n.overdueStatAvgDaysValue(_avgDaysOverdue.round()),
              sub: l10n.overdueStatAvgDaysSub,
            ),
            _StatCard(
              icon: Icons.error_outline_rounded,
              iconBg: const Color(0xFFFEE2E2),
              iconColor: AppColors.kDanger,
              label: l10n.overdueStatCriticalLabel,
              value: '$_criticalCount',
              sub: l10n.overdueStatCriticalSub,
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l10n.overdueSearchHint,
            prefixIcon: const Icon(Icons.search, color: AppColors.kTextMuted),
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
              style: const TextStyle(color: AppColors.kTextDark, fontSize: 15),
              items: [
                DropdownMenuItem(
                    value: 'All overdue', child: Text(l10n.overdueFilterAll)),
                DropdownMenuItem(
                    value: 'Critical (>30d)',
                    child: Text(l10n.overdueFilterCritical)),
              ],
              onChanged: (v) => setState(() => _filter = v ?? 'All overdue'),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                l10n.overdueNoMatchMessage,
                style: const TextStyle(color: AppColors.kTextMuted),
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
    );
  }
}

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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
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
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
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
          Text(
            sub,
            style: const TextStyle(color: AppColors.kTextMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

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
    final l10n = AppLocalizations.of(context);
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
                child: Text(
                  l10n.overdueBadgeLabel,
                  style: const TextStyle(
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
                  child: _InfoBlock(
                      label: l10n.overdueLoanNumberLabel,
                      value: account.loanNumber)),
              Expanded(
                child: _InfoBlock(
                  label: l10n.overdueDueAmountLabel,
                  value: formatIndianCurrency(account.overdueAmount),
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
                    label: l10n.overdueDaysOverdueLabel,
                    value: l10n.overdueDaysValue(account.daysOverdue)),
              ),
              Expanded(
                child: _InfoBlock(
                    label: l10n.overdueStartedLabel,
                    value: formatDate(account.earliestDueDate)),
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
                  Text(
                    l10n.overdueFollowUpSectionLabel,
                    style: const TextStyle(
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
                      l10n.overdueFollowUpDueLabel(
                          formatDate(account.followUpDate!)),
                      style: const TextStyle(
                          color: AppColors.kTextMuted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final buttons = <Widget>[
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: l10n.overdueActionMessage,
                  onTap: onMessage,
                  outlined: true,
                ),
                _ActionButton(
                  icon: Icons.call_outlined,
                  label: l10n.overdueActionCall,
                  onTap: onCall,
                  outlined: true,
                ),
                _ActionButton(
                  icon: Icons.person_add_alt_1_rounded,
                  label: l10n.overdueActionAssignFollowUp,
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
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
        context, _FollowUpResult(_noteCtrl.text.trim(), _followUpDate));
    // l10n referenced above only to keep analyzer happy if unused elsewhere
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                Text(
                  l10n.overdueAssignFollowUpTitle,
                  style: const TextStyle(
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
                          a.loanNumber,
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
                    child: Text(
                      l10n.overdueBadgeLabel,
                      style: const TextStyle(
                          color: AppColors.kDanger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel(l10n.overdueFollowUpNoteFieldLabel),
            TextFormField(
              controller: _noteCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: l10n.overdueFollowUpNoteHint,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.overdueFieldRequired : null,
            ),
            const SizedBox(height: 18),
            _FieldLabel(l10n.overdueFollowUpDateFieldLabel),
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
                  l10n.overdueStartedValue(formatDate(a.earliestDueDate)),
                  style: const TextStyle(
                      color: AppColors.kTextMuted, fontSize: 13),
                ),
                Text(
                  l10n.overdueOutstandingValue(
                      formatIndianCurrency(a.overdueAmount)),
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
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(l10n.save),
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