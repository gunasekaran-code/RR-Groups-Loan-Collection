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
import '../../services/agent_api_service.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

String formatIndianCurrency(double? amount) {
  if (amount == null) return '₹0';
  final format =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  return format.format(amount);
}

String formatDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('dd MMM yyyy').format(date);
}

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
  List<Map<String, String>> _customers = [];
  List<Map<String, String>> _agents = [];

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
      final customerRows = await CustomerApiService().fetchAllLite();
      final agentRows = await AgentApiService.instance.getAgents();
      final agents = agentRows
          .where(
              (row) => (row['role']?.toString().toLowerCase() ?? '') == 'agent')
          .map((row) => <String, String>{
                'id': row['id'].toString(),
                'name': (row['name'] ?? row['full_name'] ?? '').toString(),
              })
          .where((row) => row['name']!.isNotEmpty)
          .toList();

      List<Fund> visibleFunds = funds;
      FundsSummary? summary;

      if (_isCustomerView) {
        final myCustomerId = SessionService.instance.currentUser?.customerId;
        visibleFunds =
            funds.where((f) => f.customerId == myCustomerId).toList();
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
        _customers = customerRows;
        _agents = agents;
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
        title: AppLocalizations.of(context).fundToastLoadFailedTitle,
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
            BoxShadow(
                color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
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
      builder: (context) => _sheetFrame(
          child: _FundFormDialog(customers: _customers, agents: _agents)),
    );
    if (result == null) return;
    final l10n = AppLocalizations.of(context);

    try {
      final created = await FundApiService.create(result);
      setState(() => _funds.insert(0, created));
      ToastService.show(
        title: l10n.fundToastCreatedTitle,
        message: created.customerName,
        type: ToastType.success,
      );
      _loadData();
    } catch (e) {
      ToastService.show(
          title: l10n.fundToastCreateFailedTitle,
          message: e.toString(),
          type: ToastType.error);
    }
  }

  Future<void> _openEditDialog(Fund fund) async {
    final result = await showModalBottomSheet<Fund>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _sheetFrame(
          child: _FundFormDialog(
              existing: fund, customers: _customers, agents: _agents)),
    );
    if (result == null) return;
    final l10n = AppLocalizations.of(context);

    try {
      final updated = await FundApiService.update(fund.id, result);
      if (!mounted) return;
      setState(() {
        final idx = _funds.indexWhere((f) => f.id == fund.id);
        if (idx != -1) _funds[idx] = updated;
      });
      ToastService.show(
        title: l10n.fundToastUpdatedTitle,
        message: updated.customerName,
        type: ToastType.success,
      );
      _loadData();
    } catch (e) {
      ToastService.show(
          title: l10n.fundToastUpdateFailedTitle,
          message: e.toString(),
          type: ToastType.error);
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
      title: AppLocalizations.of(context).fundToastSettledTitle,
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
      title: AppLocalizations.of(context).fundToastCollectionRecordedTitle,
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.fundAgentSettleDialogTitle,
      message: l10n.fundAgentSettleDialogMessage(
          formatIndianCurrency(fund.remainingToSettle),
          fund.code,
          fund.customerName),
      confirmLabel: l10n.fundAgentSettleDialogConfirm,
      confirmButtonColor: AppColors.kSuccess,
    );
    if (confirmed != true || !mounted) return;

    try {
      final remaining = fund.remainingToSettle;
      await FundApiService.recordCollection(
        fund.id,
        collectedAmount: fund.totalDeposit,
        status: FundStatus.matured.label,
        paymentAmount: remaining > 0 ? remaining : 0,
        paymentMethod: 'Cash',
        paymentDate: DateTime.now(),
        fundCode: fund.code,
        customerId: fund.customerId,
        customerName: fund.customerName,
      );
      if (!mounted) return;
      _loadData();
      ToastService.show(
        title: l10n.fundToastSettledTitle,
        message: fund.customerName,
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
          title: l10n.fundToastSettlementFailedTitle,
          message: e.toString(),
          type: ToastType.error);
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.fundDeleteDialogTitle,
      message: l10n.fundDeleteDialogMessage(fund.code, fund.customerName),
      confirmLabel: l10n.fundDeleteDialogConfirm,
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true || !mounted) return;

    try {
      await FundApiService.delete(fund.id);
      setState(() => _funds.removeWhere((f) => f.id == fund.id));
      ToastService.show(
          title: l10n.fundToastDeletedTitle,
          message: fund.customerName,
          type: ToastType.warning);
    } catch (e) {
      ToastService.show(
          title: l10n.fundToastDeleteFailedTitle,
          message: e.toString(),
          type: ToastType.error);
    }
  }

  final TextEditingController _searchCtrl = TextEditingController();

  List<Fund> get _filteredFunds {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _funds;

    return _funds.where((fund) {
      return fund.customerName.toLowerCase().contains(query) ||
          fund.code.toLowerCase().contains(query) ||
          fund.customerId.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visibleFunds = _filteredFunds;
    final hasSearchQuery = _searchCtrl.text.trim().isNotEmpty;

    return AppShell(
      currentRoute: AppRoutes.funds,
      title: l10n.fundsScreenTitle,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!,
                            style: const TextStyle(color: AppColors.kDanger)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _loadData,
                            child: Text(l10n.fundRetryButton)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        l10n.fundsScreenSubtitle,
                        style: const TextStyle(
                            color: AppColors.kTextMuted, fontSize: 14),
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
                              label: Text(l10n.fundCreateButton,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: AppColors.kSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.kBorder)),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: l10n.fundSearchHint,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: hasSearchQuery
                                ? IconButton(
                                    tooltip: l10n.fundSearchClearTooltip,
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.clear, size: 20),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              label: l10n.fundStatTotalFunds,
                              value: '${_summary?.totalFunds ?? _funds.length}',
                            ),
                            _StatCard(
                              icon: Icons.trending_up_rounded,
                              iconBg: const Color(0xFFDCFCE7),
                              iconColor: AppColors.kSuccess,
                              label: l10n.fundStatActive,
                              value:
                                  '${_summary?.activeFunds ?? _funds.where((f) => f.status == FundStatus.active).length}',
                            ),
                            _StatCard(
                              icon: Icons.card_giftcard_rounded,
                              iconBg: const Color(0xFFEDE9FE),
                              iconColor: const Color(0xFF7C3AED),
                              label: l10n.fundStatMaturityPayout,
                              value: formatIndianCurrency(_summary
                                      ?.maturityPayoutTotal ??
                                  _funds.fold<double>(0.0,
                                      (double s, f) => s + f.maturityPayout)),
                            ),
                            _StatCard(
                              icon: Icons.account_balance_wallet_outlined,
                              iconBg: const Color(0xFFFEF3C7),
                              iconColor: AppColors.kGold,
                              label: l10n.fundStatCollected,
                              value: formatIndianCurrency(_summary
                                      ?.collectedTotal ??
                                  _funds.fold<double>(0.0,
                                      (double s, f) => s + f.depositedAmount)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (visibleFunds.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              hasSearchQuery
                                  ? l10n.fundEmptySearch
                                  : _isCustomerView
                                      ? l10n.fundEmptyCustomer
                                      : l10n.fundEmptyDefault,
                              style:
                                  const TextStyle(color: AppColors.kTextMuted),
                            ),
                          ),
                        )
                      else
                        ...visibleFunds.map(
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
    final l10n = AppLocalizations.of(context);
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text(fund.code,
                        style: const TextStyle(
                            color: AppColors.kTextMuted, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _statusBg, borderRadius: BorderRadius.circular(999)),
                child: Text(fund.status.label,
                    style: TextStyle(
                        color: _statusFg,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: l10n.fundCardWeekly,
                    value: formatIndianCurrency(fund.weeklyAmount)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                    label: l10n.fundCardWeeks,
                    value: '${fund.numberOfWeeks}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: l10n.fundCardBonus,
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
                Text(l10n.fundCardMaturityPayout,
                    style: const TextStyle(
                        color: AppColors.kTextDark, fontSize: 14)),
                Text(formatIndianCurrency(fund.maturityPayout),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextDark)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.fundCardDepositedProgress(
                    formatIndianCurrency(fund.depositedAmount),
                    formatIndianCurrency(fund.totalDeposit)),
                style:
                    const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
              ),
              Text('${fund.depositedPercent.round()}%',
                  style: const TextStyle(
                      color: AppColors.kTextMuted, fontSize: 13)),
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
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.kTextMuted),
              const SizedBox(width: 6),
              Text(formatDate(fund.startDate),
                  style: const TextStyle(
                      color: AppColors.kTextMuted, fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.card_giftcard_outlined,
                  size: 14, color: AppColors.kTextMuted),
              const SizedBox(width: 6),
              Text(formatDate(fund.maturityDate),
                  style: const TextStyle(
                      color: AppColors.kTextMuted, fontSize: 13)),
            ],
          ),
          const Divider(height: 28, color: AppColors.kBorder),
          _buildActions(l10n),
        ],
      ),
    );
  }

  /// Role-specific action row:
  /// - customer: Passbook only (read-only).
  /// - agent: Passbook + Collect, plus Settle in full when active. No edit/delete.
  /// - admin: Passbook + Edit + Delete, plus Settle in full when active. No Collect.
  Widget _buildActions(AppLocalizations l10n) {
    if (isCustomer) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPassbook,
          icon: const Icon(Icons.menu_book_outlined, size: 18),
          label: Text(l10n.fundCardPassbookButton),
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPassbook,
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: Text(l10n.fundCardPassbookButton),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (fund.status == FundStatus.active) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCollect,
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(l10n.fundCardCollectButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _settleBanner(onAgentSettle, l10n),
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
                label: Text(l10n.fundCardPassbookButton),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCollect,
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: Text(l10n.fundCardCollectButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _settleBanner(onSettle, l10n),
        ],
      ],
    );
  }

  Widget _settleBanner(VoidCallback onTap, AppLocalizations l10n) {
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
            const Icon(Icons.check_circle_outline,
                size: 18, color: AppColors.kSuccess),
            const SizedBox(width: 8),
            Text(
              l10n.fundCardSettleBanner(
                  formatIndianCurrency(fund.remainingToSettle)),
              style: const TextStyle(
                  color: AppColors.kSuccess,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, this.highlight = false});
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
                  color:
                      highlight ? AppColors.kWarning : AppColors.kTextMuted)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        highlight ? AppColors.kWarning : AppColors.kTextDark)),
          ),
        ],
      ),
    );
  }
}

class _IconButtonSquare extends StatelessWidget {
  const _IconButtonSquare(
      {required this.icon, required this.onTap, this.color});
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
  const _FundFormDialog(
      {this.existing, this.customers = const [], this.agents = const []});

  /// When non-null, the dialog opens in edit mode, prefilled from this fund.
  final Fund? existing;
  final List<Map<String, String>> customers;
  final List<Map<String, String>> agents;

  @override
  State<_FundFormDialog> createState() => _FundFormDialogState();
}

class _FundFormDialogState extends State<_FundFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weeklyCtrl;
  late final TextEditingController _unitsCtrl;
  late final TextEditingController _weeksCtrl;
  late final TextEditingController _bonusCtrl;
  late DateTime _startDate;
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedAgentId;
  String? _selectedAgentName;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _weeklyCtrl = TextEditingController(
        text: existing != null
            ? existing.weeklyAmount.round().toString()
            : '100');
    _unitsCtrl = TextEditingController(
        text: existing != null ? existing.units.toStringAsFixed(0) : '10');
    _weeksCtrl = TextEditingController(
        text: existing != null ? existing.numberOfWeeks.toString() : '50');
    _bonusCtrl = TextEditingController(
        text: existing != null
            ? existing.maturityBonus.round().toString()
            : '1000');
    _startDate = existing?.startDate ?? DateTime.now();
    _selectedCustomerId = existing?.customerId;
    _selectedCustomerName = existing?.customerName;
    _selectedAgentId = existing?.assignedAgentId;
    _selectedAgentName = existing?.agentName;
  }

  @override
  void dispose() {
    _weeklyCtrl.dispose();
    _unitsCtrl.dispose();
    _weeksCtrl.dispose();
    _bonusCtrl.dispose();
    super.dispose();
  }

  double get _weekly => double.tryParse(_weeklyCtrl.text) ?? 0;
  double get _units => double.tryParse(_unitsCtrl.text) ?? 0;
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
        data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: AppColors.kGold)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      final l10n = AppLocalizations.of(context);
      ToastService.show(
          title: l10n.fundToastSelectCustomerTitle,
          message: l10n.fundToastSelectCustomerMessage,
          type: ToastType.error);
      return;
    }

    final existing = widget.existing;
    final fund = Fund(
      id: existing?.id ?? '',
      code: existing?.code ?? 'FND-${DateTime.now().millisecondsSinceEpoch}',
      customerId: _selectedCustomerId!,
      customerName: _selectedCustomerName ?? '',
      assignedAgentId: _selectedAgentId,
      agentName: _selectedAgentName,
      units: _units,
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
    final l10n = AppLocalizations.of(context);
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
                  child: Text(
                      _isEditing ? l10n.fundFormTitleEdit : l10n.fundFormTitleAdd,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextDark)),
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
            Text(l10n.fundFormFieldCustomer,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextMuted)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCustomerId,
              isExpanded: true,
              decoration: InputDecoration(
                  isDense: true, hintText: l10n.fundFormFieldCustomerHint),
              items: widget.customers
                  .map((c) => DropdownMenuItem(
                        value: c['id'],
                        child: Text(
                            c['name'] ?? l10n.fundFormFieldCustomerFallback),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedCustomerId = v;
                _selectedCustomerName =
                    widget.customers.firstWhere((c) => c['id'] == v)['name'];
              }),
            ),
            const SizedBox(height: 16),
            Text(l10n.fundFormFieldAgent,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextMuted)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAgentId,
              isExpanded: true,
              decoration: InputDecoration(
                  isDense: true, hintText: l10n.fundFormFieldAgentHint),
              items: widget.agents
                  .map((agent) => DropdownMenuItem(
                        value: agent['id'],
                        child: Text(
                            agent['name'] ?? l10n.fundFormFieldAgentFallback),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedAgentId = v;
                _selectedAgentName =
                    widget.agents.firstWhere((a) => a['id'] == v)['name'];
              }),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Column(
                children: [
                  _responsiveRow(
                    isNarrow,
                    _buildTextField(l10n.fundFormFieldUnits,
                        controller: _unitsCtrl, icon: Icons.savings_outlined),
                    _buildTextField(l10n.fundFormFieldWeeklyAmount,
                        controller: _weeklyCtrl, icon: Icons.currency_rupee),
                  ),
                  const SizedBox(height: 16),
                  _responsiveRow(
                    isNarrow,
                    _buildTextField(l10n.fundFormFieldWeeks,
                        controller: _weeksCtrl, icon: Icons.event_repeat),
                    _buildTextField(l10n.fundFormFieldBonus,
                        controller: _bonusCtrl, icon: Icons.card_giftcard),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.fundFormFieldStartDate,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextMuted)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              isDense: true,
                              suffixIcon: Icon(Icons.calendar_today_outlined)),
                          child: Text('$dd/$mm/$yyyy'),
                        ),
                      ),
                    ],
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
                      label: l10n.fundFormSummaryDeposited(
                          '${_weekly.round()}', '$_weeks'),
                      value: formatIndianCurrency(_totalDeposit)),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: l10n.fundFormSummaryBonus,
                    value: l10n.fundFormSummaryBonusValue(
                        formatIndianCurrency(_bonus)),
                    valueColor: AppColors.kGold,
                  ),
                  const Divider(height: 20, color: AppColors.kBorder),
                  _SummaryRow(
                    label: l10n.fundFormSummaryTotalPayout,
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
              child: Text(l10n.fundFormMaturesOn(formatDate(_maturityDate)),
                  style: const TextStyle(
                      color: AppColors.kTextMuted, fontSize: 13)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.fundFormCancelButton)),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleSubmit,
                  icon: Icon(_isEditing
                      ? Icons.save_outlined
                      : Icons.add_circle_outline),
                  label: Text(_isEditing
                      ? l10n.fundFormSaveButton
                      : l10n.fundFormCreateButton),
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
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b)
      ],
    );
  }

  Widget _buildTextField(String label,
      {required TextEditingController controller, IconData? icon}) {
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
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: AppColors.kTextMuted)
                : null,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? AppLocalizations.of(context).fundFormValidatorRequired
              : null,
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
  String _paymentMethod = 'Cash';
  DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;

  static const _paymentMethods = [
    'Cash',
    'UPI',
    'Card',
    'Bank Transfer',
    'Cheque'
  ];

  Future<void> _pickPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: widget.fund.startDate,
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: AppColors.kGold)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  @override
  void initState() {
    super.initState();
    final fund = widget.fund;
    final suggested = fund.weeklyAmount > 0
        ? fund.weeklyAmount.clamp(
            0,
            fund.remainingToSettle == 0
                ? fund.weeklyAmount
                : fund.remainingToSettle)
        : fund.remainingToSettle;
    _amountCtrl = TextEditingController(text: suggested.round().toString());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRecord() async {
    final l10n = AppLocalizations.of(context);
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    if (amount <= 0) {
      ToastService.show(
        title: l10n.fundCollectDialogInvalidAmountTitle,
        message: l10n.fundCollectDialogInvalidAmountMessage,
        type: ToastType.error,
      );
      return;
    }

    final fund = widget.fund;
    final remaining =
        fund.remainingToSettle.clamp(0, double.infinity).toDouble();
    if (amount > remaining + 0.01) {
      ToastService.show(
        title: l10n.fundCollectDialogNotSavedTitle,
        message: l10n.fundCollectDialogNotSavedMessage(
            formatIndianCurrency(remaining)),
        type: ToastType.warning,
      );
      return;
    }
    // Backend allow-lists agent PATCH bodies to exactly `collected_amount`
    // and `status` — no `amount`/`payment_method`/`payment_date` fields are
    // accepted, so we compute the new running total and status here and
    // send only those two fields. Clamp so a stray over-payment can't push
    // collected_amount past the fund's total deposit target.
    final newCollected = fund.depositedAmount + amount;
    final newStatus = newCollected >= fund.totalDeposit
        ? FundStatus.matured.label
        : fund.status.label;

    setState(() => _isSubmitting = true);
    try {
      await FundApiService.recordCollection(
        widget.fund.id,
        collectedAmount: newCollected,
        status: newStatus,
        paymentAmount: amount,
        paymentMethod: _paymentMethod,
        paymentDate: _paymentDate,
        fundCode: widget.fund.code,
        customerId: widget.fund.customerId,
        customerName: widget.fund.customerName,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ToastService.show(
          title: AppLocalizations.of(context).fundCollectDialogFailedTitle,
          message: e.toString(),
          type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.savings_outlined,
                    color: AppColors.kGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.fundCollectDialogTitle,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text(
                        l10n.fundCollectDialogSubtitle(
                            fund.code, fund.customerName),
                        style: const TextStyle(
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.fundCollectDialogCollectedLabel,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMuted)),
                      const SizedBox(height: 4),
                      Text(formatIndianCurrency(fund.depositedAmount),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTextDark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.fundCollectDialogRemainingLabel,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kSuccess)),
                      const SizedBox(height: 4),
                      Text(formatIndianCurrency(fund.remainingToSettle),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kSuccess)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(l10n.fundCollectDialogAmountLabel,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextMuted)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;
            final methodField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.fundCollectDialogPaymentMethodLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kTextMuted)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: _paymentMethods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _paymentMethod = v ?? 'Cash'),
                ),
              ],
            );
            final dateField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.fundCollectDialogPaymentDateLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kTextMuted)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickPaymentDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      isDense: true,
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(formatDate(_paymentDate)),
                  ),
                ),
              ],
            );
            if (isNarrow)
              return Column(children: [
                methodField,
                const SizedBox(height: 16),
                dateField
              ]);
            return Row(children: [
              Expanded(child: methodField),
              const SizedBox(width: 16),
              Expanded(child: dateField)
            ]);
          }),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.currency_rupee,
                  size: 18, color: AppColors.kTextMuted),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.fundCollectDialogHelperText,
            style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.fundFormCancelButton),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleRecord,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.payments_outlined),
                label: Text(l10n.fundCollectDialogRecordButton),
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
enum _ClosureMode { partial, full }

class _SettleFundDialog extends StatefulWidget {
  const _SettleFundDialog({required this.fund});
  final Fund fund;

  @override
  State<_SettleFundDialog> createState() => _SettleFundDialogState();
}

class _SettleFundDialogState extends State<_SettleFundDialog> {
  _ClosureMode _mode = _ClosureMode.partial;
  String _paymentMethod = 'Cash';
  DateTime _settlementDate = DateTime.now();
  bool _isSubmitting = false;

  // Funds are modeled as a single unit in this schema (no `units` column),
  // so partial closure treats the whole fund as "1 unit" you can close a
  // fraction of. Wire this from a real units field if you add one later.
  static const double _maxUnits = 1;
  late final TextEditingController _unitsCtrl =
      TextEditingController(text: _maxUnits.toString());

  double get _unitsToClose =>
      (double.tryParse(_unitsCtrl.text) ?? 0).clamp(0, _maxUnits);
  double get _fraction => _maxUnits == 0 ? 0 : _unitsToClose / _maxUnits;
  double get _remainingUnits => _maxUnits - _unitsToClose;

  double get _closingDepositTarget => widget.fund.totalDeposit * _fraction;
  double get _proportionalBonus => widget.fund.maturityBonus * _fraction;
  double get _accruedForClosedPortion =>
      (widget.fund.depositedAmount * _fraction).clamp(0, _closingDepositTarget);
  double get _closedUnitsPayout =>
      _accruedForClosedPortion + _proportionalBonus;
  double get _newWeeklyAmount =>
      widget.fund.weeklyAmount *
      (_maxUnits == 0 ? 0 : _remainingUnits / _maxUnits);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _settlementDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: AppColors.kGold)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _settlementDate = picked);
  }

  Future<void> _handleFullSettle() async {
    setState(() => _isSubmitting = true);
    try {
      await FundApiService.settleInFull(
        widget.fund.id,
        paymentMethod: _paymentMethod,
        settlementDate: _settlementDate,
        totalDeposit: widget.fund.totalDeposit,
        depositedAmount: widget.fund.depositedAmount,
        fundCode: widget.fund.code,
        customerId: widget.fund.customerId,
        customerName: widget.fund.customerName,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ToastService.show(
          title: AppLocalizations.of(context).fundSettleFailedTitle,
          message: e.toString(),
          type: ToastType.error);
    }
  }

  Future<void> _handlePartialClosure() async {
    if (_unitsToClose <= 0) {
      ToastService.show(
          title: 'Enter units to close',
          message: 'Units must be greater than 0',
          type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    final fund = widget.fund;
    try {
      // Step 1: shrink the fund's ongoing target (admin-only generic PATCH,
      // same shape update() already uses — no new PHP endpoint needed).
      final shrunk = fund.copyWith(
        weeklyAmount: _newWeeklyAmount,
        numberOfWeeks:
            fund.numberOfWeeks - (fund.numberOfWeeks * _fraction).round(),
        maturityBonus: fund.maturityBonus - _proportionalBonus,
      );
      await FundApiService.update(fund.id, shrunk);

      // Step 2: credit the closed portion's payout onto collected_amount via
      // the already-allowed recordCollection path.
      final newCollected = (fund.depositedAmount + _closedUnitsPayout)
          .clamp(0, fund.totalDeposit)
          .toDouble();
      final newStatus =
          _remainingUnits <= 0 ? FundStatus.matured.label : fund.status.label;
      await FundApiService.recordCollection(
        fund.id,
        collectedAmount: newCollected,
        status: newStatus,
        paymentAmount: _closedUnitsPayout,
        paymentMethod: _paymentMethod,
        paymentDate: _settlementDate,
        fundCode: fund.code,
        customerId: fund.customerId,
        customerName: fund.customerName,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ToastService.show(
          title: AppLocalizations.of(context).fundSettleFailedTitle,
          message: e.toString(),
          type: ToastType.error);
    }
  }

  Widget _tabButton(String label, IconData icon, _ClosureMode mode) {
    final selected = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 1))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? AppColors.kGold : AppColors.kTextMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.kTextDark
                          : AppColors.kTextMuted)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.fundSettleDialogTitle,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text(
                        l10n.fundSettleDialogSubtitle(fund.code,
                            fund.customerName, _maxUnits.toStringAsFixed(0)),
                        style: const TextStyle(
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                _tabButton(l10n.fundSettleTabPartial, Icons.bolt,
                    _ClosureMode.partial),
                _tabButton(l10n.fundSettleTabFull, Icons.lock_outline,
                    _ClosureMode.full),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_mode == _ClosureMode.partial) ...[
            Text(l10n.fundSettleUnitsToCloseLabel,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unitsCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => setState(() => _unitsCtrl.text = '0.5'),
                  child: Text(l10n.fundSettleHalfUnitButton),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () =>
                      setState(() => _unitsCtrl.text = _maxUnits.toString()),
                  child: Text(l10n.fundSettleOneUnitButton),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.fundSettleClosedPayoutLabel,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF7C3AED))),
                        const SizedBox(height: 4),
                        Text(formatIndianCurrency(_closedUnitsPayout),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7C3AED))),
                        Text(l10n.fundSettleClosedPayoutSubtitle,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF7C3AED))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.fundSettleRemainingBalanceLabel,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.kSuccess)),
                        const SizedBox(height: 4),
                        Text(
                            l10n.fundSettleRemainingUnitsValue(_remainingUnits
                                .toStringAsFixed(
                                    _remainingUnits % 1 == 0 ? 0 : 1)),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kSuccess)),
                        Text(
                            l10n.fundSettleNewWeeklyValue(
                                formatIndianCurrency(_newWeeklyAmount)),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.kSuccess)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.fundSettleTotalDepositedLabel,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kTextMuted)),
                        const SizedBox(height: 4),
                        Text(formatIndianCurrency(fund.depositedAmount),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kTextDark)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.fundSettleRemainingTargetLabel,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kWarning)),
                        const SizedBox(height: 4),
                        Text(formatIndianCurrency(fund.remainingToSettle),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kWarning)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;
            final methodField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.fundSettlePaymentMethodLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kTextMuted)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: const [
                    'Cash',
                    'UPI',
                    'Card',
                    'Bank Transfer',
                    'Cheque'
                  ]
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _paymentMethod = v ?? 'Cash'),
                ),
              ],
            );
            final dateField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.fundSettleSettlementDateLabel,
                    style: const TextStyle(
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
            );
            if (isNarrow)
              return Column(children: [
                methodField,
                const SizedBox(height: 16),
                dateField
              ]);
            return Row(children: [
              Expanded(child: methodField),
              const SizedBox(width: 16),
              Expanded(child: dateField)
            ]);
          }),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _SummaryRow(
                  label: _mode == _ClosureMode.partial
                      ? l10n.fundSettleSummaryClosingTarget
                      : l10n.fundSettleSummaryTotalDeposit,
                  value: _mode == _ClosureMode.partial
                      ? l10n.fundSettleSummaryClosingTargetValue(
                          formatIndianCurrency(_closingDepositTarget),
                          _unitsToClose.toStringAsFixed(
                              _unitsToClose % 1 == 0 ? 0 : 1),
                          _maxUnits.toStringAsFixed(0))
                      : formatIndianCurrency(fund.totalDeposit),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: l10n.fundSettleSummaryProportionalBonus,
                  value: l10n.fundFormSummaryBonusValue(formatIndianCurrency(
                      _mode == _ClosureMode.partial
                          ? _proportionalBonus
                          : fund.maturityBonus)),
                  valueColor: AppColors.kGold,
                ),
                const Divider(height: 20, color: AppColors.kBorder),
                _SummaryRow(
                  label: _mode == _ClosureMode.partial
                      ? l10n.fundSettleSummaryNetClosurePayout
                      : l10n.fundSettleSummaryPayoutToCustomer,
                  value: formatIndianCurrency(_mode == _ClosureMode.partial
                      ? _closedUnitsPayout
                      : fund.maturityPayout),
                  labelColor: AppColors.kSuccess,
                  valueColor: AppColors.kSuccess,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.fundFormCancelButton),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : (_mode == _ClosureMode.partial
                        ? _handlePartialClosure
                        : _handleFullSettle),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_mode == _ClosureMode.partial
                    ? l10n.fundSettleConfirmPartialButton
                    : l10n.fundSettleConfirmFullButton),
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

  static List<FundEntry> _buildSchedule(
      Fund fund, List<FundEntry> paidEntries) {
    final totalWeeks =
        fund.numberOfWeeks > 0 ? fund.numberOfWeeks : paidEntries.length;
    final originalRows = [...paidEntries]
      ..sort((a, b) => a.date.compareTo(b.date));
    final originalPayments = <FundEntry>[];
    for (var i = 0; i < originalRows.length; i++) {
      final entry = originalRows[i];
      originalPayments.add(entry.week > 0
          ? entry
          : FundEntry(
              week: i + 1,
              date: entry.date,
              amount: entry.amount,
              balanceAfter: entry.balanceAfter,
              method: entry.method,
              paid: entry.paid,
            ));
    }
    final schedule = <FundEntry>[...originalPayments];

    if (fund.depositedAmount >= fund.totalDeposit - 0.01) {
      return schedule;
    }

    // The database payment rows are the only source for paid history. Add
    // pending rows only to complete the fund's configured number of weeks.
    for (int week = originalPayments.length + 1; week <= totalWeeks; week++) {
      schedule.add(FundEntry(
        week: week,
        date: fund.startDate.add(Duration(days: 7 * (week - 1))),
        amount: fund.weeklyAmount,
        method: null,
        paid: false,
      ));
    }
    return schedule;
  }

  static const _weekdayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
    final l10n = AppLocalizations.of(context);
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
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.savings_outlined,
                    color: AppColors.kGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.fundPassbookTitle,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text(
                        l10n.fundPassbookSubtitle(
                            fund.code, fund.customerName),
                        style: const TextStyle(
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
                  Text(_error!,
                      style: const TextStyle(color: AppColors.kDanger)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _load, child: Text(l10n.fundRetryButton)),
                ],
              ),
            )
          else ...[
            LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final stats = [
                _PassbookStat(
                    label: l10n.fundPassbookDepositedLabel,
                    value: formatIndianCurrency(_paidSum),
                    bg: const Color(0xFFDCFCE7),
                    fg: AppColors.kSuccess),
                _PassbookStat(
                    label: l10n.fundPassbookToDepositLabel,
                    value: formatIndianCurrency((fund.totalDeposit - _paidSum)
                        .clamp(0, double.infinity)
                        .toDouble()),
                    bg: const Color(0xFFF3F4F6),
                    fg: AppColors.kTextDark),
                _PassbookStat(
                    label: l10n.fundPassbookEntriesLabel,
                    value: l10n.fundPassbookEntriesValue(
                        '$_paidCount', '${fund.numberOfWeeks}'),
                    bg: const Color(0xFFFEF3C7),
                    fg: AppColors.kWarning),
              ];
              if (compact) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: stats
                      .map((stat) => SizedBox(
                          width: (constraints.maxWidth - 10) / 2, child: stat))
                      .toList(),
                );
              }
              return Row(
                  children: stats
                      .map((stat) => Expanded(
                              child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: stat,
                          )))
                      .toList());
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _SummaryRow(
                      label: l10n.fundPassbookSummaryTotalDeposit(
                          '${fund.weeklyAmount.round()}',
                          '${fund.numberOfWeeks}'),
                      value: formatIndianCurrency(fund.totalDeposit)),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: l10n.fundPassbookSummaryBonus,
                    value: l10n.fundFormSummaryBonusValue(
                        formatIndianCurrency(fund.maturityBonus)),
                    valueColor: AppColors.kGold,
                  ),
                  const Divider(height: 20, color: AppColors.kBorder),
                  _SummaryRow(
                    label: l10n.fundPassbookSummaryPayout,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF2563EB)),
                          children: [
                            TextSpan(text: l10n.fundPassbookNextDuePrefix),
                            TextSpan(
                              text: l10n.fundPassbookNextDueValue(
                                  formatDate(next.date),
                                  '${next.week}',
                                  formatIndianCurrency(next.amount)),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Text(l10n.fundPassbookColWeek,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTextMuted))),
                  Expanded(
                      flex: 3,
                      child: Text(l10n.fundPassbookColDateMethod,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTextMuted))),
                  Expanded(
                      flex: 2,
                      child: Text(l10n.fundPassbookColAmountBalance,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTextMuted))),
                ],
              ),
            ),
            const Divider(height: 16, color: AppColors.kBorder),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _schedule.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.kBorder),
                itemBuilder: (context, i) {
                  final e = _schedule[i];
                  final isNext = next != null && e.week == next.week;

                  final balance = e.balanceAfter ??
                      _schedule
                          .take(i + 1)
                          .where((row) => row.paid)
                          .fold<double>(0, (sum, row) => sum + row.amount);

                  final weekdayLabel =
                      _weekdayAbbr[(e.date.weekday - 1).clamp(0, 6)];
                  final dateLabel = e.paid
                      ? formatDate(e.date)
                      : '${formatDate(e.date)} ($weekdayLabel)';

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
                                      color: isNext
                                          ? const Color(0xFF2563EB)
                                          : AppColors.kTextDark)),
                              Text(
                                isNext
                                    ? l10n.fundPassbookNextDueRowLabel
                                    : (e.paid
                                        ? (e.method ??
                                            l10n.fundPassbookPaidFallback)
                                        : ''),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isNext
                                        ? const Color(0xFF2563EB)
                                        : AppColors.kTextMuted),
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
                                    color: e.paid
                                        ? AppColors.kSuccess
                                        : AppColors.kTextDark),
                              ),
                              Text(
                                e.paid
                                    ? l10n.fundPassbookBalanceValue(
                                        formatIndianCurrency(balance))
                                    : l10n.fundPassbookPendingLabel,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.kTextMuted),
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
              child: Text(l10n.fundPassbookCloseButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassbookStat extends StatelessWidget {
  const _PassbookStat(
      {required this.label,
      required this.value,
      required this.bg,
      required this.fg});
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
          ),
        ],
      ),
    );
  }
}
