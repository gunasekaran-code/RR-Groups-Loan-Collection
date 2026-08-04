// screens/funds/funds_screen.dart

import 'package:flutter/material.dart';
import '../../theme/confirm_dialog.dart';
import '../../theme/glass_toast.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../models/fund.dart';
import '../../models/user_role.dart';
import '../../services/customer_api_service.dart';
import '../../services/fund_api_service.dart';
import '../../services/session_service.dart';
import '../chit_groups/chit_groups_screen.dart' show formatIndianCurrency, formatDate;

class FundsScreen extends StatefulWidget {
  const FundsScreen({super.key});

  @override
  State<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends State<FundsScreen> {
  bool _isLoading = true;
  String? _loadError;

  List<Fund> _funds = [];
  FundsSummary? _summary;

  // Role gates:
  // - customer: read-only, sees only their own fund(s). No create/edit/delete/settle/collect.
  // - agent: field collector. Sees Collect + Settle in full only. No create/edit/delete, no stat cards.
  // - admin: full control. Create/edit/delete/settle. No Collect button (that's the agent's job).
  bool get _isCustomerView => SessionService.instance.role == UserRole.customer;
  bool get _isAgentView => SessionService.instance.role == UserRole.agent;
  bool get _isAdminView => SessionService.instance.role == UserRole.admin;

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
      final funds = await FundApiService.fetchAll();

      List<Fund> visibleFunds = funds;
      FundsSummary? summary;

      if (_isCustomerView) {
        final myCustomerId = SessionService.instance.currentUser?.customerId;
        visibleFunds = funds.where((f) => f.customerId == myCustomerId).toList();
        // Stat cards fall back to computing from the (already filtered) fund
        // list below, so we deliberately skip the global summary endpoint
        // for customers — it would otherwise show totals across all customers.
        summary = null;
      } else if (_isAdminView) {
        summary = await FundApiService.fetchSummary();
      }
      // Agents don't see stat cards at all, so we skip fetching a summary for them.

      if (!mounted) return;
      setState(() {
        _funds = visibleFunds;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
      ToastService.show(
        title: 'Failed to load funds',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

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

  Future<void> _openCreateDialog() async {
    final result = await showModalBottomSheet<Fund>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _sheetFrame(child: const _FundFormDialog()),
    );
    if (result == null) return;

    try {
      final created = await FundApiService.create(result);
      setState(() => _funds.insert(0, created));
      ToastService.show(
        title: 'Fund created',
        message: created.customerName,
        type: ToastType.success,
      );
      _loadData();
    } catch (e) {
      ToastService.show(title: 'Create failed', message: e.toString(), type: ToastType.error);
    }
  }

  Future<void> _openEditDialog(Fund fund) async {
    final result = await showModalBottomSheet<Fund>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _sheetFrame(child: _FundFormDialog(existing: fund)),
    );
    if (result == null) return;

    try {
      final updated = await FundApiService.update(fund.id, result);
      if (!mounted) return;
      setState(() {
        final idx = _funds.indexWhere((f) => f.id == fund.id);
        if (idx != -1) _funds[idx] = updated;
      });
      ToastService.show(
        title: 'Fund updated',
        message: updated.customerName,
        type: ToastType.success,
      );
      _loadData();
    } catch (e) {
      ToastService.show(title: 'Update failed', message: e.toString(), type: ToastType.error);
    }
  }

  Future<void> _openSettleDialog(Fund fund) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _sheetFrame(child: _SettleFundDialog(fund: fund)),
    );
    if (result != true) return;
    _loadData();
    ToastService.show(
      title: 'Fund settled',
      message: fund.customerName,
      type: ToastType.success,
    );
  }

  Future<void> _openCollectDialog(Fund fund) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _sheetFrame(child: _CollectDialog(fund: fund)),
    );
    if (result != true) return;
    _loadData();
    ToastService.show(
      title: 'Collection recorded',
      message: fund.customerName,
      type: ToastType.success,
    );
  }

  /// Agent version of "settle in full". The admin _SettleFundDialog posts
  /// action/payment_method/settlement_date, which the backend's FundController
  /// rejects for agents (403 "Agents can only record fund collections"). Agents
  /// are allow-listed to exactly `collected_amount` + `status`, so we settle
  /// by collecting the full remaining balance and marking the fund matured —
  /// the same shape as a normal Collect, just for the full amount.
  Future<void> _openAgentSettleDialog(Fund fund) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Settle Fund in Full',
      message:
          'Collect the remaining ${formatIndianCurrency(fund.remainingToSettle)} for "${fund.code}" (${fund.customerName}) now and mark it matured?',
      confirmLabel: 'Settle Now',
      confirmButtonColor: AppColors.kSuccess,
    );
    if (confirmed != true || !mounted) return;

    try {
      await FundApiService.recordCollection(
        fund.id,
        collectedAmount: fund.totalDeposit,
        status: FundStatus.matured.label,
      );
      if (!mounted) return;
      _loadData();
      ToastService.show(
        title: 'Fund settled',
        message: fund.customerName,
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(title: 'Settlement failed', message: e.toString(), type: ToastType.error);
    }
  }

  Future<void> _openPassbook(Fund fund) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _sheetFrame(child: _PassbookDialog(fund: fund)),
    );
  }

  Future<void> _confirmDelete(Fund fund) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Fund',
      message:
          'Are you sure you want to delete "${fund.code}" for ${fund.customerName}? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true || !mounted) return;

    try {
      await FundApiService.delete(fund.id);
      setState(() => _funds.removeWhere((f) => f.id == fund.id));
      ToastService.show(title: 'Fund deleted', message: fund.customerName, type: ToastType.warning);
    } catch (e) {
      ToastService.show(title: 'Delete failed', message: e.toString(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.funds,
      title: 'Funds',
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!, style: const TextStyle(color: AppColors.kDanger)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'Weekly-deposit savings schemes with a maturity bonus',
                        style: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      // Creating funds is an admin-only action.
                      if (_isAdminView) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 150,
                            child: ElevatedButton.icon(
                              onPressed: _openCreateDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Fund',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Stat cards are hidden for agents — they're out in the field
                      // collecting, not reviewing portfolio-wide totals.
                      if (!_isAgentView) ...[
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _StatCard(
                              icon: Icons.savings_outlined,
                              iconBg: const Color(0xFFFEF3C7),
                              iconColor: AppColors.kWarning,
                              label: 'Total Funds',
                              value: '${_summary?.totalFunds ?? _funds.length}',
                            ),
                            _StatCard(
                              icon: Icons.trending_up_rounded,
                              iconBg: const Color(0xFFDCFCE7),
                              iconColor: AppColors.kSuccess,
                              label: 'Active',
                              value:
                                  '${_summary?.activeFunds ?? _funds.where((f) => f.status == FundStatus.active).length}',
                            ),
                            _StatCard(
                              icon: Icons.card_giftcard_rounded,
                              iconBg: const Color(0xFFEDE9FE),
                              iconColor: const Color(0xFF7C3AED),
                              label: 'Maturity Payout',
                              value: formatIndianCurrency(_summary?.maturityPayoutTotal ??
                                  _funds.fold(0.0, (s, f) => s + f.maturityPayout)),
                            ),
                            _StatCard(
                              icon: Icons.account_balance_wallet_outlined,
                              iconBg: const Color(0xFFFEF3C7),
                              iconColor: AppColors.kGold,
                              label: 'Collected',
                              value: formatIndianCurrency(_summary?.collectedTotal ??
                                  _funds.fold(0.0, (s, f) => s + f.depositedAmount)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_funds.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              _isCustomerView ? 'You have no funds yet.' : 'No funds yet.',
                              style: const TextStyle(color: AppColors.kTextMuted),
                            ),
                          ),
                        )
                      else
                        ..._funds.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _FundCard(
                              fund: f,
                              isAdmin: _isAdminView,
                              isAgent: _isAgentView,
                              isCustomer: _isCustomerView,
                              onPassbook: () => _openPassbook(f),
                              onDelete: () => _confirmDelete(f),
                              onSettle: () => _openSettleDialog(f),
                              onAgentSettle: () => _openAgentSettleDialog(f),
                              onEdit: () => _openEditDialog(f),
                              onCollect: () => _openCollectDialog(f),
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
      padding: const EdgeInsets.all(16),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// FUND CARD
/// -----------------------------------------------------------------------
class _FundCard extends StatelessWidget {
  const _FundCard({
    required this.fund,
    required this.onPassbook,
    required this.onDelete,
    required this.onSettle,
    required this.onAgentSettle,
    required this.onEdit,
    required this.onCollect,
    this.isAdmin = false,
    this.isAgent = false,
    this.isCustomer = false,
  });

  final Fund fund;
  final VoidCallback onPassbook;
  final VoidCallback onDelete;
  final VoidCallback onSettle;
  final VoidCallback onAgentSettle;
  final VoidCallback onEdit;
  final VoidCallback onCollect;
  final bool isAdmin;
  final bool isAgent;
  final bool isCustomer;

  Color get _statusBg {
    switch (fund.status) {
      case FundStatus.active:
        return const Color(0xFFFEF3C7);
      case FundStatus.matured:
        return const Color(0xFFDCFCE7);
      case FundStatus.settled:
        return const Color(0xFFE5E7EB);
    }
  }

  Color get _statusFg {
    switch (fund.status) {
      case FundStatus.active:
        return AppColors.kWarning;
      case FundStatus.matured:
        return AppColors.kSuccess;
      case FundStatus.settled:
        return AppColors.kTextMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (fund.depositedPercent / 100).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.savings_outlined,
                    color: AppColors.kGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fund.customerName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text(fund.code,
                        style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(999)),
                child: Text(fund.status.label,
                    style: TextStyle(color: _statusFg, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'WEEKLY', value: formatIndianCurrency(fund.weeklyAmount)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(label: 'WEEKS', value: '${fund.numberOfWeeks}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'BONUS',
                  value: formatIndianCurrency(fund.maturityBonus),
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Maturity payout',
                    style: TextStyle(color: AppColors.kTextDark, fontSize: 14)),
                Text(formatIndianCurrency(fund.maturityPayout),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.kTextDark)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deposited ${formatIndianCurrency(fund.depositedAmount)} / ${formatIndianCurrency(fund.totalDeposit)}',
                style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
              ),
              Text('${fund.depositedPercent.round()}%',
                  style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1EFE8),
              valueColor: const AlwaysStoppedAnimation(AppColors.kGold),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.kTextMuted),
              const SizedBox(width: 6),
              Text(formatDate(fund.startDate),
                  style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.card_giftcard_outlined, size: 14, color: AppColors.kTextMuted),
              const SizedBox(width: 6),
              Text(formatDate(fund.maturityDate),
                  style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
            ],
          ),
          const Divider(height: 28, color: AppColors.kBorder),
          _buildActions(),
        ],
      ),
    );
  }

  /// Role-specific action row:
  /// - customer: Passbook only (read-only).
  /// - agent: Passbook + Collect, plus Settle in full when active. No edit/delete.
  /// - admin: Passbook + Edit + Delete, plus Settle in full when active. No Collect.
  Widget _buildActions() {
    if (isCustomer) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPassbook,
          icon: const Icon(Icons.menu_book_outlined, size: 18),
          label: const Text('Passbook'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    if (isAgent) {
      // Agents can settle in full — but via the same allow-listed
      // (collected_amount + status) shape as Collect, not the admin dialog's
      // action/payment_method/settlement_date payload, which 403s for this role.
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPassbook,
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: const Text('Passbook'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (fund.status == FundStatus.active) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCollect,
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Collect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (fund.status == FundStatus.active) ...[
            const SizedBox(height: 10),
            _settleBanner(onAgentSettle),
          ],
        ],
      );
    }

    // Admin
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPassbook,
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('Passbook'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _IconButtonSquare(icon: Icons.edit_outlined, onTap: onEdit),
            const SizedBox(width: 8),
            _IconButtonSquare(
              icon: Icons.delete_outline_rounded,
              color: AppColors.kDanger,
              onTap: onDelete,
            ),
          ],
        ),
        if (fund.status == FundStatus.active) ...[
          const SizedBox(height: 10),
          _settleBanner(onSettle),
        ],
      ],
    );
  }

  Widget _settleBanner(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 18, color: AppColors.kSuccess),
            const SizedBox(width: 8),
            Text(
              'Settle in full · ${formatIndianCurrency(fund.remainingToSettle)} left',
              style: const TextStyle(
                  color: AppColors.kSuccess, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: highlight ? AppColors.kWarning : AppColors.kTextMuted)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: highlight ? AppColors.kWarning : AppColors.kTextDark)),
          ),
        ],
      ),
    );
  }
}

class _IconButtonSquare extends StatelessWidget {
  const _IconButtonSquare({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color ?? AppColors.kTextDark),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// CREATE / EDIT FUND FORM
/// -----------------------------------------------------------------------
class _FundFormDialog extends StatefulWidget {
  const _FundFormDialog({this.existing});

  /// When non-null, the dialog opens in edit mode, prefilled from this fund.
  final Fund? existing;

  @override
  State<_FundFormDialog> createState() => _FundFormDialogState();
}

class _FundFormDialogState extends State<_FundFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weeklyCtrl;
  late final TextEditingController _weeksCtrl;
  late final TextEditingController _bonusCtrl;
  late DateTime _startDate;
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  bool _isLoadingCustomers = true;

  final List<Map<String, String>> _customers = [];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _weeklyCtrl = TextEditingController(
        text: existing != null ? existing.weeklyAmount.round().toString() : '100');
    _weeksCtrl = TextEditingController(
        text: existing != null ? existing.numberOfWeeks.toString() : '50');
    _bonusCtrl = TextEditingController(
        text: existing != null ? existing.maturityBonus.round().toString() : '1000');
    _startDate = existing?.startDate ?? DateTime.now();
    _selectedCustomerId = existing?.customerId;
    _selectedCustomerName = existing?.customerName;
    _loadCustomers();
  }

  @override
  void dispose() {
    _weeklyCtrl.dispose();
    _weeksCtrl.dispose();
    _bonusCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final api = CustomerApiService();
      final list = await api.fetchAllLite();
      if (!mounted) return;
      setState(() {
        _customers.clear();
        _customers.addAll(list);
        _isLoadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCustomers = false;
      });
      ToastService.show(
        title: 'Could not load customers',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  double get _weekly => double.tryParse(_weeklyCtrl.text) ?? 0;
  int get _weeks => int.tryParse(_weeksCtrl.text) ?? 0;
  double get _bonus => double.tryParse(_bonusCtrl.text) ?? 0;
  double get _totalDeposit => _weekly * _weeks;
  double get _totalPayout => _totalDeposit + _bonus;
  DateTime get _maturityDate => DateTime(
      _startDate.year, _startDate.month, _startDate.day + (_weeks * 7));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.kGold)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ToastService.show(
          title: 'Select a customer', message: 'Please choose a customer', type: ToastType.error);
      return;
    }

    final existing = widget.existing;
    final fund = Fund(
      id: existing?.id ?? '',
      code: existing?.code ?? 'FND-${DateTime.now().millisecondsSinceEpoch}',
      customerId: _selectedCustomerId!,
      customerName: _selectedCustomerName ?? '',
      status: existing?.status ?? FundStatus.active,
      weeklyAmount: _weekly,
      numberOfWeeks: _weeks,
      maturityBonus: _bonus,
      startDate: _startDate,
      maturityDate: _maturityDate,
      depositedAmount: existing?.depositedAmount ?? 0,
      entriesPaid: existing?.entriesPaid ?? 0,
    );

    Navigator.of(context).pop(fund);
  }

  @override
  Widget build(BuildContext context) {
    final dd = _startDate.day.toString().padLeft(2, '0');
    final mm = _startDate.month.toString().padLeft(2, '0');
    final yyyy = _startDate.year.toString();

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
                Expanded(
                  child: Text(_isEditing ? 'Edit Fund' : 'Add Fund',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
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
            const Text('CUSTOMER',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.kTextMuted)),
            const SizedBox(height: 8),
            _isLoadingCustomers
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedCustomerId,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(isDense: true, hintText: 'Select a customer...'),
                    items: _customers
                        .map((c) => DropdownMenuItem(
                              value: c['id'],
                              child: Text(c['name'] ?? 'Unknown'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedCustomerId = v;
                      _selectedCustomerName = _customers
                          .firstWhere((c) => c['id'] == v)['name'];
                    }),
                  ),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Column(
                children: [
                  _responsiveRow(
                    isNarrow,
                    _buildTextField('WEEKLY AMOUNT', controller: _weeklyCtrl, icon: Icons.currency_rupee),
                    _buildTextField('NUMBER OF WEEKS', controller: _weeksCtrl, icon: Icons.event_repeat),
                  ),
                  const SizedBox(height: 16),
                  _responsiveRow(
                    isNarrow,
                    _buildTextField('MATURITY BONUS', controller: _bonusCtrl, icon: Icons.card_giftcard),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('START DATE',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.kTextMuted)),
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
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                      label: 'Deposited (₹${_weekly.round()} x $_weeks weeks)',
                      value: formatIndianCurrency(_totalDeposit)),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Maturity bonus',
                    value: '+ ${formatIndianCurrency(_bonus)}',
                    valueColor: AppColors.kGold,
                  ),
                  const Divider(height: 20, color: AppColors.kBorder),
                  _SummaryRow(
                    label: 'Total maturity payout',
                    value: formatIndianCurrency(_totalPayout),
                    labelColor: AppColors.kSuccess,
                    valueColor: AppColors.kSuccess,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('Matures on ${formatDate(_maturityDate)}',
                  style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleSubmit,
                  icon: Icon(_isEditing ? Icons.save_outlined : Icons.add_circle_outline),
                  label: Text(_isEditing ? 'Save Changes' : 'Create Fund'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _responsiveRow(bool isNarrow, Widget a, Widget b) {
    if (isNarrow) return Column(children: [a, const SizedBox(height: 16), b]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)],
    );
  }

  Widget _buildTextField(String label,
      {required TextEditingController controller, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.kTextMuted) : null,
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: labelColor ?? AppColors.kTextMuted,
                fontSize: 14,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? AppColors.kTextDark,
                fontSize: bold ? 18 : 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }
}

/// -----------------------------------------------------------------------
/// RECORD COLLECTION (agent — partial/weekly payment)
/// -----------------------------------------------------------------------
class _CollectDialog extends StatefulWidget {
  const _CollectDialog({required this.fund});
  final Fund fund;

  @override
  State<_CollectDialog> createState() => _CollectDialogState();
}

class _CollectDialogState extends State<_CollectDialog> {
  late final TextEditingController _amountCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final fund = widget.fund;
    final suggested = fund.weeklyAmount > 0
        ? fund.weeklyAmount.clamp(0, fund.remainingToSettle == 0 ? fund.weeklyAmount : fund.remainingToSettle)
        : fund.remainingToSettle;
    _amountCtrl = TextEditingController(text: suggested.round().toString());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRecord() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ToastService.show(
        title: 'Invalid amount',
        message: 'Enter a collection amount greater than 0',
        type: ToastType.error,
      );
      return;
    }

    final fund = widget.fund;
    // Backend allow-lists agent PATCH bodies to exactly `collected_amount`
    // and `status` — no `amount`/`payment_method`/`payment_date` fields are
    // accepted, so we compute the new running total and status here and
    // send only those two fields. Clamp so a stray over-payment can't push
    // collected_amount past the fund's total deposit target.
    final newCollected = (fund.depositedAmount + amount)
        .clamp(0, fund.totalDeposit)
        .toDouble();
    final newStatus = newCollected >= fund.totalDeposit
        ? FundStatus.matured.label
        : fund.status.label;

    setState(() => _isSubmitting = true);
    try {
      await FundApiService.recordCollection(
        widget.fund.id,
        collectedAmount: newCollected,
        status: newStatus,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ToastService.show(title: 'Collection failed', message: e.toString(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fund = widget.fund;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                    color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.savings_outlined, color: AppColors.kGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Record Collection',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text('${fund.code} · ${fund.customerName}',
                        style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('COLLECTED',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.kTextMuted)),
                      const SizedBox(height: 4),
                      Text(formatIndianCurrency(fund.depositedAmount),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.kTextDark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('REMAINING',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.kSuccess)),
                      const SizedBox(height: 4),
                      Text(formatIndianCurrency(fund.remainingToSettle),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.kSuccess)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('COLLECTION AMOUNT',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.kTextMuted)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.currency_rupee, size: 18, color: AppColors.kTextMuted),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Adds this amount to the fund's collected total. "
            "Auto-marks the fund matured once the full deposit target is collected.",
            style: TextStyle(color: AppColors.kTextMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleRecord,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.payments_outlined),
                label: const Text('Record'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// SETTLE FUND IN FULL
/// -----------------------------------------------------------------------
class _SettleFundDialog extends StatefulWidget {
  const _SettleFundDialog({required this.fund});
  final Fund fund;

  @override
  State<_SettleFundDialog> createState() => _SettleFundDialogState();
}

class _SettleFundDialogState extends State<_SettleFundDialog> {
  String _paymentMethod = 'Cash';
  DateTime _settlementDate = DateTime.now();
  bool _isSubmitting = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _settlementDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.kGold)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _settlementDate = picked);
  }

  Future<void> _handleSettle() async {
    setState(() => _isSubmitting = true);
    try {
      await FundApiService.settleInFull(
        widget.fund.id,
        paymentMethod: _paymentMethod,
        settlementDate: _settlementDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ToastService.show(title: 'Settlement failed', message: e.toString(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fund = widget.fund;
    final dd = _settlementDate.day.toString().padLeft(2, '0');
    final mm = _settlementDate.month.toString().padLeft(2, '0');
    final yyyy = _settlementDate.year.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                    color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.savings_outlined, color: AppColors.kGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Settle Fund in Full',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text('${fund.code} · ${fund.customerName}',
                        style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
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
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DEPOSITED',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.kTextMuted)),
                      const SizedBox(height: 4),
                      Text(formatIndianCurrency(fund.depositedAmount),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.kTextDark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('REMAINING TO SETTLE',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.kWarning)),
                      const SizedBox(height: 4),
                      Text(formatIndianCurrency(fund.remainingToSettle),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.kWarning)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;
            final methodField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PAYMENT METHOD',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.kTextMuted)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v ?? 'Cash'),
                ),
              ],
            );
            final dateField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SETTLEMENT DATE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.kTextMuted)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(isDense: true),
                    child: Text('$dd-$mm-$yyyy'),
                  ),
                ),
              ],
            );
            if (isNarrow) {
              return Column(children: [methodField, const SizedBox(height: 16), dateField]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: methodField),
                const SizedBox(width: 16),
                Expanded(child: dateField),
              ],
            );
          }),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _SummaryRow(label: 'Total deposit', value: formatIndianCurrency(fund.totalDeposit)),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: '🎁 Maturity bonus',
                  value: '+ ${formatIndianCurrency(fund.maturityBonus)}',
                  valueColor: AppColors.kGold,
                ),
                const Divider(height: 20, color: AppColors.kBorder),
                _SummaryRow(
                  label: 'Payout to customer',
                  value: formatIndianCurrency(fund.maturityPayout),
                  labelColor: AppColors.kSuccess,
                  valueColor: AppColors.kSuccess,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Collects the remaining balance now, credits the full bonus, and marks the fund matured — even though all weeks aren\'t finished.',
            style: TextStyle(color: AppColors.kTextMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleSettle,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Settle Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// PASSBOOK
/// -----------------------------------------------------------------------
class _PassbookDialog extends StatefulWidget {
  const _PassbookDialog({required this.fund});
  final Fund fund;

  @override
  State<_PassbookDialog> createState() => _PassbookDialogState();
}

class _PassbookDialogState extends State<_PassbookDialog> {
  bool _isLoading = true;
  String? _error;

  /// Raw rows returned by the backend — only itemized fund_payments rows.
  List<FundEntry> _paidEntries = [];

  List<FundEntry> _schedule = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await FundApiService.fetchPassbook(widget.fund.id);
      if (!mounted) return;
      setState(() {
        _paidEntries = entries;
        _schedule = _buildSchedule(widget.fund, entries);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  static List<FundEntry> _buildSchedule(Fund fund, List<FundEntry> paidEntries) {
    final byWeek = <int, FundEntry>{for (final e in paidEntries) e.week: e};
    final totalWeeks = fund.numberOfWeeks > 0 ? fund.numberOfWeeks : paidEntries.length;

    // Agent "Collect" / "Settle in full" only PATCH funds.collected_amount +
    // funds.status — they never insert a fund_payments row, since the
    // backend allow-lists agent PATCH bodies to those two fields only. So
    // paidEntries (the real fund_payments rows) under-counts whenever an
    // agent has collected anything. fund.depositedAmount is the source of
    // truth (it's driven straight off funds.collected_amount), so we
    // reconcile: any gap between the sum of real payment rows and
    // depositedAmount is un-itemized agent collection, and we synthesize it
    // as paid weeks (oldest un-recorded week first) so ENTRIES/DEPOSITED in
    // the passbook always foot to the same total as the fund card.
    final recordedSum = paidEntries.fold<double>(0, (s, e) => s + e.amount);
    double unallocated = fund.depositedAmount - recordedSum;
    if (unallocated < 0) unallocated = 0; // defensive; shouldn't happen

    final schedule = <FundEntry>[];
    for (int week = 1; week <= totalWeeks; week++) {
      final existing = byWeek[week];
      if (existing != null) {
        schedule.add(existing);
        continue;
      }

      if (unallocated > 0) {
        final amt = unallocated >= fund.weeklyAmount ? fund.weeklyAmount : unallocated;
        unallocated -= amt;
        schedule.add(FundEntry(
          week: week,
          date: fund.startDate.add(Duration(days: 7 * (week - 1))),
          amount: amt,
          method: 'Collected', // itemized method/date unknown — recorded via agent Collect
          paid: true,
        ));
      } else {
        schedule.add(FundEntry(
          week: week,
          date: fund.startDate.add(Duration(days: 7 * (week - 1))),
          amount: fund.weeklyAmount,
          method: null,
          paid: false,
        ));
      }
    }
    return schedule;
  }

  static const _weekdayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // ENTRIES now counts real + synthesized paid weeks, so a fund settled or
  // partially collected by an agent still reads correctly (e.g. 12/50)
  // instead of the stale 0/50 that fund_payments-only data gave.
  int get _paidCount => _schedule.where((e) => e.paid).length;

  // DEPOSITED reads straight off fund.depositedAmount — the real
  // funds.collected_amount — rather than summing fund_payments rows, so it
  // can never drift from the number shown on the fund card / stat cards.
  double get _paidSum => widget.fund.depositedAmount;

  FundEntry? get _nextDue {
    for (final e in _schedule) {
      if (!e.paid) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fund = widget.fund;
    final next = _nextDue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                    color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.savings_outlined, color: AppColors.kGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Passbook',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text('${fund.code} · ${fund.customerName}',
                        style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
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
          const SizedBox(height: 20),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(_error!, style: const TextStyle(color: AppColors.kDanger)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                    Expanded(
                  child: _PassbookStat(
                      label: 'DEPOSITED',
                      // Use actual paid entries to compute deposited amount
                      value: formatIndianCurrency(_paidSum),
                      bg: const Color(0xFFDCFCE7),
                      fg: AppColors.kSuccess),
                    ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PassbookStat(
                      label: 'TO DEPOSIT',
                      // Remaining based on total deposit minus actual paid sum
                      value: formatIndianCurrency(fund.totalDeposit - _paidSum),
                      bg: const Color(0xFFF3F4F6),
                      fg: AppColors.kTextDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PassbookStat(
                      // Driven by actual backend fund_payments rows, not the
                      // (often-unset) entriesPaid field on Fund — so a fund
                      // settled in one shot still reads correctly, e.g. 50/50
                      // rather than a stale 0/50.
                          label: 'ENTRIES',
                          value: '$_paidCount / ${fund.numberOfWeeks}',
                      bg: const Color(0xFFFEF3C7),
                      fg: AppColors.kWarning),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _SummaryRow(
                      label: 'Total deposit (₹${fund.weeklyAmount.round()} x ${fund.numberOfWeeks} weeks)',
                      value: formatIndianCurrency(fund.totalDeposit)),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: '🎁 Maturity bonus (at settlement)',
                    value: '+ ${formatIndianCurrency(fund.maturityBonus)}',
                    valueColor: AppColors.kGold,
                  ),
                  const Divider(height: 20, color: AppColors.kBorder),
                  _SummaryRow(
                    label: 'Maturity payout',
                    value: formatIndianCurrency(fund.maturityPayout),
                    labelColor: AppColors.kSuccess,
                    valueColor: AppColors.kSuccess,
                    bold: true,
                  ),
                ],
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB)),
                          children: [
                            const TextSpan(text: 'Next deposit due · '),
                            TextSpan(
                              text:
                                  '${formatDate(next.date)} · Week ${next.week} · ${formatIndianCurrency(next.amount)}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Text('WK',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.kTextMuted))),
                  Expanded(
                      flex: 3,
                      child: Text('DATE · METHOD',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.kTextMuted))),
                  Expanded(
                      flex: 2,
                      child: Text('AMOUNT · BALANCE',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.kTextMuted))),
                ],
              ),
            ),
            const Divider(height: 16, color: AppColors.kBorder),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _schedule.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.kBorder),
                itemBuilder: (context, i) {
                  final e = _schedule[i];
                  final isNext = next != null && e.week == next.week;

                  // Running balance = sum of amounts actually paid up to and
                  // including this week (paid rows only — pending weeks don't
                  // contribute, matching "Bal ₹x" only appearing on paid rows).
                  double balance = 0;
                  for (final row in _schedule.take(i + 1)) {
                    if (row.paid) balance += row.amount;
                  }

                  final weekdayLabel = _weekdayAbbr[(e.date.weekday - 1).clamp(0, 6)];
                  final dateLabel = e.paid ? formatDate(e.date) : '${formatDate(e.date)} ($weekdayLabel)';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: e.paid ? const Color(0xFFFEF3C7) : null,
                              border: Border.all(
                                color: isNext
                                    ? const Color(0xFF2563EB)
                                    : e.paid
                                        ? Colors.transparent
                                        : AppColors.kBorder,
                                width: isNext ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${e.week}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isNext
                                        ? const Color(0xFF2563EB)
                                        : e.paid
                                            ? AppColors.kGold
                                            : AppColors.kTextMuted)),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateLabel,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isNext ? const Color(0xFF2563EB) : AppColors.kTextDark)),
                              Text(
                                isNext ? 'Next due' : (e.paid ? (e.method ?? 'Paid') : ''),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isNext ? const Color(0xFF2563EB) : AppColors.kTextMuted),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                e.paid
                                    ? '+ ${formatIndianCurrency(e.amount)}'
                                    : formatIndianCurrency(e.amount),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: e.paid ? AppColors.kSuccess : AppColors.kTextDark),
                              ),
                              Text(
                                e.paid ? 'Bal ${formatIndianCurrency(balance)}' : 'Pending',
                                style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassbookStat extends StatelessWidget {
  const _PassbookStat({required this.label, required this.value, required this.bg, required this.fg});
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
          ),
        ],
      ),
    );
  }
}