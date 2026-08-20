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
import '../../models/user_role.dart';
import '../../services/loan_service.dart';
import '../../services/api_client.dart';
import '../../services/session_service.dart';

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
/// [collectionType] here is the *frequency* the schedule repeats on —
/// 'Monthly', 'Weekly', or anything else is treated as 'Daily'. Both the
/// "Monthly EMI" and "Monthly Interest" products repay monthly, so callers
/// pass 'Monthly' for either — the distinction only affects how the
/// installment amount itself was calculated upstream, not the due-date math.
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
  '',  'Jan',  'Feb',  'Mar',  'Apr',  'May',  'Jun',
       'Jul',  'Aug',  'Sep',  'Oct',  'Nov',  'Dec',
];

String _formatScheduleDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_kMonthNames[d.month]} ${d.year}';

const String kMonthlyInterestSubtypeMarker = '[[subtype:monthly_interest]]';

bool loanHasMonthlyInterestMarker(String? notes) =>
    notes != null && notes.contains(kMonthlyInterestSubtypeMarker);

String stripMonthlyInterestMarker(String? notes) =>
    (notes ?? '').replaceAll(kMonthlyInterestSubtypeMarker, '').trim();

String friendlyCollectionTypeLabel(LoanRecord loan) {
  switch (loan.collectionType) {
    case 'Monthly':
      return loanHasMonthlyInterestMarker(loan.notes)
          ? 'Monthly Interest'
          : 'Monthly EMI';
    case 'Weekly':
      return 'Weekly';
    case 'Daily':
      return 'Daily';
    default:
      return loan.collectionType;
  }
}

String fmtRate(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

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
    'All',    'Active',    'Overdue',    'Closed',    'Pending'
  ];

  final LoanService _loanService = LoanService.instance;

  bool get _isCustomer =>
      SessionService.instance.currentUser?.role == UserRole.customer;

  String? get _customerId =>
      SessionService.instance.currentUser?.customerId?.toString();

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
      final filteredLoans = _isCustomer && _customerId != null
          ? loans.where((loan) => loan.customerId == _customerId).toList()
          : loans;
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _agents = agents;
        _loans = filteredLoans;
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
                  if (!_isCustomer)
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
        DataColumn(label: Text('HP NO')),
        DataColumn(label: Text('CUSTOMER')),
        DataColumn(label: Text('TYPE')),
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
          DataCell(Text(friendlyCollectionTypeLabel(loan))),
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
              if (!_isCustomer) ...[
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
              constraints: const BoxConstraints(minWidth: 1080),
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
        return loanHasMonthlyInterestMarker(loan.notes)
            ? '${loan.durationUnits} months (interest-only)'
            : '${loan.durationUnits} months';
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

    final double totalAmount;
    switch (loan.collectionType) {
      case 'Daily':
        totalAmount =
            loan.principalAmount + loan.principalAmount * (loan.interestRate / 100);
        break;
      case 'Weekly':
        totalAmount = loan.principalAmount;
        break;
      default: // Monthly (EMI or Interest-only)
        totalAmount = loan.emiAmount * periods;
    }

    final scheduleFrequency =
        loan.collectionType == 'Weekly' || loan.collectionType == 'Daily'
            ? loan.collectionType
            : 'Monthly';

    final entries = buildRepaymentSchedule(
      collectionType: scheduleFrequency,
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
    final isInterestOnly = loan.collectionType == 'Monthly' &&
        loanHasMonthlyInterestMarker(loan.notes);
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

          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cols = width < 420 ? 1 : (width < 700 ? 2 : 4);
            const spacing = 8.0;
            final cellWidth = (width - spacing * (cols - 1)) / cols;

            final fields = <MapEntry<String, String>>[
              MapEntry('Customer', loan.customerName),
              MapEntry('Loan Type', friendlyCollectionTypeLabel(loan)),
              MapEntry('Loan Amount', loan.formattedAmount),
              MapEntry(isInterestOnly ? 'Monthly Interest' : 'EMI',
                  loan.formattedEmi),
              MapEntry('Outstanding', loan.formattedOutstanding),
              MapEntry('Interest', '${fmtRate(loan.interestRate)}%'),
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
            if (isInterestOnly) ...[
              const SizedBox(height: 4),
              const Text(
                'Interest-only schedule — principal can be repaid separately, anytime.',
                style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
              ),
            ],
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

class LoanFormDialog extends StatefulWidget {
  final LoanRecord? loan;
  final List<Customer> customers;
  final List<Agent> agents;
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

class _LoanTypeOption {
  final String key;
  const _LoanTypeOption(this.key);
}

const List<_LoanTypeOption> _kLoanTypeOptions = [
  _LoanTypeOption('Monthly EMI'),
  _LoanTypeOption('Monthly Interest'),
  _LoanTypeOption('Weekly'),
  _LoanTypeOption('Daily'),
];

class _LoanFormDialogState extends State<LoanFormDialog> {
  String _collectionType = 'Monthly EMI';
  int _dailyDays = 60;

  Customer? _selectedCustomer;
  Agent? _selectedAgent;
  bool _saving = false;

  bool _loadingHpNumber = false;

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

    if (loan != null) {
      _collectionType = loan.collectionType == 'Monthly'
          ? (loanHasMonthlyInterestMarker(loan.notes)
              ? 'Monthly Interest'
              : 'Monthly EMI')
          : loan.collectionType; // 'Weekly' or 'Daily'
      if (_collectionType == 'Daily') {
        _dailyDays = loan.durationUnits == 100 ? 100 : 60;
      }

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
    }

    _loanNumberController = TextEditingController(text: loan?.loanNumber ?? '');
    _amountController = TextEditingController(
        text: loan != null ? loan.principalAmount.toStringAsFixed(0) : '');
    _interestController = TextEditingController(
        text: loan != null ? fmtRate(loan.interestRate) : _defaultRateFor(_collectionType));
    _durationController = TextEditingController(
        text: loan != null &&
                (_collectionType == 'Monthly EMI' ||
                    _collectionType == 'Monthly Interest')
            ? loan.durationUnits.toString()
            : '10');
    _startDateController = TextEditingController(text: loan?.startDate ?? '');
    _feeController = TextEditingController(
        text: loan != null ? loan.processingFee.toStringAsFixed(0) : '');
    _notesController =
        TextEditingController(text: stripMonthlyInterestMarker(loan?.notes));

    // Live recalculation: any keystroke in these fields immediately updates
    // the summary cards + schedule preview below via setState.
    _amountController.addListener(_rebuild);
    _interestController.addListener(_rebuild);
    _durationController.addListener(_rebuild);
    _startDateController.addListener(_rebuild);

    if (!widget.isEdit) {
      _fetchNextHpNumber();
    }
  }

  void _rebuild() => setState(() {});

  String _defaultRateFor(String type) {
    switch (type) {
      case 'Weekly':
        return '10';
      case 'Daily':
        return '15';
      default:
        return '2.5';
    }
  }

  Future<void> _fetchNextHpNumber() async {
    setState(() => _loadingHpNumber = true);
    try {
      final dynamic result = await ApiClient.instance
          .list('loans', query: {'action': 'next_hp_number'});
      String? next;
      if (result is Map && result['next_hp_number'] != null) {
        next = result['next_hp_number'].toString();
      } else if (result is List &&
          result.isNotEmpty &&
          result.first is Map &&
          (result.first as Map)['next_hp_number'] != null) {
        next = (result.first as Map)['next_hp_number'].toString();
      }
      if (mounted && next != null && next.isNotEmpty) {
        setState(() => _loanNumberController.text = next!);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingHpNumber = false);
    }
  }

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

  double get _principal => double.tryParse(_amountController.text) ?? 0.0;
  double get _interestRate => double.tryParse(_interestController.text) ?? 0.0;

  int get _duration {
    switch (_collectionType) {
      case 'Weekly':
        return 10; // Fixed product: always 10 weeks.
      case 'Daily':
        return _dailyDays;
      default: // Monthly EMI / Monthly Interest
        return int.tryParse(_durationController.text) ?? 0;
    }
  }

  String get _loanTypeForBackend {
    switch (_collectionType) {
      case 'Weekly':
        return 'weekly';
      case 'Daily':
        return 'daily';
      default:
        return 'monthly'; // Both Monthly products share this enum value.
    }
  }

  String _buildNotesForSave() {
    final base = _notesController.text.trim();
    if (_collectionType == 'Monthly Interest') {
      return base.isEmpty
          ? kMonthlyInterestSubtypeMarker
          : '$base\n$kMonthlyInterestSubtypeMarker';
    }
    return base;
  }

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

    final periods = _duration;
    final installment = _currentInstallment();
    final totalAmount = _currentTotalRepaymentAmount();
    final frequency = (_collectionType == 'Weekly' || _collectionType == 'Daily')
        ? _collectionType
        : 'Monthly';

    if (periods <= 0 || installment <= 0) return;

    final entries = buildRepaymentSchedule(
      collectionType: frequency,
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

    final notesForSave = _buildNotesForSave();

    return <String, dynamic>{
      if (widget.isEdit) 'loan_number': _loanNumberController.text,
      'customer_id': _selectedCustomer?.id,
      if (_selectedCustomer?.name.isNotEmpty == true)
        'customer_name': _selectedCustomer!.name,
      'assigned_agent': _selectedAgent?.id,
      if (_selectedAgent?.name.isNotEmpty == true)
        'agent_name': _selectedAgent!.name,
      'loan_amount': _principal,
      'interest_percentage': _interestRate,
      'loan_duration': _duration,
      'loan_type': _loanTypeForBackend,
      'start_date':
          toIsoDate(_startDateController.text) ?? _startDateController.text,
      'outstanding_balance': widget.loan?.outstandingBalance ?? _principal,
      'emi': _currentInstallment(),
      'processing_fee': double.tryParse(_feeController.text) ?? 0,
      'status':
          approve ? 'active' : (widget.loan?.status.toLowerCase() ?? 'pending'),
      if (notesForSave.isNotEmpty) 'notes': notesForSave,
    };
  }

  double _currentInstallment() {
    switch (_collectionType) {
      case 'Monthly Interest':
        return _calcMonthlyInterestDue();
      case 'Weekly':
        return _calcWeeklyInstallment();
      case 'Daily':
        return _calcDailyInstallment();
      default:
        return _calcMonthlyEmiInstallment();
    }
  }

  /// The sum every installment in the schedule should add up to.
  double _currentTotalRepaymentAmount() {
    switch (_collectionType) {
      case 'Monthly Interest':
        return _calcMonthlyInterestDue() * _duration;
      case 'Weekly':
        return _principal; // Interest deducted upfront.
      case 'Daily':
        return _calcDailyTotalRepayment(); // Interest added on top.
      default:
        return _calcMonthlyEmiTotalRepayment();
    }
  }

  double _calcMonthlyEmiTotalInterest() =>
      (_principal > 0 && _duration > 0)
          ? _principal * (_interestRate / 100) * _duration
          : 0;

  double _calcMonthlyEmiTotalRepayment() =>
      _principal + _calcMonthlyEmiTotalInterest();

  double _calcMonthlyEmiInstallment() =>
      _duration > 0 ? _calcMonthlyEmiTotalRepayment() / _duration : 0;

  double _calcMonthlyInterestDue() => _principal * (_interestRate / 100);

  double _calcWeeklyInstallment() => _principal > 0 ? _principal / 10 : 0;

  double _calcWeeklyDeductedInterest() => _principal * (_interestRate / 100);

  double _calcWeeklyDisbursed() =>
      (_principal - _calcWeeklyDeductedInterest()).clamp(0, double.infinity);

  double _calcDailyAddedInterest() => _principal * (_interestRate / 100);

  double _calcDailyTotalRepayment() =>
      _principal + _calcDailyAddedInterest();

  double _calcDailyInstallment() =>
      _dailyDays > 0 ? _calcDailyTotalRepayment() / _dailyDays : 0;

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
                    _buildTextField('HP NUMBER',
                        widget.isEdit
                            ? ''
                            : (_loadingHpNumber
                                ? 'Loading...'
                                : 'Auto-generated by server'),
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
                suffixIcon: Icon(Icons.expand_more, size: 20),
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
                suffixIcon: Icon(Icons.expand_more, size: 20),
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

  Widget _buildCollectionTypeSelector() {
    Widget typeChip(_LoanTypeOption option) {
      final isSelected = _collectionType == option.key;
      return GestureDetector(
        onTap: () {
          setState(() {
            _collectionType = option.key;
            _interestController.text = _defaultRateFor(option.key);
            if (option.key == 'Daily') {
              _dailyDays = 60;
            } else if ((option.key == 'Monthly EMI' ||
                    option.key == 'Monthly Interest') &&
                _durationController.text.isEmpty) {
              _durationController.text = '10';
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : AppColors.kBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.kGold : AppColors.kBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            option.key,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.kGold : AppColors.kTextMuted,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COLLECTION / REPAYMENT TYPE',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 560;
          if (narrow) {
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.4,
              children: _kLoanTypeOptions.map(typeChip).toList(),
            );
          }
          return Row(
            children: [
              for (final option in _kLoanTypeOptions)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: typeChip(option),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  // Dynamic Middle Inputs based on Collection / Repayment Type
  Widget _buildDynamicMiddleInputs(bool isNarrow) {
    switch (_collectionType) {
      case 'Monthly EMI':
        return Column(
          children: [
            _responsiveRow(
              isNarrow,
              _buildTextField('LOAN AMOUNT *', '₹50,000',
                  controller: _amountController),
              _buildTextField('INTEREST RATE (% MONTHLY) *', '2.5',
                  controller: _interestController),
            ),
            const SizedBox(height: 16),
            _responsiveRow(
              isNarrow,
              _buildTextField('DURATION (MONTHS) *', '10',
                  controller: _durationController),
              _buildTextField('START DATE *', '10/07/2026',
                  controller: _startDateController),
            ),
          ],
        );

      case 'Monthly Interest':
        return Column(
          children: [
            _buildTextField('LOAN AMOUNT *', '₹50,000',
                controller: _amountController),
            const SizedBox(height: 16),
            _buildInterestOnlyInfoBox(),
            const SizedBox(height: 16),
            _responsiveRow(
              isNarrow,
              _buildRateFieldWithChips(
                  'MONTHLY INTEREST RATE (%) *', const [2, 2.5, 3, 4, 5]),
              _buildTextField(
                  'LOAN TENURE / DURATION (MONTHS) *', '10',
                  controller: _durationController),
            ),
            const SizedBox(height: 16),
            _buildTextField('START DATE *', '10/07/2026',
                controller: _startDateController),
          ],
        );

      case 'Weekly':
        return Column(
          children: [
            _responsiveRow(
              isNarrow,
              _buildTextField('LOAN AMOUNT *', '₹50,000',
                  controller: _amountController),
              _buildRateFieldWithChips('INTEREST RATE (%) *', const [10, 12]),
            ),
            const SizedBox(height: 16),
            _responsiveRow(
              isNarrow,
              _buildDisabledField('DURATION', '10 Weeks'),
              _buildTextField('START DATE *', '10/07/2026',
                  controller: _startDateController),
            ),
          ],
        );

      default: // Daily
        return Column(
          children: [
            _responsiveRow(
              isNarrow,
              _buildTextField('LOAN AMOUNT *', '₹50,000',
                  controller: _amountController),
              _buildRateFieldWithChips('INTEREST RATE (%) *', const [15, 20]),
            ),
            const SizedBox(height: 16),
            _responsiveRow(
              isNarrow,
              _buildDailyPlanDropdown(),
              _buildTextField('START DATE *', '10/07/2026',
                  controller: _startDateController),
            ),
          ],
        );
    }
  }

  Widget _buildRateFieldWithChips(String label, List<num> rates) {
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
          controller: _interestController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(isDense: true),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rates.map((r) {
            final rateLabel = fmtRate(r.toDouble());
            final selected = _interestRate == r.toDouble();
            return ChoiceChip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text('$rateLabel%'),
              selected: selected,
              selectedColor: AppColors.kGold,
              labelStyle: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : AppColors.kTextDark,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (val) {
                if (val) setState(() => _interestController.text = rateLabel);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // Disabled/read-only field for the fixed 10-week Weekly duration.
  Widget _buildDisabledField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.kBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Text(value,
              style: const TextStyle(fontSize: 14, color: AppColors.kTextDark)),
        ),
      ],
    );
  }

  // Daily collection plan / duration dropdown (60 or 100 days).
  Widget _buildDailyPlanDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COLLECTION PLAN / DURATION *',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _dailyDays,
          isExpanded: true,
          decoration: const InputDecoration(isDense: true),
          items: const [
            DropdownMenuItem(
              value: 60,
              child: Text('60 Days Plan (Interest Added to Repayment)',
                  overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 100,
              child: Text('100 Days Plan (Interest Added to Repayment)',
                  overflow: TextOverflow.ellipsis),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _dailyDays = v);
          },
        ),
      ],
    );
  }

  Widget _buildInterestOnlyInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kInfo.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Interest-Only Monthly with Flexible Principal Repayment',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.kTextDark),
                ),
                SizedBox(height: 4),
                Text(
                  'Borrowers pay only the interest amount every month. The principal amount can be repaid in flexible installments anytime whenever the borrower has funds available.',
                  style: TextStyle(fontSize: 12, color: AppColors.kInfo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dynamic Calculation Display Section — rebuilds on every keystroke because
  // the amount/interest/duration controllers call setState via _rebuild().
  Widget _buildDynamicSummarySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        List<Widget> cards = [];

        switch (_collectionType) {
          case 'Monthly EMI':
            {
              final totalInterest = _calcMonthlyEmiTotalInterest();
              final totalRepayment = _calcMonthlyEmiTotalRepayment();
              final emi = _calcMonthlyEmiInstallment();
              final perMonth = _duration > 0 ? totalInterest / _duration : 0;

              cards = [
                _buildSummaryCard('Monthly EMI', '₹${emi.toStringAsFixed(0)}',
                    const Color(0xFFFFFBEB), AppColors.kWarning,
                    subtitle: 'Per Month ($_duration Months)'),
                _buildSummaryCard(
                    'Total Interest',
                    '₹${totalInterest.toStringAsFixed(0)}',
                    const Color(0xFFFFFBEB),
                    AppColors.kWarning,
                    subtitle: '₹${perMonth.toStringAsFixed(0)} / month'),
                _buildSummaryCard(
                    'Total Repayment',
                    '₹${totalRepayment.toStringAsFixed(0)}',
                    const Color(0xFFF0FDF4),
                    AppColors.kSuccess,
                    subtitle: 'Principal + Total Interest'),
              ];
              break;
            }

          case 'Monthly Interest':
            {
              final due = _calcMonthlyInterestDue();
              cards = [
                _buildSummaryCard(
                    'MONTHLY INTEREST DUE',
                    '₹${due.toStringAsFixed(0)}',
                    const Color(0xFFF0F5FF),
                    AppColors.kInfo,
                    subtitle:
                        '${fmtRate(_interestRate)}% of ${LoanRecord.formatRupees(_principal)} / month'),
                _buildSummaryCard(
                    'PRINCIPAL REPAYMENT',
                    'Flexible Installments',
                    const Color(0xFFF0FDF4),
                    AppColors.kSuccess,
                    subtitle: 'Repay anytime whenever funds available'),
                _buildSummaryCard(
                    'PRINCIPAL DISBURSED',
                    LoanRecord.formatRupees(_principal),
                    const Color(0xFFFFFBEB),
                    AppColors.kWarning,
                    subtitle: 'Tenure: $_duration Months'),
              ];
              break;
            }

          case 'Weekly':
            {
              final installment = _calcWeeklyInstallment();
              final deductedInterest = _calcWeeklyDeductedInterest();
              final disbursed = _calcWeeklyDisbursed();

              cards = [
                _buildSummaryCard(
                    'Weekly Installment',
                    '₹${installment.toStringAsFixed(0)}',
                    const Color(0xFFF0F5FF),
                    AppColors.kInfo,
                    subtitle:
                        '× 10 weeks = ${LoanRecord.formatRupees(_principal)}'),
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
              break;
            }

          default: // Daily
            {
              final installment = _calcDailyInstallment();
              final addedInterest = _calcDailyAddedInterest();
              final totalRepayment = _calcDailyTotalRepayment();

              cards = [
                _buildSummaryCard(
                    'Daily Installment',
                    '₹${installment.toStringAsFixed(0)}',
                    const Color(0xFFF0F5FF),
                    AppColors.kInfo,
                    subtitle:
                        '× $_dailyDays days = ${LoanRecord.formatRupees(totalRepayment)}'),
                _buildSummaryCard(
                    'Interest (added)',
                    '₹${addedInterest.toStringAsFixed(0)}',
                    const Color(0xFFFFFBEB),
                    AppColors.kWarning,
                    subtitle: 'Added to repayment'),
                _buildSummaryCard(
                    'Amount Disbursed to Borrower',
                    LoanRecord.formatRupees(_principal),
                    const Color(0xFFF0FDF4),
                    AppColors.kSuccess,
                    subtitle: 'Full loan amount'),
              ];
            }
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

  Widget _buildScheduleSection() {
    final startDate = tryParseFlexibleDate(_startDateController.text);
    if (_principal <= 0 || startDate == null) {
      return const SizedBox.shrink();
    }

    final periods = _duration;
    final installment = _currentInstallment();
    final totalAmount = _currentTotalRepaymentAmount();

    if (periods <= 0 || installment <= 0) {
      return const SizedBox.shrink();
    }

    final frequency = (_collectionType == 'Weekly' || _collectionType == 'Daily')
        ? _collectionType
        : 'Monthly';

    final schedule = buildRepaymentSchedule(
      collectionType: frequency,
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
        if (_collectionType == 'Monthly Interest') ...[
          const SizedBox(height: 4),
          const Text(
            'Interest-only schedule — principal can be repaid separately, anytime.',
            style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
          ),
        ],
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
