import 'package:flutter/material.dart';
import '../../theme/glass_toast.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/agent_dropdown.dart';
import '../../models/cash_handover.dart';
import '../../services/cash_handover_api_service.dart';
import '../../theme/confirm_dialog.dart';
import '../../services/session_service.dart';
import '../../models/user_role.dart';

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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final dd = d.day.toString().padLeft(2, '0');
  return '$dd ${months[d.month - 1]} ${d.year}';
}

/// -----------------------------------------------------------------------
/// SIMPLE RESPONSIVE HELPERS
/// -----------------------------------------------------------------------
/// Kept local to this file on purpose — promote to a shared
/// `lib/utils/responsive.dart` once a second screen needs the same
/// breakpoints, same as we did with AgentDropdown.
class _Breakpoints {
  static const double narrow = 360; // small phones (e.g. Galaxy Fold, SE)
  static const double phone = 600; // regular phones
  static const double tablet = 900;
}

bool _isNarrow(double width) => width < _Breakpoints.narrow;
bool _isTablet(double width) => width >= _Breakpoints.phone;

/// -----------------------------------------------------------------------
/// SCREEN
/// -----------------------------------------------------------------------
class CashHandoverScreen extends StatefulWidget {
  const CashHandoverScreen({super.key});

  @override
  State<CashHandoverScreen> createState() => _CashHandoverScreenState();
}

class _CashHandoverScreenState extends State<CashHandoverScreen> {
  bool _isLoading = true;
  String? _loadError;

  double _totalCollected = 0;
  double _totalHandedOver = 0;
  double _totalPending = 0;
  int _agentsWithPending = 0;

  List<HandoverAgentOption> _agents = [];
  List<AgentSettlement> _settlements = [];
  List<HandoverRecord> _history = [];

  bool get _canCreateOrEdit =>
      SessionService.instance.currentUser?.role == UserRole.admin ||
      SessionService.instance.currentUser?.role == UserRole.agent;

  bool get _canManageRecords =>
      SessionService.instance.currentUser?.role == UserRole.admin;

  String? get _scopeAgentId {
    final role = SessionService.instance.currentUser?.role;
    if (role == UserRole.agent) {
      return SessionService.instance.currentUser?.userId;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        CashHandoverApiService.fetchSummary(),
        CashHandoverApiService.fetchSettlements(),
        CashHandoverApiService.fetchHistory(),
        CashHandoverApiService.fetchActiveAgents(),
      ]);
      final summary = results[0] as HandoverSummary;
      final settlements = results[1] as List<AgentSettlement>;
      final history = results[2] as List<HandoverRecord>;
      final agents = results[3] as List<HandoverAgentOption>;
      if (!mounted) return;
      setState(() {
        _totalCollected = summary.totalCollected;
        _totalHandedOver = summary.totalHandedOver;
        _totalPending = summary.totalPending;
        _agentsWithPending = summary.agentsWithPending;
        _agents = agents;
        _settlements = settlements;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
      ToastService.show(
        title: 'Failed to load handover data',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _openRecordHandoverDialog({HandoverRecord? existing}) async {
    final result = await showModalBottomSheet<HandoverRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildSheetFrame(
        child: _RecordHandoverDialog(
          agents: _agents,
          existing: existing,
          canChooseAgent:
              SessionService.instance.currentUser?.role == UserRole.admin,
          initialAgentId: existing?.agentId ?? _scopeAgentId,
        ),
      ),
    );
    if (result == null) return;

    try {
      final isEdit = existing != null;
      final saved = isEdit
          ? await CashHandoverApiService.updateHandover(result)
          : await CashHandoverApiService.createHandover(result);
      await _loadData();
      ToastService.show(
        title: isEdit ? 'Handover updated' : 'Handover recorded',
        message: saved.agentName,
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Handover failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _verifyRecord(HandoverRecord record) async {
    try {
      final updated = record.copyWith(
        verified: !record.verified,
        receivedBy: !record.verified
            ? SessionService.instance.currentUser?.userId
            : null,
      );
      await CashHandoverApiService.updateHandover(updated);
      await _loadData();
      ToastService.show(
        title: record.verified ? 'Marked pending' : 'Marked verified',
        message: record.agentName,
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Could not update handover',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _deleteRecord(HandoverRecord record) async {
    try {
      await CashHandoverApiService.deleteHandover(record.id);
      await _loadData();
      ToastService.show(
        title: 'Handover deleted',
        message: record.agentName,
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Could not delete handover',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Widget _buildSheetFrame({required Widget child}) {
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final double maxSheetHeight = MediaQuery.of(context).size.height * 0.9;

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
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.handover,
      title: 'Cash Handover',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final narrow = _isNarrow(width);
          final tablet = _isTablet(width);

          // Adaptive horizontal padding: tighter on small phones,
          // roomier on tablets so content doesn't stretch edge-to-edge.
          final hPad = narrow ? 12.0 : (tablet ? 24.0 : 16.0);

          // Adaptive grid: 1 column on very narrow phones (folded phones,
          // iPhone SE in split view, etc.), 2 on regular phones, 3 on
          // tablets. Aspect ratio also loosens on narrow screens so the
          // currency values never get clipped.
          final crossAxisCount = narrow ? 1 : (tablet ? 3 : 2);
          final aspectRatio = narrow ? 2.6 : (tablet ? 1.8 : 1.5);

          return RefreshIndicator(
            onRefresh: _loadData,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _loadError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.kDanger),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                  onPressed: _loadData,
                                  child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
                        children: [
                          const SizedBox(height: 6),
                          const Text(
                            'Agents settle collected cash & UPI to the office — pending carries forward',
                            style: TextStyle(
                                color: AppColors.kTextMuted, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          if (_canCreateOrEdit)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                // Full width on narrow phones so the tap
                                // target is comfortably large; fixed
                                // width otherwise.
                                width: narrow ? double.infinity : 190,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _openRecordHandoverDialog(),
                                  icon: const Icon(Icons.add),
                                  label: const Text(
                                    'Record Handover',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: aspectRatio,
                            children: [
                              _StatCard(
                                icon: Icons.currency_exchange_rounded,
                                iconBg: const Color(0xFFDBEAFE),
                                iconColor: const Color(0xFF2563EB),
                                label: 'Total Collected',
                                value:
                                    formatIndianCurrency(_totalCollected),
                                subtitle: 'Today: ₹0',
                              ),
                              _StatCard(
                                icon: Icons.check_circle_outline_rounded,
                                iconBg: const Color(0xFFDCFCE7),
                                iconColor: AppColors.kSuccess,
                                label: 'Handed Over',
                                value:
                                    formatIndianCurrency(_totalHandedOver),
                              ),
                              _StatCard(
                                icon: Icons.account_balance_wallet_outlined,
                                iconBg: const Color(0xFFFEF3C7),
                                iconColor: AppColors.kWarning,
                                label: 'Pending',
                                value: formatIndianCurrency(_totalPending),
                                highlight: true,
                              ),
                              _StatCard(
                                icon: Icons.groups_rounded,
                                iconBg: const Color(0xFFFEE2E2),
                                iconColor: AppColors.kDanger,
                                label: 'Agents With Pending',
                                value: '$_agentsWithPending',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: EdgeInsets.all(narrow ? 14 : 20),
                            decoration: BoxDecoration(
                              color: AppColors.kSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.kBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Agent Settlement Position',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.kTextDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Pending = collected − handed over (runs continuously)',
                                  style: TextStyle(
                                      color: AppColors.kTextMuted,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                _SettlementTable(
                                  settlements: _settlements,
                                  narrow: narrow,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(narrow ? 14 : 20),
                            decoration: BoxDecoration(
                              color: AppColors.kSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.kBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Handover History',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.kTextDark,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_history.isEmpty)
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        'No handovers recorded yet.',
                                        style: TextStyle(
                                            color: AppColors.kTextMuted),
                                      ),
                                    ),
                                  )
                                else
                                  ..._history.map(
                                    (h) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4),
                                      child: _HistoryTile(
                                        record: h,
                                        canManage: _canManageRecords,
                                        narrow: narrow,
                                        onEdit: () =>
                                            _openRecordHandoverDialog(
                                                existing: h),
                                        onVerify: () => _verifyRecord(h),
                                        onDelete: () => _deleteRecord(h),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
          );
        },
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
    this.subtitle,
    this.highlight = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? AppColors.kGold : AppColors.kBorder,
          width: highlight ? 1.5 : 1,
        ),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.kTextMuted,
              fontSize: 13,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.kSuccess,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// SETTLEMENT TABLE
/// -----------------------------------------------------------------------
class _SettlementTable extends StatelessWidget {
  const _SettlementTable({required this.settlements, required this.narrow});
  final List<AgentSettlement> settlements;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    // On narrow phones a 4-column money table gets cramped and truncates
    // currency values. Instead of shrinking text to the point of being
    // unreadable, we give the table a fixed minimum width and let it
    // scroll horizontally — the user can swipe to see all columns.
    final table = _buildTable();
    if (!narrow) return table;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(width: 560, child: table),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Text('AGENT',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextMuted))),
              Expanded(
                  flex: 2,
                  child: Text('COLLECTED',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextMuted))),
              Expanded(
                  flex: 2,
                  child: Text('HANDED OVER',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextMuted))),
              Expanded(
                  flex: 2,
                  child: Text('PENDING',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextMuted))),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.kBorder),
        ...settlements.map((s) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(s.agentName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kTextDark)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(formatIndianCurrency(s.collected),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.kTextDark)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(formatIndianCurrency(s.handedOver),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.kSuccess)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(formatIndianCurrency(s.pending),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: s.pending > 0
                                    ? AppColors.kWarning
                                    : AppColors.kTextMuted)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.kBorder),
              ],
            )),
      ],
    );
  }
}

/// -----------------------------------------------------------------------
/// HISTORY TILE
/// -----------------------------------------------------------------------
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.record,
    required this.canManage,
    required this.narrow,
    required this.onEdit,
    required this.onVerify,
    required this.onDelete,
  });

  final HandoverRecord record;
  final bool canManage;
  final bool narrow;
  final VoidCallback onEdit;
  final VoidCallback onVerify;
  final VoidCallback onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Handover?',
      message:
          'This will permanently remove ${record.agentName}\'s handover record of ${formatIndianCurrency(record.totalAmount)}. This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed == true) {
      onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.handshake_outlined,
          color: AppColors.kWarning, size: 20),
    );

    final nameAndBadge = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.agentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextDark),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: record.verified
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            record.verified ? 'verified' : 'pending',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: record.verified
                    ? AppColors.kSuccess
                    : AppColors.kWarning),
          ),
        ),
      ],
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameAndBadge,
        const SizedBox(height: 6),
        Text(
          '${formatDate(record.date)} · ₹${record.cashAmount.round()} cash · ₹${record.upiAmount.round()} UPI',
          style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
        ),
        if (record.notes != null && record.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            record.notes!.trim(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.kTextDark,
              height: 1.35,
            ),
          ),
        ],
      ],
    );

    final amountRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(formatIndianCurrency(record.totalAmount),
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark)),
        if (!canManage)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: AppColors.kSuccess),
              SizedBox(width: 4),
              Text('Received',
                  style: TextStyle(fontSize: 12, color: AppColors.kSuccess)),
            ],
          ),
      ],
    );

    // Moved spacing/layout to span full width horizontally
    final actionButtons = canManage
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              alignment: WrapAlignment.end, // Aligns to the right
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: onVerify,
                  icon: Icon(
                    record.verified
                        ? Icons.undo_outlined
                        : Icons.verified_outlined,
                    size: 16,
                  ),
                  label: Text(record.verified ? 'Unverify' : 'Verify'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    if (narrow) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(child: details),
              ],
            ),
            const SizedBox(height: 12),
            amountRow,
            if (canManage) actionButtons,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(child: details),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatIndianCurrency(record.totalAmount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextDark,
                    ),
                  ),
                  if (!canManage) ...[
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 14, color: AppColors.kSuccess),
                        SizedBox(width: 4),
                        Text('Received',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.kSuccess)),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          // Actions placed outside the right-side column to lay out horizontally across the bottom
          if (canManage) actionButtons,
        ],
      ),
    );
  }
}



/// -----------------------------------------------------------------------
/// RECORD HANDOVER DIALOG
/// -----------------------------------------------------------------------
class _RecordHandoverDialog extends StatefulWidget {
  const _RecordHandoverDialog({
    required this.agents,
    this.existing,
    required this.canChooseAgent,
    this.initialAgentId,
  });

  final List<HandoverAgentOption> agents;
  final HandoverRecord? existing;
  final bool canChooseAgent;
  final String? initialAgentId;

  @override
  State<_RecordHandoverDialog> createState() => _RecordHandoverDialogState();
}

class _RecordHandoverDialogState extends State<_RecordHandoverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cashCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  HandoverAgentOption? _selectedAgent;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _cashCtrl.text = existing.cashAmount.toStringAsFixed(2);
      _upiCtrl.text = existing.upiAmount.toStringAsFixed(2);
      _notesCtrl.text = existing.notes ?? '';
      _date = existing.date;
    }

    final seededAgents = [...widget.agents];
    if (existing != null &&
        seededAgents.every((a) => a.id != existing.agentId) &&
        existing.agentId.isNotEmpty) {
      seededAgents.insert(
        0,
        HandoverAgentOption(
          id: existing.agentId,
          name: existing.agentName,
          active: true,
        ),
      );
    }

    HandoverAgentOption? pick(String? id) {
      if (id == null || id.isEmpty) return null;
      for (final agent in seededAgents) {
        if (agent.id == id) return agent;
      }
      return null;
    }

    _selectedAgent = pick(widget.initialAgentId) ??
        pick(existing?.agentId) ??
        (!widget.canChooseAgent && seededAgents.isNotEmpty
            ? seededAgents.first
            : null);
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _upiCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.kGold),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate() || _selectedAgent == null) return;
    final existing = widget.existing;

    final result = HandoverRecord(
      id: existing?.id ?? '',
      agentId: _selectedAgent!.id,
      agentName: _selectedAgent!.name,
      date: _date,
      cashAmount: double.tryParse(_cashCtrl.text) ?? 0,
      upiAmount: double.tryParse(_upiCtrl.text) ?? 0,
      verified: existing?.verified ?? false,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      receivedBy: existing?.receivedBy,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final dd = _date.day.toString().padLeft(2, '0');
    final mm = _date.month.toString().padLeft(2, '0');
    final yyyy = _date.year.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = _isNarrow(constraints.maxWidth);
        final hPad = narrow ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Record Handover',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close,
                          color: AppColors.kTextMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Global dropdown widget, used here in place of a
                // hand-rolled DropdownButtonFormField.
                AgentDropdown<HandoverAgentOption>(
                  items: widget.agents,
                  idOf: (a) => a.id,
                  labelOf: (a) => a.name,
                  isActiveOf: (a) => a.active,
                  value: _selectedAgent,
                  enabled: widget.canChooseAgent,
                  onChanged: (v) => setState(() => _selectedAgent = v),
                  validator: (v) => v == null ? 'Select an agent' : null,
                ),
                const SizedBox(height: 16),

                // Stack Cash/UPI fields vertically on very narrow screens
                // so each field keeps enough width to show its hint/value
                // without squeezing.
                if (narrow) ...[
                  _buildTextField('CASH AMOUNT', controller: _cashCtrl),
                  const SizedBox(height: 16),
                  _buildTextField('UPI AMOUNT', controller: _upiCtrl),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField('CASH AMOUNT',
                            controller: _cashCtrl),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField('UPI AMOUNT',
                            controller: _upiCtrl),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                _buildTextArea(
                  'NOTES',
                  controller: _notesCtrl,
                  hintText: 'Optional remarks',
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DATE *',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextMuted)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(isDense: true),
                        child: Text('$dd/$mm/$yyyy'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Buttons stretch full-width and stack on narrow screens
                // instead of squeezing onto one row.
                if (narrow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _handleSave,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(
                            widget.existing == null ? 'Record' : 'Save'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _handleSave,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(
                            widget.existing == null ? 'Record' : 'Save'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label,
      {required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(isDense: true, hintText: '0'),
        ),
      ],
    );
  }

  Widget _buildTextArea(
    String label, {
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(isDense: true, hintText: hintText),
        ),
      ],
    );
  }
}