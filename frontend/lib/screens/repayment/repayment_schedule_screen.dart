import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/status_badge.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../models/loan_record.dart';
import '../../models/repayment_installment.dart';
import '../../services/api_service_repayment.dart';
import '../../services/loan_service.dart';
import '../../services/session_service.dart';
import '../../models/user_role.dart';

class RepaymentScheduleScreen extends StatefulWidget {
  const RepaymentScheduleScreen({super.key});

  @override
  State<RepaymentScheduleScreen> createState() =>
      _RepaymentScheduleScreenState();
}

class _RepaymentScheduleScreenState extends State<RepaymentScheduleScreen> {
  bool _loading = true;
  String? _error;

  bool get _isCustomer =>
      SessionService.instance.currentUser?.role == UserRole.customer;

  String? get _customerId =>
      SessionService.instance.currentUser?.customerId?.toString();

  List<LoanRecord> _loanOptions = [];
  LoanRecord? _selectedLoan;
  List<RepaymentInstallment> _installments = [];

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() {
      _loading = true;
      _error = null;
      _loanOptions = [];
      _selectedLoan = null;
      _installments = [];
    });

    try {
      final customers = await LoanService.instance.fetchCustomers();
      final agents = await LoanService.instance.fetchAgents();
      final loans = await LoanService.instance.fetchLoans(
        customers: customers,
        agents: agents,
      );
      final filteredLoans = _isCustomer && _customerId != null
          ? loans.where((loan) => loan.customerId == _customerId).toList()
          : loans;
      if (!mounted) return;
      setState(() {
        _loanOptions = filteredLoans;
        _selectedLoan = filteredLoans.isNotEmpty ? filteredLoans.first : null;
      });
      if (_selectedLoan != null) {
        await _loadSchedule();
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load loans';
        _loading = false;
      });
      ToastService.show(
        title: 'Loan load failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _loadSchedule() async {
    if (_selectedLoan == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiServiceRepayment.instance
          .fetchSchedule(_selectedLoan!.id);
      if (!mounted) return;
      setState(() {
        _installments = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load repayment schedule';
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        return AppShell(
          currentRoute: AppRoutes.repayment,
          title: 'Repayment Schedule',
          body: RefreshIndicator(
            onRefresh: _loadSchedule,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 12 : 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isNarrow),
                  const SizedBox(height: 24),
                  if (!_isCustomer) ...[
                    _buildLoanSelector(),
                    const SizedBox(height: 20),
                  ],
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _buildErrorState()
                  else ...[
                    if (!_isCustomer) ...[
                      _buildSummaryGrid(isNarrow),
                      const SizedBox(height: 24),
                      _buildSectionLabel('INSTALLMENT BREAKDOWN'),
                      const SizedBox(height: 12),
                    ],
                    _buildInstallmentsTable(isNarrow),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
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
            onPressed: _loadSchedule,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Header
  Widget _buildHeader(BuildContext context, bool isNarrow) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = Text(
      'Track installment-wise EMI collections and outstanding balances',
      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
    );

    final downloadButton = Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 200,
        child: ElevatedButton.icon(
          onPressed: () {
            ToastService.show(
              title: 'Download started',
              message: _selectedLoan?.loanNumber ?? 'No loan selected',
              type: ToastType.info,
            );
          },
          icon: const Icon(Icons.download_outlined, size: 20),
          label: const Text('Download Schedule'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          subtitle,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: downloadButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: subtitle),
        downloadButton,
      ],
    );
  }

  // Loan selector card
  Widget _buildLoanSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT LOAN',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.kTextMuted,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<LoanRecord>(
            initialValue: _selectedLoan,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
            ),
            hint: const Text('Select loan'),
            items: _loanOptions
                .map((loan) => DropdownMenuItem<LoanRecord>(
                      value: loan,
                      child: Text('${loan.loanNumber} — ${loan.customerName}'),
                    ))
                .toList(),
            onChanged: _loanOptions.isEmpty
                ? null
                : (loan) {
                    if (loan != null) {
                      setState(() => _selectedLoan = loan);
                      ToastService.show(
                        title: 'Loan switched',
                        message: loan.loanNumber,
                        type: ToastType.info,
                      );
                      _loadSchedule();
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.kTextMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  // Summary cards grid — responsive: 2 columns narrow, 4 columns wide.
  // All figures below are derived from the fetched schedule rows.
  Widget _buildSummaryGrid(bool isNarrow) {
    final total = _installments.length;
    final paidCount =
        _installments.where((i) => i.status == 'paid').length;
    final overdueCount =
        _installments.where((i) => i.status == 'overdue').length;
    final pendingCount = total - paidCount - overdueCount;

    final emi = _installments.isNotEmpty
        ? _installments.first.emiAmount
        : 0.0;
    final totalRepayment =
        _installments.fold<double>(0, (sum, i) => sum + i.emiAmount);
    final outstanding =
        _installments.fold<double>(0, (sum, i) => sum + i.balance);

    final nextDue = _installments
        .where((i) => i.status != 'paid' && i.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final nextDueDisplay =
        nextDue.isNotEmpty ? nextDue.first.dueDateDisplay : '-';

    String fmt(double v) =>
        RepaymentInstallment(
          id: '',
          loanId: '',
          installmentNo: 0,
          dueDate: null,
          emiAmount: v,
          paidAmount: 0,
          balance: 0,
          status: 'pending',
        ).amountDisplay;

    final cards = <Widget>[
      _buildStatCard('LOAN NUMBER', _selectedLoan?.loanNumber ?? '-', icon: Icons.badge_outlined),
      _buildStatCard('CUSTOMER', _selectedLoan?.customerName ?? '-', icon: Icons.person_outline),
      _buildStatCard('LOAN AMOUNT', '—',
          icon: Icons.account_balance_wallet_outlined),
      _buildStatCard('EMI', fmt(emi), icon: Icons.calendar_month_outlined),
      _buildStatCard('TOTAL REPAYMENT', fmt(totalRepayment),
          icon: Icons.summarize_outlined),
      _buildStatCard('OUTSTANDING', fmt(outstanding),
          icon: Icons.warning_amber_outlined, textColor: AppColors.kDanger),
      _buildStatCard('TOTAL INST.', '$total',
          icon: Icons.format_list_numbered),
      _buildStatCard('PAID', '$paidCount',
          icon: Icons.check_circle_outline,
          textColor: AppColors.kSuccess,
          borderColor: AppColors.kSuccess.withOpacity(0.3),
          bgColor: AppColors.kSuccess.withOpacity(0.05)),
      _buildStatCard('PENDING', '$pendingCount',
          icon: Icons.hourglass_empty,
          textColor: AppColors.kWarning,
          borderColor: AppColors.kWarning.withOpacity(0.3),
          bgColor: AppColors.kWarning.withOpacity(0.05)),
      _buildStatCard('OVERDUE', '$overdueCount',
          icon: Icons.error_outline,
          textColor: AppColors.kDanger,
          borderColor: AppColors.kDanger.withOpacity(0.3),
          bgColor: AppColors.kDanger.withOpacity(0.05)),
      _buildStatCard('NEXT DUE', nextDueDisplay,
          icon: Icons.event_outlined,
          textColor: AppColors.kInfo,
          borderColor: AppColors.kInfo.withOpacity(0.3),
          bgColor: AppColors.kInfo.withOpacity(0.05)),
    ];

    return GridView.count(
      crossAxisCount: isNarrow ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isNarrow ? 1.5 : 1.7,
      children: cards,
    );
  }

  // Reusable widget for building the summary cards
  Widget _buildStatCard(
    String title,
    String value, {
    IconData? icon,
    Color? bgColor,
    Color? borderColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.kSurface,
        border: Border.all(color: borderColor ?? AppColors.kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor?.withOpacity(0.85) ?? AppColors.kTextMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              if (icon != null)
                Icon(icon,
                    size: 16,
                    color: textColor?.withOpacity(0.6) ??
                        AppColors.kTextMuted.withOpacity(0.6)),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: textColor ?? AppColors.kTextDark,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Installments table — same visual pattern as before, now sourced
  // from live `_installments` fetched via ApiServiceRepayment.
  Widget _buildInstallmentsTable(bool isNarrow) {
    if (_installments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          border: Border.all(color: AppColors.kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No installments found for this loan',
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
        DataColumn(label: Text('INST. NO')),
        DataColumn(label: Text('DUE DATE')),
        DataColumn(label: Text('EMI AMOUNT')),
        DataColumn(label: Text('PAID')),
        DataColumn(label: Text('BALANCE')),
        DataColumn(label: Text('STATUS')),
      ],
      rows: _installments.map((inst) {
        return DataRow(cells: [
          DataCell(Text('#${inst.installmentNo}',
              style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(inst.dueDateDisplay)),
          DataCell(Text(inst.amountDisplay)),
          DataCell(Text(inst.paidDisplay)),
          DataCell(Text(inst.balanceDisplay,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(StatusBadge(
              label: inst.statusLabel, tone: _toneFor(inst.statusLabel))),
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
              constraints: const BoxConstraints(minWidth: 720),
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
