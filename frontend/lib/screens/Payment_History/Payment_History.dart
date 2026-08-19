import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/status_badge.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../models/payment_history.dart';
import '../../services/collection_api_service.dart';
import '../../services/loan_service.dart';
import '../../services/session_service.dart';
import '../../models/user_role.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<PaymentHistoryItem> _payments = [];

  UserRole? get _role => SessionService.instance.currentUser?.role;

  bool get _isCustomer => _role == UserRole.customer;
  bool get _isAgent => _role == UserRole.agent;

  String? get _customerId =>
      SessionService.instance.currentUser?.customerId;

  // NOTE: assumes SessionService.currentUser exposes an agentId getter the
  // same way it exposes customerId. If your AppUser model uses a different
  // field name for the logged-in agent's id, update this line.
  String? get _agentId =>
      SessionService.instance.currentUser?.agentId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<String>? loanIds;

      // Customers only have access to their own loans, so resolve those
      // loan ids first (same pattern as RepaymentScheduleScreen) and use
      // them to scope the collections query — this is reliable even though
      // collection rows may have a null customer_id.
      if (_isCustomer) {
        final cid = _customerId;
        if (cid == null) {
          if (!mounted) return;
          setState(() {
            _payments = [];
            _loading = false;
          });
          return;
        }
        final customers = await LoanService.instance.fetchCustomers();
        final agents = await LoanService.instance.fetchAgents();
        final loans = await LoanService.instance.fetchLoans(
          customers: customers,
          agents: agents,
        );
        loanIds = loans
            .where((loan) => loan.customerId == cid)
            .map((loan) => loan.id)
            .toList();

        // No loans for this customer -> no payments possible, skip the call.
        if (loanIds.isEmpty) {
          if (!mounted) return;
          setState(() {
            _payments = [];
            _loading = false;
          });
          return;
        }
      }

      final data = await CollectionApiService.fetchPaymentHistory(
        customerId: _isCustomer ? _customerId : null,
        loanIds: loanIds,
        agentId: _isAgent ? _agentId : null,
      );
      if (!mounted) return;
      setState(() {
        _payments = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load payment history';
        _loading = false;
      });
      ToastService.show(
        title: 'Load failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  BadgeTone _toneFor(String status) {
    switch (status) {
      case 'Paid':
        return BadgeTone.success;
      case 'Overdue':
        return BadgeTone.danger;
      default:
        return BadgeTone.warning;
    }
  }

  double get _totalPaid =>
      _payments.fold<double>(0, (sum, p) => sum + p.amount);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        return AppShell(
          currentRoute: AppRoutes.paymentHistory,
          title: 'Payment History',
          body: RefreshIndicator(
            onRefresh: _loadHistory,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 12 : 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryBar(),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _buildErrorState()
                  else
                    _buildPaymentsTable(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // "13 payments · Total paid: ₹23,800" + refresh button, as in the reference.
  Widget _buildSummaryBar() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_payments.length} payments · Total paid: ${PaymentHistoryItem.formatAmount(_totalPaid)}',
          style: TextStyle(
            fontSize: 15,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          width: 40,
          child: Material(
            color: AppColors.kSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.kBorder),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _loading ? null : _loadHistory,
              child: const Icon(Icons.refresh, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.kDanger, size: 32),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadHistory,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTable() {
    if (_payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          border: Border.all(color: AppColors.kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No payments found',
          style: TextStyle(color: AppColors.kTextMuted),
        ),
      );
    }

    final table = DataTable(
      headingTextStyle: const TextStyle(
        color: AppColors.kTextMuted,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      dataTextStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.kTextDark,
      ),
      dividerThickness: 0,
      columns: const [
        DataColumn(label: Text('RECEIPT')),
        DataColumn(label: Text('LOAN')),
        DataColumn(label: Text('AMOUNT')),
        DataColumn(label: Text('MODE')),
        DataColumn(label: Text('DATE')),
        DataColumn(label: Text('COLLECTED BY')),
        DataColumn(label: Text('STATUS')),
      ],
      rows: _payments.map((p) {
        return DataRow(cells: [
          DataCell(Text(p.displayReceipt,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(p.loanNumber)),
          DataCell(Text(
            p.formattedAmount,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.kSuccess,
            ),
          )),
          DataCell(Text(p.displayMode)),
          DataCell(Text(p.formattedDate)),
          DataCell(Text(p.displayCollectedBy)),
          DataCell(StatusBadge(
              label: p.statusLabel, tone: _toneFor(p.statusLabel))),
        ]);
      }).toList(),
    );

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: SingleChildScrollView(
                child: table,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
