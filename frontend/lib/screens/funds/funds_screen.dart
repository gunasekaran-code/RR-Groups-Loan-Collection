// screens/funds/funds_screen.dart

import 'package:flutter/material.dart';
import '../../theme/confirm_dialog.dart';
import '../../theme/glass_toast.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../models/fund.dart';
import '../../services/fund_api_service.dart';
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
      final summary = await FundApiService.fetchSummary();
      if (!mounted) return;
      setState(() {
        _funds = funds;
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
                            value: '${_summary?.activeFunds ?? _funds.where((f) => f.status == FundStatus.active).length}',
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
                      if (_funds.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text('No funds yet.',
                                style: TextStyle(color: AppColors.kTextMuted)),
                          ),
                        )
                      else
                        ..._funds.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _FundCard(
                              fund: f,
                              onPassbook: () => _openPassbook(f),
                              onDelete: () => _confirmDelete(f),
                              onSettle: () => _openSettleDialog(f),
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
          // Top Row: Number (Starting) and Icon (End)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Value / Number -> Starting, Top
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
              // Icon -> End, Top
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

          const Spacer(), // Pushes text label to the bottom

          // Bottom Section: Text Label -> Starting, Down
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
  });

  final Fund fund;
  final VoidCallback onPassbook;
  final VoidCallback onDelete;
  final VoidCallback onSettle;

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
              _IconButtonSquare(icon: Icons.edit_outlined, onTap: () {}),
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
            InkWell(
              onTap: onSettle,
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
            ),
          ],
        ],
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
/// CREATE FUND FORM
/// -----------------------------------------------------------------------
class _FundFormDialog extends StatefulWidget {
  const _FundFormDialog();

  @override
  State<_FundFormDialog> createState() => _FundFormDialogState();
}

class _FundFormDialogState extends State<_FundFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weeklyCtrl = TextEditingController(text: '100');
  final _weeksCtrl = TextEditingController(text: '50');
  final _bonusCtrl = TextEditingController(text: '1000');
  DateTime _startDate = DateTime.now();
  String? _selectedCustomerId;
  String? _selectedCustomerName;

  // TODO: replace with real customer list loaded from your CustomerApiService,
  // matching the "Select a customer..." dropdown pattern used elsewhere in the app.
  final List<Map<String, String>> _customers = [];

  @override
  void dispose() {
    _weeklyCtrl.dispose();
    _weeksCtrl.dispose();
    _bonusCtrl.dispose();
    super.dispose();
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

  void _handleCreate() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ToastService.show(
          title: 'Select a customer', message: 'Please choose a customer', type: ToastType.error);
      return;
    }

    final fund = Fund(
      id: '',
      code: '',
      customerId: _selectedCustomerId!,
      customerName: _selectedCustomerName ?? '',
      status: FundStatus.active,
      weeklyAmount: _weekly,
      numberOfWeeks: _weeks,
      maturityBonus: _bonus,
      startDate: _startDate,
      maturityDate: _maturityDate,
      depositedAmount: 0,
      entriesPaid: 0,
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
                const Expanded(
                  child: Text('Add Fund',
                      style: TextStyle(
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
            DropdownButtonFormField<String>(
              initialValue: _selectedCustomerId,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true, hintText: 'Select a customer...'),
              items: _customers
                  .map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name'] ?? '')))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedCustomerId = v;
                _selectedCustomerName = _customers.firstWhere((c) => c['id'] == v)['name'];
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
                  onPressed: _handleCreate,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create Fund'),
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
                    child: Text('$dd/$mm/$yyyy'),
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
  List<FundEntry> _entries = [];

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
        _entries = entries;
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

  FundEntry? get _nextDue {
    for (final e in _entries) {
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
                      value: formatIndianCurrency(fund.depositedAmount),
                      bg: const Color(0xFFDCFCE7),
                      fg: AppColors.kSuccess),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PassbookStat(
                      label: 'TO DEPOSIT',
                      value: formatIndianCurrency(fund.remainingToSettle),
                      bg: const Color(0xFFF3F4F6),
                      fg: AppColors.kTextDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PassbookStat(
                      label: 'ENTRIES',
                      value: '${fund.entriesPaid} / ${fund.numberOfWeeks}',
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
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.kBorder),
                itemBuilder: (context, i) {
                  final e = _entries[i];
                  final isNext = next != null && e.week == next.week;
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
                              border: Border.all(
                                  color: isNext ? const Color(0xFF2563EB) : AppColors.kBorder,
                                  style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${e.week}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isNext ? const Color(0xFF2563EB) : AppColors.kTextDark)),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatDate(e.date),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.kTextDark)),
                              Text(
                                isNext ? 'Next due' : (e.paid ? (e.method ?? 'Paid') : 'Upcoming'),
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
                              Text(formatIndianCurrency(e.amount),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.kTextDark)),
                              Text(e.paid ? 'Paid' : 'Pending',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: e.paid ? AppColors.kSuccess : AppColors.kTextMuted)),
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