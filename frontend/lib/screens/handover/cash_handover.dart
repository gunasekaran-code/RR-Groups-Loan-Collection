import 'package:flutter/material.dart';
import '../../theme/glass_toast.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../models/cash_handover.dart';
import '../../services/cash_handover_api_service.dart';

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

  List<AgentSettlement> _settlements = [];
  List<HandoverRecord> _history = [];

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
      final summary = await CashHandoverApiService.fetchSummary();
      final settlements = await CashHandoverApiService.fetchSettlements();
      final history = await CashHandoverApiService.fetchHistory();
      if (!mounted) return;
      setState(() {
        _totalCollected = summary.totalCollected;
        _totalHandedOver = summary.totalHandedOver;
        _totalPending = summary.totalPending;
        _agentsWithPending = summary.agentsWithPending;
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

  Future<void> _openRecordHandoverDialog() async {
    final result = await showModalBottomSheet<HandoverRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildSheetFrame(
        child: _RecordHandoverDialog(agents: _settlements),
      ),
    );
    if (result == null) return;

    try {
      final created = await CashHandoverApiService.createHandover(result);
      setState(() => _history.insert(0, created));
      ToastService.show(
        title: 'Handover recorded',
        message: created.agentName,
        type: ToastType.success,
      );
      _loadData();
    } catch (e) {
      ToastService.show(
        title: 'Handover failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Widget _buildSheetFrame({required Widget child}) {
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final double maxSheetHeight = MediaQuery.of(context).size.height * 0.75;

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
                            onPressed: _loadData, child: const Text('Retry')),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'Agents settle collected cash & UPI to the office — pending carries forward',
                        style: TextStyle(
                            color: AppColors.kTextMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 190,
                          child: ElevatedButton.icon(
                            onPressed: _openRecordHandoverDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Record Handover',
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
                            icon: Icons.currency_exchange_rounded,
                            iconBg: const Color(0xFFDBEAFE),
                            iconColor: const Color(0xFF2563EB),
                            label: 'Total Collected',
                            value: formatIndianCurrency(_totalCollected),
                            subtitle: 'Today: ₹0',
                          ),
                          _StatCard(
                            icon: Icons.check_circle_outline_rounded,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: AppColors.kSuccess,
                            label: 'Handed Over',
                            value: formatIndianCurrency(_totalHandedOver),
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
                        padding: const EdgeInsets.all(20),
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
                                  color: AppColors.kTextMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            _SettlementTable(settlements: _settlements),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
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
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'No handovers recorded yet.',
                                    style:
                                        TextStyle(color: AppColors.kTextMuted),
                                  ),
                                ),
                              )
                            else
                              ..._history.map(
                                (h) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: _HistoryTile(record: h),
                                ),
                              ),
                          ],
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
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
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style:
                    const TextStyle(color: AppColors.kSuccess, fontSize: 12)),
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
  const _SettlementTable({required this.settlements});
  final List<AgentSettlement> settlements;

  @override
  Widget build(BuildContext context) {
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
  const _HistoryTile({required this.record});
  final HandoverRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
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
            child: const Icon(Icons.handshake_outlined,
                color: AppColors.kWarning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(record.agentName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('verified',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kSuccess)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatDate(record.date)} · ₹${record.cashAmount.round()} cash · ₹${record.upiAmount.round()} UPI',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.kTextMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatIndianCurrency(record.totalAmount),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextDark)),
              const SizedBox(height: 2),
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppColors.kSuccess),
                  SizedBox(width: 4),
                  Text('Received',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.kSuccess)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// RECORD HANDOVER DIALOG
/// -----------------------------------------------------------------------
class _RecordHandoverDialog extends StatefulWidget {
  const _RecordHandoverDialog({required this.agents});
  final List<AgentSettlement> agents;

  @override
  State<_RecordHandoverDialog> createState() => _RecordHandoverDialogState();
}

class _RecordHandoverDialogState extends State<_RecordHandoverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cashCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  AgentSettlement? _selectedAgent;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _cashCtrl.dispose();
    _upiCtrl.dispose();
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
          colorScheme:
              Theme.of(context).colorScheme.copyWith(primary: AppColors.kGold),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate() || _selectedAgent == null) return;

    final result = HandoverRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      agentId: _selectedAgent!.agentId,
      agentName: _selectedAgent!.agentName,
      date: _date,
      cashAmount: double.tryParse(_cashCtrl.text) ?? 0,
      upiAmount: double.tryParse(_upiCtrl.text) ?? 0,
      verified: false,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final dd = _date.day.toString().padLeft(2, '0');
    final mm = _date.month.toString().padLeft(2, '0');
    final yyyy = _date.year.toString();

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
                  icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('AGENT *',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextMuted)),
            const SizedBox(height: 8),
            DropdownButtonFormField<AgentSettlement>(
              initialValue: _selectedAgent,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: widget.agents
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a.agentName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedAgent = v),
              validator: (v) => v == null ? 'Select an agent' : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField('CASH AMOUNT', controller: _cashCtrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField('UPI AMOUNT', controller: _upiCtrl),
                ),
              ],
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
                  label: const Text('Record'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {required TextEditingController controller}) {
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
}