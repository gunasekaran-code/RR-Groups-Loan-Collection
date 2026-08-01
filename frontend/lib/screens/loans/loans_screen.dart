import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_badge.dart';
import '../../theme/confirm_dialog.dart';
import '../../theme/glass_toast.dart';
import '../../models/loan_record.dart';
import '../../models/customer.dart';
import '../../models/agent.dart';
import '../../services/loan_service.dart';
import '../../services/api_client.dart';

// ==========================================
// REPAYMENT SCHEDULE — shared helpers/widget
// ==========================================
//
// These are used by both the Create/Edit Loan form (schedule *preview*,
// no payment data) and the Loan Detail view (schedule with placeholder
// paid/balance/status, since there's no repayments API wired up yet).

/// A single row in a computed repayment schedule.
class RepaymentEntry {
  final int index;
  final DateTime dueDate;
  final double amount;
  double paidAmount;
  String status; // 'Paid' | 'Overdue' | 'Due Today' | 'Pending'

  RepaymentEntry({
    required this.index,
    required this.dueDate,
    required this.amount,
    this.paidAmount = 0,
    this.status = 'Pending',
  });

  double get balance => (amount - paidAmount).clamp(0, double.infinity);
}

DateTime _addMonths(DateTime date, int months) {
  // Dart normalizes month/day overflow automatically.
  return DateTime(date.year, date.month + months, date.day);
}

/// Parses either 'DD/MM/YYYY' or 'YYYY-MM-DD' into a [DateTime].
DateTime? tryParseFlexibleDate(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
    return DateTime.tryParse(trimmed);
  }
  final parts = trimmed.split('/');
  if (parts.length == 3) {
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d != null && m != null && y != null) {
      return DateTime(y, m, d);
    }
  }
  return null;
}

/// Builds the due-date/amount schedule for a loan.
///
/// Due-date conventions (matched to the reference screenshots):
/// - Monthly: due one day before the start date's monthly anniversary
///   (start 30 Jul -> first due 29 Aug, then 29 Sep, 29 Oct, ...).
/// - Weekly: due every 7 days from the start date.
/// - Daily: due every 1 day from the start date.
///
/// `totalAmount` is the exact total the borrower repays across all periods;
/// the last installment absorbs any rounding drift so the rows sum exactly.
List<RepaymentEntry> buildRepaymentSchedule({
  required String collectionType,
  required DateTime startDate,
  required int periods,
  required double installment,
  required double totalAmount,
}) {
  if (periods <= 0 || installment <= 0) return [];

  final entries = <RepaymentEntry>[];
  double runningTotal = 0;

  for (int k = 1; k <= periods; k++) {
    late DateTime due;
    switch (collectionType) {
      case 'Monthly':
        final base =
            DateTime(startDate.year, startDate.month, startDate.day - 1);
        due = _addMonths(base, k);
        break;
      case 'Weekly':
        due = startDate.add(Duration(days: 7 * k));
        break;
      default: // Daily
        due = startDate.add(Duration(days: k));
    }

    double amount = double.parse(installment.toStringAsFixed(2));
    if (k == periods) {
      // Absorb rounding drift into the final installment.
      amount = double.parse((totalAmount - runningTotal).toStringAsFixed(2));
    } else {
      runningTotal += amount;
    }

    entries.add(RepaymentEntry(index: k, dueDate: due, amount: amount));
  }
  return entries;
}

/// ASSUMPTION: there's no repayments/transactions endpoint yet, so paid
/// amounts and statuses can't be pulled from the server. This fills in a
/// best-effort status purely from today's date vs. due date. Replace this
/// with real data once a repayments API exists.
void applyPlaceholderScheduleStatus(
    List<RepaymentEntry> entries, String loanStatus) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  for (final e in entries) {
    if (loanStatus == 'Closed') {
      e.paidAmount = e.amount;
      e.status = 'Paid';
      continue;
    }
    final due = DateTime(e.dueDate.year, e.dueDate.month, e.dueDate.day);
    if (due.isBefore(today)) {
      e.status = 'Overdue';
    } else if (due.isAtSameMomentAs(today)) {
      e.status = 'Due Today';
    } else {
      e.status = 'Pending';
    }
  }
}

BadgeTone _scheduleStatusTone(String status) {
  switch (status) {
    case 'Paid':
      return BadgeTone.success;
    case 'Overdue':
      return BadgeTone.danger;
    case 'Due Today':
      return BadgeTone.warning;
    default:
      return BadgeTone.neutral;
  }
}

const List<String> _kMonthNames = [
  '',
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
  'Dec'
];

String _formatScheduleDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_kMonthNames[d.month]} ${d.year}';

/// Renders a repayment schedule as a table. When [showPaymentColumns] is
/// true (Loan Detail view), Paid/Balance/Status columns are shown; the
/// Create/Edit form only shows #, Due Date, and EMI (a pure preview).
/// Horizontally scrolls on narrow (mobile) widths so nothing gets clipped.
class RepaymentScheduleTable extends StatelessWidget {
  final List<RepaymentEntry> entries;
  final bool showPaymentColumns;
  final double maxHeight;

  const RepaymentScheduleTable({
    super.key,
    required this.entries,
    this.showPaymentColumns = false,
    this.maxHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Text(
          'No schedule to preview yet — enter amount, duration, and start date.',
          style: TextStyle(color: AppColors.kTextMuted, fontSize: 13),
        ),
      );
    }

    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppColors.kTextMuted,
    );
    const cellStyle = TextStyle(fontSize: 13, color: AppColors.kTextDark);

    Widget headerRow() => Container(
          color: AppColors.kBackground,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const SizedBox(width: 28, child: Text('#', style: headerStyle)),
              const Expanded(
                  flex: 2, child: Text('DUE DATE', style: headerStyle)),
              const Expanded(child: Text('EMI', style: headerStyle)),
              if (showPaymentColumns) ...[
                const Expanded(child: Text('PAID', style: headerStyle)),
                const Expanded(child: Text('BALANCE', style: headerStyle)),
                const SizedBox(
                    width: 90, child: Text('STATUS', style: headerStyle)),
              ],
            ],
          ),
        );

    Widget dataRow(RepaymentEntry e) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.kBorder, width: 0.5)),
          ),
          child: Row(
            children: [
              SizedBox(width: 28, child: Text('${e.index}', style: cellStyle)),
              Expanded(
                  flex: 2,
                  child:
                      Text(_formatScheduleDate(e.dueDate), style: cellStyle)),
              Expanded(
                  child: Text(LoanRecord.formatRupees(e.amount),
                      style: cellStyle)),
              if (showPaymentColumns) ...[
                Expanded(
                  child: Text(
                    LoanRecord.formatRupees(e.paidAmount),
                    style: cellStyle.copyWith(
                      color: e.paidAmount > 0
                          ? AppColors.kSuccess
                          : AppColors.kTextMuted,
                    ),
                  ),
                ),
                Expanded(
                    child: Text(LoanRecord.formatRupees(e.balance),
                        style: cellStyle)),
                SizedBox(
                  width: 90,
                  child: StatusBadge(
                      label: e.status, tone: _scheduleStatusTone(e.status)),
                ),
              ],
            ],
          ),
        );

    final table = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        headerRow(),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              itemBuilder: (context, i) => dataRow(entries[i]),
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(builder: (context, constraints) {
      final minWidth = showPaymentColumns ? 560.0 : 300.0;
      if (constraints.maxWidth >= minWidth) return table;
      // Mobile / narrow: scroll horizontally instead of clipping columns.
      return Scrollbar(
        thumbVisibility: true,
        notificationPredicate: (n) => n.depth == 0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: table),
        ),
      );
    });
  }
}

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  String _query = '';
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Active',
    'Overdue',
    'Closed',
    'Pending'
  ];

  final LoanService _loanService = LoanService.instance;

  bool _loading = true;
  String? _error;
  List<LoanRecord> _loans = [];
  List<Customer> _customers = [];
  List<Agent> _agents = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final customers = await _loanService.fetchCustomers();
      final agents = await _loanService.fetchAgents();
      final loans = await _loanService.fetchLoans(
        customers: customers,
        agents: agents,
      );
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _agents = agents;
        _loans = loans;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load loans: $e';
        _loading = false;
      });
    }
  }

  /// Helper to wrap form or view content inside the identical 75% max height layout frame
  Widget _buildGlobalSheetFrame({required Widget child}) {
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
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }

  void _showViewLoanDialog(LoanRecord loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: LoanDetailDialog(
          loan: loan,
          onDelete: () {
            Navigator.of(context).pop();
            _showCloseLoanDialog(loan);
          },
        ),
      ),
    );
  }

  void _showCreateLoanDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: LoanFormDialog(
          customers: _customers,
          agents: _agents,
          onSubmit: (data, {required approve}) async {
            final loan = await _loanService.createLoan(data);
            await _loadAll();
            if (!mounted) return loan;
            ToastService.show(
              title: 'Loan created',
              message: loan.loanNumber,
              type: ToastType.success,
            );
            return loan;
          },
        ),
      ),
    );
  }

  void _showEditLoanDialog(LoanRecord loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: LoanFormDialog(
          loan: loan,
          customers: _customers,
          agents: _agents,
          onSubmit: (data, {required approve}) async {
            final updatedLoan = await _loanService.updateLoan(loan.id, data);
            await _loadAll();
            if (!mounted) return updatedLoan;
            ToastService.show(
              title: 'Loan updated',
              message: updatedLoan.loanNumber,
              type: ToastType.success,
            );
            return updatedLoan;
          },
        ),
      ),
    );
  }

  void _showCloseLoanDialog(LoanRecord loan) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Close Loan',
      message:
          'Are you sure you want to close loan ${loan.loanNumber}? Outstanding balance will be set to zero.',
      confirmLabel: 'Close Loan',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true && mounted) {
      try {
        await _loanService.closeLoan(loan.id);
        await _loadAll();
        if (!mounted) return;
        ToastService.show(
          title: 'Loan closed',
          message: '${loan.loanNumber} outstanding balance set to zero',
          type: ToastType.success,
        );
      } catch (e) {
        if (!mounted) return;
        ToastService.show(
          title: 'Could not close loan',
          message: e.toString(),
          type: ToastType.error,
        );
      }
    }
  }

  BadgeTone _toneFor(String status) {
    switch (status) {
      case 'Active':
        return BadgeTone.success;
      case 'Overdue':
        return BadgeTone.danger;
      case 'Closed':
        return BadgeTone.neutral;
      default:
        return BadgeTone.warning;
    }
  }

  List<LoanRecord> get _filteredLoans => _loans.where((l) {
        final q = _query.toLowerCase();
        final matchesQuery = l.customerName.toLowerCase().contains(q) ||
            l.loanNumber.toLowerCase().contains(q);
        final matchesFilter =
            _selectedFilter == 'All' || l.status == _selectedFilter;
        return matchesQuery && matchesFilter;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/loans',
      title: 'Loans',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Loans',
                subtitle: 'Manage loan accounts, schedules, and repayments',
                actions: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 150,
                      child: ElevatedButton.icon(
                        onPressed: _showCreateLoanDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Loan'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _buildSearchAndFilters(isNarrow),
              const SizedBox(height: 8),
              Expanded(child: _buildBody(isNarrow)),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(bool isNarrow) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.kDanger)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _loadAll, child: const Text('Retry')),
          ],
        ),
      );
    }
    return _buildLoansTable(isNarrow);
  }

  Widget _buildSearchAndFilters(bool isNarrow) {
    final scheme = Theme.of(context).colorScheme;
    final searchField = TextField(
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Search loan number or customer...',
        isDense: true,
      ),
      onChanged: (v) => setState(() => _query = v),
    );

    final filterRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              selectedColor: scheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : scheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) =>
                  setState(() => _selectedFilter = filter),
            ),
          );
        }).toList(),
      ),
    );

    if (isNarrow) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 12),
            filterRow,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: searchField),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: filterRow),
        ],
      ),
    );
  }

  Widget _buildLoansTable(bool isNarrow) {
    final loans = _filteredLoans;

    if (loans.isEmpty) {
      return const Center(child: Text('No loans found'));
    }

    final table = DataTable(
      headingTextStyle: const TextStyle(
        color: AppColors.kTextMuted,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      columns: const [
        DataColumn(label: Text('LOAN NO')),
        DataColumn(label: Text('CUSTOMER')),
        DataColumn(label: Text('AMOUNT')),
        DataColumn(label: Text('EMI')),
        DataColumn(label: Text('OUTSTANDING')),
        DataColumn(label: Text('AGENT')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('START')),
        DataColumn(label: Text('ACTIONS')),
      ],
      rows: loans.map((loan) {
        return DataRow(cells: [
          DataCell(Text(loan.loanNumber,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(loan.customerName)),
          DataCell(Text(loan.formattedAmount)),
          DataCell(Text(loan.formattedEmi)),
          DataCell(Text(loan.formattedOutstanding,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(loan.agentName)),
          DataCell(
              StatusBadge(label: loan.status, tone: _toneFor(loan.status))),
          DataCell(Text(loan.startDate ?? '-')),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                color: AppColors.kTextMuted,
                onPressed: () => _showViewLoanDialog(loan),
                tooltip: 'View',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.kTextMuted,
                onPressed: () => _showEditLoanDialog(loan),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.block_outlined, size: 20),
                color: AppColors.kDanger,
                onPressed: () => _showCloseLoanDialog(loan),
                tooltip: 'Block/Delete',
              ),
            ],
          )),
        ]);
      }).toList(),
    );

    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: isNarrow ? 12.0 : 24.0, vertical: 8.0),
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
              constraints: const BoxConstraints(minWidth: 980),
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

// ==========================================
// VIEW LOAN DETAIL SHEET
// ==========================================
class LoanDetailDialog extends StatefulWidget {
  final LoanRecord loan;
  final VoidCallback? onDelete;

  const LoanDetailDialog({super.key, required this.loan, this.onDelete});

  @override
  State<LoanDetailDialog> createState() => _LoanDetailDialogState();
}

class _LoanDetailDialogState extends State<LoanDetailDialog> {
  bool _showSchedule = false;
  List<RepaymentEntry> _schedule = [];

  BadgeTone _toneFor(String status) {
    switch (status) {
      case 'Active':
        return BadgeTone.success;
      case 'Overdue':
        return BadgeTone.danger;
      case 'Closed':
        return BadgeTone.neutral;
      default:
        return BadgeTone.warning;
    }
  }

  String _durationLabel(LoanRecord loan) {
    switch (loan.collectionType) {
      case 'Weekly':
        return '${loan.durationUnits} weeks';
      case 'Daily':
        return '${loan.durationUnits} days';
      default:
        return '${loan.durationUnits} months';
    }
  }

  void _regenerateSchedule() {
    final loan = widget.loan;
    final startDate = tryParseFlexibleDate(loan.startDate ?? '');
    if (startDate == null || loan.principalAmount <= 0 || loan.emiAmount <= 0) {
      _schedule = [];
      return;
    }

    final periods = loan.durationUnits;
    // For Weekly/Daily, interest is deducted upfront so the borrower repays
    // exactly the principal back over the periods. For Monthly the EMI is
    // amortized, so total repayment = emi * periods.
    final totalAmount = loan.collectionType == 'Monthly'
        ? loan.emiAmount * periods
        : loan.principalAmount;

    final entries = buildRepaymentSchedule(
      collectionType: loan.collectionType,
      startDate: startDate,
      periods: periods,
      installment: loan.emiAmount,
      totalAmount: totalAmount,
    );
    applyPlaceholderScheduleStatus(entries, loan.status);
    _schedule = entries;
  }

  void _toggleSchedule() {
    setState(() {
      _showSchedule = !_showSchedule;
      if (_showSchedule) _regenerateSchedule();
    });
  }

  Widget _field(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.kBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextDark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Loan ${loan.loanNumber}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
          const SizedBox(height: 20),

          // Responsive field grid: 1 column on phones, 2 on tablets, 4 on desktop.
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cols = width < 420 ? 1 : (width < 700 ? 2 : 4);
            const spacing = 8.0;
            final cellWidth = (width - spacing * (cols - 1)) / cols;

            final fields = <MapEntry<String, String>>[
              MapEntry('Customer', loan.customerName),
              MapEntry('Loan Amount', loan.formattedAmount),
              MapEntry('EMI', loan.formattedEmi),
              MapEntry('Outstanding', loan.formattedOutstanding),
              MapEntry('Interest', '${loan.interestRate.toStringAsFixed(0)}%'),
              MapEntry('Duration', _durationLabel(loan)),
              MapEntry('Start Date', loan.startDate ?? '-'),
              MapEntry('Agent', loan.agentName),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: fields
                  .map((f) =>
                      SizedBox(width: cellWidth, child: _field(f.key, f.value)))
                  .toList(),
            );
          }),

          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              StatusBadge(label: loan.status, tone: _toneFor(loan.status)),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _toggleSchedule,
                    icon: Icon(
                        _showSchedule
                            ? Icons.expand_less
                            : Icons.description_outlined,
                        size: 18),
                    label: Text(_showSchedule ? 'Hide Schedule' : 'Schedule'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Downloading ${loan.loanNumber}')),
                      );
                    },
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kDanger,
                      side: const BorderSide(color: AppColors.kDanger),
                    ),
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),

          if (_showSchedule) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.description_outlined,
                    size: 18, color: AppColors.kTextMuted),
                const SizedBox(width: 8),
                const Text('Repayment Schedule',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextDark)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh Schedule',
                  onPressed: () => setState(_regenerateSchedule),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.kBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: RepaymentScheduleTable(
                entries: _schedule,
                showPaymentColumns: true,
                maxHeight: 320,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// CREATE / EDIT LOAN SHEET
// ==========================================
class LoanFormDialog extends StatefulWidget {
  final LoanRecord? loan;
  final List<Customer> customers;
  final List<Agent> agents;

  /// Called with the payload to send to the backend. Returns the saved
  /// loan record so the form can create repayment schedule rows afterward.
  final Future<LoanRecord> Function(Map<String, dynamic> data,
      {required bool approve}) onSubmit;

  const LoanFormDialog({
    super.key,
    this.loan,
    required this.customers,
    required this.agents,
    required this.onSubmit,
  });

  bool get isEdit => loan != null;

  @override
  State<LoanFormDialog> createState() => _LoanFormDialogState();
}

class _LoanFormDialogState extends State<LoanFormDialog> {
  // Collection Type State: 'Monthly' | 'Weekly' | 'Daily'
  String _collectionType = 'Monthly';

  // Specific state presets
  String _weeklyInterestRate = '10%'; // '10%' or '12%'
  String _dailyPlan = '60 Days · 20%'; // '60 Days · 20%' or '100 Days · 15%'

  Customer? _selectedCustomer;
  Agent? _selectedAgent;
  bool _saving = false;

  late final TextEditingController _loanNumberController;
  late final TextEditingController _amountController;
  late final TextEditingController _interestController;
  late final TextEditingController _durationController;
  late final TextEditingController _startDateController;
  late final TextEditingController _feeController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    _collectionType = loan?.collectionType ?? 'Monthly';

    if (loan != null) {
      Customer? findCustomer() {
        for (final c in widget.customers) {
          if (c.id == loan.customerId) return c;
        }
        return null;
      }

      Agent? findAgent() {
        for (final a in widget.agents) {
          if (a.id == loan.agentId) return a;
        }
        return null;
      }

      _selectedCustomer = findCustomer();
      _selectedAgent = findAgent();

      if (_collectionType == 'Weekly') {
        _weeklyInterestRate = '${loan.interestRate.toStringAsFixed(0)}%';
      } else if (_collectionType == 'Daily') {
        _dailyPlan =
            '${loan.durationUnits} Days · ${loan.interestRate.toStringAsFixed(0)}%';
      }
    }

    _loanNumberController = TextEditingController(text: loan?.loanNumber ?? '');
    _amountController = TextEditingController(
        text: loan != null ? loan.principalAmount.toStringAsFixed(0) : '');
    _interestController = TextEditingController(
        text: loan != null && _collectionType == 'Monthly'
            ? loan.interestRate.toStringAsFixed(0)
            : '12');
    _durationController = TextEditingController(
        text: loan != null
            ? loan.durationUnits.toString()
            : (_collectionType == 'Weekly' ? '10' : '12'));
    _startDateController = TextEditingController(text: loan?.startDate ?? '');
    _feeController = TextEditingController(
        text: loan != null ? loan.processingFee.toStringAsFixed(0) : '');
    _notesController = TextEditingController(text: loan?.notes ?? '');

    // Live recalculation: any keystroke in these fields immediately updates
    // the summary cards + schedule preview below via setState.
    _amountController.addListener(_rebuild);
    _interestController.addListener(_rebuild);
    _durationController.addListener(_rebuild);
    _startDateController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _amountController.removeListener(_rebuild);
    _interestController.removeListener(_rebuild);
    _durationController.removeListener(_rebuild);
    _startDateController.removeListener(_rebuild);

    _loanNumberController.dispose();
    _amountController.dispose();
    _interestController.dispose();
    _durationController.dispose();
    _startDateController.dispose();
    _feeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Helper parsing methods
  double get _principal => double.tryParse(_amountController.text) ?? 0.0;
  double get _monthlyInterestRate =>
      double.tryParse(_interestController.text) ?? 0.0;
  int get _duration => int.tryParse(_durationController.text) ?? 0;

  Future<void> _handleSave({bool approve = false}) async {
    if (_selectedCustomer == null) {
      ToastService.show(
        title: 'Customer required',
        message: 'Select a customer before saving',
        type: ToastType.error,
      );
      return;
    }

    final payload = _buildPayload(approve: approve);

    setState(() => _saving = true);
    try {
      final loan = await widget.onSubmit(payload, approve: approve);
      if (!widget.isEdit) {
        await _createRepaymentScheduleForLoan(loan);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: 'Could not save loan',
        message: e.toString(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createRepaymentScheduleForLoan(LoanRecord loan) async {
    final startDate = tryParseFlexibleDate(_startDateController.text);
    if (startDate == null || _principal <= 0) return;

    int periods;
    double installment;
    double totalAmount;

    switch (_collectionType) {
      case 'Weekly':
        periods = _duration > 0 ? _duration : 10;
        installment = _calcWeeklyInstallment();
        totalAmount = _principal;
        break;
      case 'Daily':
        periods = _getDailyDays();
        installment = _calcDailyInstallment();
        totalAmount = _principal;
        break;
      default:
        periods = _duration;
        installment = _calcMonthlyEmi();
        totalAmount = installment * periods;
    }

    if (periods <= 0 || installment <= 0) return;

    final entries = buildRepaymentSchedule(
      collectionType: _collectionType,
      startDate: startDate,
      periods: periods,
      installment: installment,
      totalAmount: totalAmount,
    );

    for (final entry in entries) {
      final row = {
        'loan_id': loan.id,
        'installment_no': entry.index,
        'due_date': entry.dueDate.toIso8601String().split('T').first,
        'emi_amount': entry.amount,
        'paid_amount': 0,
        'balance': entry.amount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
      await ApiClient.instance.create('repayment_schedule', row);
    }
  }

  Map<String, dynamic> _buildPayload({required bool approve}) {
    /// Converts a 'DD/MM/YYYY' (or 'D/M/YYYY') string to 'YYYY-MM-DD' for the backend.
    /// Returns null if the input can't be parsed.
    String? toIsoDate(String input) {
      final trimmed = input.trim();
      if (trimmed.isEmpty) return null;

      // Already ISO?
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) return trimmed;

      final parts = trimmed.split('/');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) return null;

      final mm = month.toString().padLeft(2, '0');
      final dd = day.toString().padLeft(2, '0');
      return '$year-$mm-$dd';
    }

    double interestRate;
    int durationUnits;
    switch (_collectionType) {
      case 'Weekly':
        interestRate = _getWeeklyInterestPercent();
        durationUnits = _duration > 0 ? _duration : 10;
        break;
      case 'Daily':
        interestRate = _getDailyInterestPercent();
        durationUnits = _getDailyDays();
        break;
      default:
        interestRate = _monthlyInterestRate;
        durationUnits = _duration;
    }

    return <String, dynamic>{
      // Omitted on create so the server auto-generates it
      // (see LoanController::fillLoanNumbers()).
      if (widget.isEdit) 'loan_number': _loanNumberController.text,
      'customer_id': _selectedCustomer?.id,
      if (_selectedCustomer?.name.isNotEmpty == true)
        'customer_name': _selectedCustomer!.name,
      'assigned_agent': _selectedAgent?.id,
      if (_selectedAgent?.name.isNotEmpty == true)
        'agent_name': _selectedAgent!.name,
      'loan_amount': _principal,
      'interest_percentage': interestRate,
      'loan_duration': durationUnits,
      'loan_type': _collectionType.toLowerCase(),
      'start_date':
          toIsoDate(_startDateController.text) ?? _startDateController.text,
      'outstanding_balance': widget.loan?.outstandingBalance ?? _principal,
      'emi': _currentInstallment(),
      'processing_fee': double.tryParse(_feeController.text) ?? 0,
      'status':
          approve ? 'active' : (widget.loan?.status.toLowerCase() ?? 'pending'),
      if (_notesController.text.isNotEmpty) 'notes': _notesController.text,
    };
  }

  double _currentInstallment() {
    switch (_collectionType) {
      case 'Weekly':
        return _calcWeeklyInstallment();
      case 'Daily':
        return _calcDailyInstallment();
      default:
        return _calcMonthlyEmi();
    }
  }

  // --- Monthly Calculation Logic ---
  // Standard reducing-balance (amortized) EMI formula:
  //   EMI = P * r * (1+r)^n / ((1+r)^n - 1)
  // where r is the *monthly* interest rate (annual % / 12 / 100) and n is
  // the number of months. This matches how banks/NBFCs actually compute
  // EMIs — flat interest (P * rate% * years) overstates interest and was
  // producing the wrong numbers before.
  double _calcMonthlyEmi() {
    if (_principal <= 0 || _duration <= 0) return 0;
    final r = _monthlyInterestRate / 100 / 12;
    if (r <= 0) return _principal / _duration;
    final factor = math.pow(1 + r, _duration).toDouble();
    return _principal * r * factor / (factor - 1);
  }

  double _calcMonthlyInterest() {
    if (_principal <= 0 || _duration <= 0) return 0;
    return _calcMonthlyEmi() * _duration - _principal;
  }

  // --- Weekly Calculation Logic ---
  // Interest is deducted upfront from the disbursed amount; the borrower
  // repays the full principal back in equal weekly installments.
  double _getWeeklyInterestPercent() =>
      _weeklyInterestRate == '10%' ? 10.0 : 12.0;

  double _calcWeeklyDeductedInterest() =>
      _principal * (_getWeeklyInterestPercent() / 100);

  double _calcWeeklyInstallment() {
    final weeks = _duration > 0 ? _duration : 10;
    return _principal > 0 ? _principal / weeks : 0;
  }

  double _calcWeeklyDisbursed() =>
      (_principal - _calcWeeklyDeductedInterest()).clamp(0, double.infinity);

  // --- Daily Calculation Logic ---
  // Same upfront-deduction model as Weekly: installment = principal / days,
  // interest is deducted from what's disbursed rather than added on top.
  int _getDailyDays() => _dailyPlan.contains('60') ? 60 : 100;
  double _getDailyInterestPercent() => _dailyPlan.contains('20%') ? 20.0 : 15.0;

  double _calcDailyDeductedInterest() =>
      _principal * (_getDailyInterestPercent() / 100);

  double _calcDailyInstallment() {
    final days = _getDailyDays();
    return days > 0 && _principal > 0 ? _principal / days : 0;
  }

  double _calcDailyDisbursed() =>
      (_principal - _calcDailyDeductedInterest()).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.isEdit ? 'Edit Loan' : 'Create Loan',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
              )
            ],
          ),
          const SizedBox(height: 20),

          _buildCollectionTypeSelector(),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Column(
                children: [
                  _responsiveRow(
                    isNarrow,
                    _buildTextField('LOAN NUMBER',
                        widget.isEdit ? '' : 'Auto-generated by server',
                        enabled: false, controller: _loanNumberController),
                    _buildCustomerField(),
                  ),
                  const SizedBox(height: 16),
                  _buildDynamicMiddleInputs(isNarrow),
                  const SizedBox(height: 16),
                  _responsiveRow(
                    isNarrow,
                    _buildAgentField(),
                    _buildTextField('PROCESSING FEE', '₹0',
                        controller: _feeController),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTextField('NOTES', 'Optional notes...',
              maxLines: 2, controller: _notesController),
          const SizedBox(height: 24),

          _buildDynamicSummarySection(),
          const SizedBox(height: 24),

          _buildScheduleSection(),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _saving ? null : () => _handleSave(),
                child: const Text('Save'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kSuccess),
                onPressed: _saving ? null : () => _handleSave(approve: true),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Approve'),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Searchable dropdown for the customer this loan belongs to.
  Widget _buildCustomerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CUSTOMER *',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        Autocomplete<Customer>(
          displayStringForOption: (c) => c.name,
          initialValue: TextEditingValue(text: _selectedCustomer?.name ?? ''),
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) return widget.customers;
            final q = value.text.toLowerCase();
            return widget.customers
                .where((c) => c.name.toLowerCase().contains(q));
          },
          onSelected: (c) => setState(() => _selectedCustomer = c),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Select customer...',
                isDense: true,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 220, maxWidth: 300),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: options
                        .map((c) => ListTile(
                              dense: true,
                              title: Text(c.name),
                              subtitle: c.phone != null ? Text(c.phone!) : null,
                              onTap: () => onSelected(c),
                            ))
                        .toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Searchable dropdown for the agent assigned to this loan.
  Widget _buildAgentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ASSIGNED AGENT',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        Autocomplete<Agent>(
          displayStringForOption: (a) => a.name,
          initialValue: TextEditingValue(text: _selectedAgent?.name ?? ''),
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) return widget.agents;
            final q = value.text.toLowerCase();
            return widget.agents.where((a) => a.name.toLowerCase().contains(q));
          },
          onSelected: (a) => setState(() => _selectedAgent = a),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Unassigned',
                isDense: true,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 220, maxWidth: 300),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: options
                        .map((a) => ListTile(
                              dense: true,
                              title: Text(a.name),
                              onTap: () => onSelected(a),
                            ))
                        .toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Collection Type Selector Bar
  Widget _buildCollectionTypeSelector() {
    final options = ['Monthly', 'Weekly', 'Daily'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COLLECTION TYPE',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.kBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: options.map((type) {
              final isSelected = _collectionType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _collectionType = type;
                      if (_collectionType == 'Weekly' &&
                          _durationController.text.isEmpty) {
                        _durationController.text = '10';
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppColors.kGold
                              : AppColors.kTextMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Dynamic Middle Inputs based on Collection Type
  Widget _buildDynamicMiddleInputs(bool isNarrow) {
    if (_collectionType == 'Monthly') {
      return Column(
        children: [
          _responsiveRow(
            isNarrow,
            _buildTextField('LOAN AMOUNT *', '₹50,000',
                controller: _amountController),
            _buildTextField('INTEREST (% P.A.) *', '12',
                controller: _interestController),
          ),
          const SizedBox(height: 16),
          _responsiveRow(
            isNarrow,
            _buildTextField('DURATION (MONTHS) *', '12',
                controller: _durationController),
            _buildTextField('START DATE *', '10/07/2026',
                controller: _startDateController),
          ),
        ],
      );
    } else if (_collectionType == 'Weekly') {
      return Column(
        children: [
          _responsiveRow(
            isNarrow,
            _buildTextField('LOAN AMOUNT *', '₹50,000',
                controller: _amountController),
            _buildWeeklyInterestChips(),
          ),
          const SizedBox(height: 16),
          _responsiveRow(
            isNarrow,
            _buildTextField('DURATION (WEEKS) *', '10',
                controller: _durationController),
            _buildTextField('START DATE *', '10/07/2026',
                controller: _startDateController),
          ),
        ],
      );
    } else {
      // Daily Scheme
      return Column(
        children: [
          _responsiveRow(
            isNarrow,
            _buildTextField('LOAN AMOUNT *', '₹50,000',
                controller: _amountController),
            _buildDailyPlanChips(),
          ),
          const SizedBox(height: 16),
          _responsiveRow(
            isNarrow,
            _buildTextField('START DATE *', '10/07/2026',
                controller: _startDateController),
            Container(), // Spacer placeholder
          ),
        ],
      );
    }
  }

  Widget _buildWeeklyInterestChips() {
    final rates = ['10%', '12%'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('INTEREST RATE *',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(rates.length, (index) {
            final rate = rates[index];
            final selected = _weeklyInterestRate == rate;
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: index == rates.length - 1 ? 0 : 8),
                child: ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  label: Center(
                      child: Text(rate,
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                  selected: selected,
                  selectedColor: AppColors.kGold,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : AppColors.kTextDark,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _weeklyInterestRate = rate);
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDailyPlanChips() {
    final plans = ['60 Days · 20%', '100 Days · 15%'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COLLECTION PLAN *',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(plans.length, (index) {
            final plan = plans[index];
            final selected = _dailyPlan == plan;
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: index == plans.length - 1 ? 0 : 8),
                child: ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  label: Center(
                      child: Text(plan,
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                  selected: selected,
                  selectedColor: AppColors.kGold,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : AppColors.kTextDark,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _dailyPlan = plan);
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Dynamic Calculation Display Section — rebuilds on every keystroke because
  // the amount/interest/duration controllers call setState via _rebuild().
  Widget _buildDynamicSummarySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        List<Widget> cards = [];

        if (_collectionType == 'Monthly') {
          final totalInterest = _calcMonthlyInterest();
          final totalRepayment = _principal + totalInterest;
          final emi = _calcMonthlyEmi();

          cards = [
            _buildSummaryCard('EMI', '₹${emi.toStringAsFixed(0)}',
                const Color(0xFFF0F5FF), AppColors.kInfo),
            _buildSummaryCard(
                'Interest (added)',
                '₹${totalInterest.toStringAsFixed(0)}',
                const Color(0xFFFFFBEB),
                AppColors.kWarning),
            _buildSummaryCard(
                'Amount Disbursed to Borrower',
                '₹${totalRepayment.toStringAsFixed(0)}',
                const Color(0xFFF0FDF4),
                AppColors.kSuccess),
          ];
        } else if (_collectionType == 'Weekly') {
          final weeks = _duration > 0 ? _duration : 10;
          final installment = _calcWeeklyInstallment();
          final deductedInterest = _calcWeeklyDeductedInterest();
          final disbursed = _calcWeeklyDisbursed();

          cards = [
            _buildSummaryCard(
                'Weekly Installment',
                '₹${installment.toStringAsFixed(0)}',
                const Color(0xFFF0F5FF),
                AppColors.kInfo,
                subtitle: '× $weeks weeks = ₹${_principal.toStringAsFixed(0)}'),
            _buildSummaryCard(
                'Interest (deducted)',
                '₹${deductedInterest.toStringAsFixed(0)}',
                const Color(0xFFFFFBEB),
                AppColors.kWarning,
                subtitle: 'Deducted upfront'),
            _buildSummaryCard(
                'Amount Disbursed',
                '₹${disbursed.toStringAsFixed(0)}',
                const Color(0xFFF0FDF4),
                AppColors.kSuccess,
                subtitle: 'Principal − Interest'),
          ];
        } else {
          // Daily Scheme Summary — same upfront-deduction model as Weekly.
          final days = _getDailyDays();
          final installment = _calcDailyInstallment();
          final deductedInterest = _calcDailyDeductedInterest();
          final disbursed = _calcDailyDisbursed();

          cards = [
            _buildSummaryCard(
                'Daily Installment',
                '₹${installment.toStringAsFixed(0)}',
                const Color(0xFFF0F5FF),
                AppColors.kInfo,
                subtitle: '× $days days = ₹${_principal.toStringAsFixed(0)}'),
            _buildSummaryCard(
                'Interest (deducted)',
                '₹${deductedInterest.toStringAsFixed(0)}',
                const Color(0xFFFFFBEB),
                AppColors.kWarning,
                subtitle: 'Deducted upfront'),
            _buildSummaryCard(
                'Amount Disbursed to Borrower',
                '₹${disbursed.toStringAsFixed(0)}',
                const Color(0xFFF0FDF4),
                AppColors.kSuccess,
                subtitle: 'Principal − Interest'),
          ];
        }

        if (isNarrow) {
          return Column(
            children: [
              for (final c in cards) ...[
                SizedBox(width: double.infinity, child: c),
                const SizedBox(height: 12),
              ]
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ]
          ],
        );
      },
    );
  }

  // Repayment Schedule Preview — recomputes live as the amount / interest /
  // duration / start-date fields change. Pure preview, no payment data
  // (that only exists once a real loan/repayments record is saved).
  Widget _buildScheduleSection() {
    final startDate = tryParseFlexibleDate(_startDateController.text);
    if (_principal <= 0 || startDate == null) {
      return const SizedBox.shrink();
    }

    int periods;
    double installment;
    double totalAmount;

    switch (_collectionType) {
      case 'Weekly':
        periods = _duration > 0 ? _duration : 10;
        installment = _calcWeeklyInstallment();
        totalAmount = _principal;
        break;
      case 'Daily':
        periods = _getDailyDays();
        installment = _calcDailyInstallment();
        totalAmount = _principal;
        break;
      default:
        periods = _duration;
        installment = _calcMonthlyEmi();
        totalAmount = installment * periods;
    }

    if (periods <= 0 || installment <= 0) {
      return const SizedBox.shrink();
    }

    final schedule = buildRepaymentSchedule(
      collectionType: _collectionType,
      startDate: startDate,
      periods: periods,
      installment: installment,
      totalAmount: totalAmount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.description_outlined,
                size: 18, color: AppColors.kTextMuted),
            SizedBox(width: 8),
            Text('Repayment Schedule Preview',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.kTextDark)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.kBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: RepaymentScheduleTable(entries: schedule),
        ),
      ],
    );
  }

  Widget _responsiveRow(bool isNarrow, Widget a, Widget b) {
    if (isNarrow) {
      return Column(children: [a, const SizedBox(height: 16), b]);
    }
    return Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );
  }

  Widget _buildTextField(String label, String hint,
      {bool enabled = true,
      TextEditingController? controller,
      int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: label.contains('AMOUNT') ||
                  label.contains('INTEREST') ||
                  label.contains('DURATION')
              ? TextInputType.number
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color bgColor, Color textColor,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: 10,
                  color: textColor.withOpacity(0.75),
                  fontWeight: FontWeight.w500),
            ),
          ]
        ],
      ),
    );
  }
}
