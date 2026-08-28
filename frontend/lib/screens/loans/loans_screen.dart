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
import '../../l10n/generated/app_localizations.dart';

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
  String status; // 'Paid' | 'Overdue' | 'Due Today' | 'Pending' (internal keys)

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

/// Maps an internal status/type key (English constant used for comparisons,
/// API payloads, and business logic) to its localized display text. Covers
/// loan statuses, schedule-entry statuses, and the 'All' filter chip — they
/// share several words ('Overdue', 'Pending') so one mapping serves all.
String localizedStatusLabel(String key, AppLocalizations l10n) {
  switch (key) {
    case 'All':
      return l10n.loansFilterAll;
    case 'Active':
      return l10n.loansStatusActive;
    case 'Overdue':
      return l10n.loansStatusOverdue;
    case 'Closed':
      return l10n.loansStatusClosed;
    case 'Pending':
      return l10n.loansStatusPending;
    case 'Paid':
      return l10n.loansScheduleStatusPaid;
    case 'Due Today':
      return l10n.loansScheduleStatusDueToday;
    default:
      return key;
  }
}

/// Maps an internal collection-type-option key to its localized label.
String localizedCollectionTypeOption(String key, AppLocalizations l10n) {
  switch (key) {
    case 'Monthly EMI':
      return l10n.loansTypeMonthlyEmi;
    case 'Monthly Interest':
      return l10n.loansTypeMonthlyInterest;
    case 'Weekly':
      return l10n.loansTypeWeekly;
    case 'Daily':
      return l10n.loansTypeDaily;
    default:
      return key;
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
  'Dec',
];

String _formatScheduleDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_kMonthNames[d.month]} ${d.year}';

const String kMonthlyInterestSubtypeMarker = '[[subtype:monthly_interest]]';

bool loanHasMonthlyInterestMarker(String? notes) =>
    notes != null && notes.contains(kMonthlyInterestSubtypeMarker);

String stripMonthlyInterestMarker(String? notes) =>
    (notes ?? '').replaceAll(kMonthlyInterestSubtypeMarker, '').trim();

/// Internal (English) collection-type-option key for a loan — used for
/// comparisons. For the localized display string, pass the result through
/// [localizedCollectionTypeOption].
String collectionTypeOptionKey(LoanRecord loan) {
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

/// Localized, display-ready collection-type label for a loan.
String friendlyCollectionTypeLabel(LoanRecord loan, AppLocalizations l10n) =>
    localizedCollectionTypeOption(collectionTypeOptionKey(loan), l10n);

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
    final l10n = AppLocalizations.of(context);

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Text(
          l10n.loansScheduleEmptyMessage,
          style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
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
              SizedBox(
                  width: 28,
                  child: Text(l10n.loansScheduleColIndex, style: headerStyle)),
              Expanded(
                  flex: 2,
                  child:
                      Text(l10n.loansScheduleColDueDate, style: headerStyle)),
              Expanded(
                  child: Text(l10n.loansScheduleColEmi, style: headerStyle)),
              if (showPaymentColumns) ...[
                Expanded(
                    child:
                        Text(l10n.loansScheduleColPaid, style: headerStyle)),
                Expanded(
                    child: Text(l10n.loansScheduleColBalance,
                        style: headerStyle)),
                SizedBox(
                    width: 90,
                    child:
                        Text(l10n.loansScheduleColStatus, style: headerStyle)),
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
                      label: localizedStatusLabel(e.status, l10n),
                      tone: _scheduleStatusTone(e.status)),
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
  // Internal filter keys stay English; only the displayed chip text is
  // localized, via localizedStatusLabel().
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Active',
    'Overdue',
    'Closed',
    'Pending'
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
      final l10n = AppLocalizations.of(context);
      setState(() {
        _error = l10n.loansCouldNotLoad(e.toString());
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
    final l10n = AppLocalizations.of(context);
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
            _showLoanActionDialog(loan);
          },
          actionLabel:
              loan.status == 'Active' ? l10n.loansActionClose : l10n.loansActionDelete,
        ),
      ),
    );
  }

  void _showCreateLoanDialog() {
    final l10n = AppLocalizations.of(context);
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
              title: l10n.loansLoanCreatedTitle,
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
    final l10n = AppLocalizations.of(context);
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
              title: l10n.loansLoanUpdatedTitle,
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
    final l10n = AppLocalizations.of(context);

    // outstandingBalance is the authoritative pending figure — LoanRecalc.php
    // (server-side) already folds any accrued penalty into it, so a loan can
    // only ever be closed once the customer has paid everything down to ~0.
    if (loan.outstandingBalance > 0.01) {
      ToastService.show(
        title: l10n.loansCloseBlockedTitle,
        message: l10n.loansCloseBlockedMessage(loan.formattedOutstanding),
        type: ToastType.error,
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.loansCloseLoanTitle,
      message: l10n.loansCloseLoanMessage(loan.loanNumber),
      confirmLabel: l10n.loansCloseLoanConfirm,
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true && mounted) {
      try {
        final closedLoan = await _loanService.closeLoan(loan.id);
        final closedIndex = _loans.indexWhere((item) => item.id == loan.id);
        if (!mounted) return;
        if (closedIndex != -1) {
          setState(() {
            _loans[closedIndex] = closedLoan.copyWith(
              status: 'Closed',
              customerName: loan.customerName,
              agentName: loan.agentName,
            );
          });
        }
        ToastService.show(
          title: l10n.loansLoanClosedTitle,
          message: l10n.loansLoanClosedMessage(loan.loanNumber),
          type: ToastType.success,
        );
      } catch (e) {
        if (!mounted) return;
        ToastService.show(
          title: l10n.loansCloseFailedTitle,
          message: e.toString(),
          type: ToastType.error,
        );
      }
    }
  }

  void _showLoanActionDialog(LoanRecord loan) {
    if (loan.status == 'Active') {
      _showCloseLoanDialog(loan);
    } else {
      _showDeleteLoanDialog(loan);
    }
  }

  Future<void> _showDeleteLoanDialog(LoanRecord loan) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.loansDeleteLoanTitle,
      message: l10n.loansDeleteLoanMessage(loan.loanNumber),
      confirmLabel: l10n.loansDeleteLoanConfirm,
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true && mounted) {
      try {
        await _loanService.deleteLoan(loan.id);
        await _loadAll();
        if (!mounted) return;
        ToastService.show(
          title: l10n.loansLoanDeletedTitle,
          message: l10n.loansLoanDeletedMessage(loan.loanNumber),
          type: ToastType.success,
        );
      } catch (e) {
        if (!mounted) return;
        ToastService.show(
          title: l10n.loansDeleteFailedTitle,
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
    final l10n = AppLocalizations.of(context);
    return AppShell(
      currentRoute: '/loans',
      title: l10n.loansTitle,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: l10n.loansTitle,
                subtitle: l10n.loansSubtitle,
                actions: [
                  if (!_isCustomer)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 150,
                        child: ElevatedButton.icon(
                          onPressed: _showCreateLoanDialog,
                          icon: const Icon(Icons.add),
                          label: Text(l10n.loansCreateButton),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              _buildSearchAndFilters(isNarrow, l10n),
              const SizedBox(height: 8),
              Expanded(child: _buildBody(isNarrow, l10n)),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(bool isNarrow, AppLocalizations l10n) {
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
            OutlinedButton(onPressed: _loadAll, child: Text(l10n.retry)),
          ],
        ),
      );
    }
    return _buildLoansTable(isNarrow, l10n);
  }

  Widget _buildSearchAndFilters(bool isNarrow, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final searchField = TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: l10n.loansSearchHint,
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
              label: Text(localizedStatusLabel(filter, l10n)),
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

  Widget _buildLoansTable(bool isNarrow, AppLocalizations l10n) {
    final loans = _filteredLoans;

    if (loans.isEmpty) {
      return Center(child: Text(l10n.loansNoLoansFound));
    }

    final table = DataTable(
      headingTextStyle: const TextStyle(
        color: AppColors.kTextMuted,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      columns: [
        DataColumn(label: Text(l10n.loansColHpNo)),
        DataColumn(label: Text(l10n.loansColCustomer)),
        DataColumn(label: Text(l10n.loansColType)),
        DataColumn(label: Text(l10n.loansColAmount)),
        DataColumn(label: Text(l10n.loansColEmi)),
        DataColumn(label: Text(l10n.loansColOutstanding)),
        DataColumn(label: Text(l10n.loansColAgent)),
        DataColumn(label: Text(l10n.loansColStatus)),
        DataColumn(label: Text(l10n.loansColStart)),
        DataColumn(label: Text(l10n.loansColActions)),
      ],
      rows: loans.map((loan) {
        return DataRow(cells: [
          DataCell(Text(loan.loanNumber,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(loan.customerName)),
          DataCell(Text(friendlyCollectionTypeLabel(loan, l10n))),
          DataCell(Text(loan.formattedAmount)),
          DataCell(Text(loan.formattedEmi)),
          DataCell(Text(loan.formattedOutstanding,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(loan.agentName)),
          DataCell(StatusBadge(
              label: localizedStatusLabel(loan.status, l10n),
              tone: _toneFor(loan.status))),
          DataCell(Text(loan.startDate ?? '-')),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                color: AppColors.kTextMuted,
                onPressed: () => _showViewLoanDialog(loan),
                tooltip: l10n.loansActionView,
              ),
              if (!_isCustomer) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.kTextMuted,
                  onPressed: () => _showEditLoanDialog(loan),
                  tooltip: l10n.loansActionEdit,
                ),
                IconButton(
                  icon: Icon(
                    loan.status == 'Active'
                        ? Icons.close
                        : Icons.delete_outline,
                    size: 20,
                  ),
                  color: AppColors.kDanger,
                  onPressed: () => _showLoanActionDialog(loan),
                  tooltip: loan.status == 'Active'
                      ? l10n.loansActionClose
                      : l10n.loansActionDelete,
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
  final String actionLabel;

  const LoanDetailDialog({
    super.key,
    required this.loan,
    this.onDelete,
    this.actionLabel = 'Delete',
  });

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

  String _durationLabel(LoanRecord loan, AppLocalizations l10n) {
    switch (loan.collectionType) {
      case 'Weekly':
        return l10n.loansDurationWeeks(loan.durationUnits);
      case 'Daily':
        return l10n.loansDurationDays(loan.durationUnits);
      default:
        return loanHasMonthlyInterestMarker(loan.notes)
            ? l10n.loansDurationMonthsInterestOnly(loan.durationUnits)
            : l10n.loansDurationMonths(loan.durationUnits);
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
        totalAmount = loan.principalAmount +
            loan.principalAmount * (loan.interestRate / 100);
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.loansDetailTitle(loan.loanNumber),
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
              MapEntry(l10n.loansFieldCustomer, loan.customerName),
              MapEntry(l10n.loansFieldLoanType,
                  friendlyCollectionTypeLabel(loan, l10n)),
              MapEntry(l10n.loansFieldLoanAmount, loan.formattedAmount),
              MapEntry(
                  isInterestOnly
                      ? l10n.loansFieldMonthlyInterest
                      : l10n.loansFieldEmi,
                  loan.formattedEmi),
              MapEntry(l10n.loansFieldOutstanding, loan.formattedOutstanding),
              MapEntry(l10n.loansFieldPenalty, loan.formattedPenalty),
              MapEntry(l10n.loansFieldTotalDuePenalty,
                  loan.formattedOutstandingWithPenalty),
              MapEntry(l10n.loansFieldInterest, '${fmtRate(loan.interestRate)}%'),
              MapEntry(l10n.loansFieldDuration, _durationLabel(loan, l10n)),
              MapEntry(l10n.loansFieldStartDate, loan.startDate ?? '-'),
              MapEntry(l10n.loansFieldAgent, loan.agentName),
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
              StatusBadge(
                  label: localizedStatusLabel(loan.status, l10n),
                  tone: _toneFor(loan.status)),
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
                    label: Text(_showSchedule
                        ? l10n.loansHideSchedule
                        : l10n.loansShowSchedule),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kDanger,
                      side: const BorderSide(color: AppColors.kDanger),
                    ),
                    onPressed: widget.onDelete,
                    icon: Icon(
                      widget.actionLabel == l10n.loansActionClose
                          ? Icons.close
                          : Icons.delete_outline,
                      size: 18,
                    ),
                    label: Text(widget.actionLabel),
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
                Text(l10n.loansRepaymentSchedule,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextDark)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: l10n.loansRefreshScheduleTooltip,
                  onPressed: () => setState(_regenerateSchedule),
                ),
              ],
            ),
            if (isInterestOnly) ...[
              const SizedBox(height: 4),
              Text(
                l10n.loansInterestOnlyScheduleNote,
                style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
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
  bool _penaltyEnabled = false;
  final TextEditingController _penaltyRateController = TextEditingController();
  final TextEditingController _weeklyPenaltyController = TextEditingController();

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
      _penaltyEnabled = loan.penaltyEnabled;
      _penaltyRateController.text = loan.penaltyRatePerDay.toStringAsFixed(0);
      _weeklyPenaltyController.text = loan.penaltyPerWeek.toStringAsFixed(0);
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
        text: loan != null
            ? fmtRate(loan.interestRate)
            : _defaultRateFor(_collectionType));
    _durationController = TextEditingController(
        text: loan != null &&
                (_collectionType == 'Monthly EMI' ||
                    _collectionType == 'Monthly Interest')
            ? loan.durationUnits.toString()
            : '10');
    final today = DateTime.now();
    final defaultStartDate =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';
    _startDateController =
        TextEditingController(text: loan?.startDate ?? defaultStartDate);
    _feeController = TextEditingController(
        text: loan != null ? loan.processingFee.toStringAsFixed(0) : '');
    _notesController =
        TextEditingController(text: stripMonthlyInterestMarker(loan?.notes));
    if (loan == null) {
      _penaltyRateController.text = '';
      _weeklyPenaltyController.text = '';
    }

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

    _penaltyRateController.dispose();
    _weeklyPenaltyController.dispose();

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
    final l10n = AppLocalizations.of(context);
    if (_selectedCustomer == null) {
      ToastService.show(
        title: l10n.loansCustomerRequiredTitle,
        message: l10n.loansCustomerRequiredMessage,
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
        title: l10n.loansSaveFailedTitle,
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
    final frequency =
        (_collectionType == 'Weekly' || _collectionType == 'Daily')
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

    final penaltyRate = double.tryParse(_penaltyRateController.text) ?? 0;
    final weeklyPenalty = double.tryParse(_weeklyPenaltyController.text) ?? 0;

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
      'penalty_enabled': _penaltyEnabled,
      'penalty_rate_per_day': penaltyRate,
      'penalty_per_week': weeklyPenalty,
      'penalty_amount': 0,
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

  double _calcMonthlyEmiTotalInterest() => (_principal > 0 && _duration > 0)
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
      _dailyDays == 100 ? _principal : _principal + _calcDailyAddedInterest();

  double _calcDailyInstallment() => _dailyDays == 100
      ? (_dailyDays > 0 ? _principal / _dailyDays : 0)
      : (_dailyDays > 0 ? _calcDailyTotalRepayment() / _dailyDays : 0);

  double _calcDailyDisbursed() => _dailyDays == 100
      ? (_principal - _calcDailyAddedInterest()).clamp(0, double.infinity)
      : _principal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  widget.isEdit ? l10n.loansEditTitle : l10n.loansCreateTitle,
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

          _buildCollectionTypeSelector(l10n),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Column(
                children: [
                  _responsiveRow(
                    isNarrow,
                    _buildTextField(
                        l10n.loansHpNumberLabel,
                        widget.isEdit
                            ? ''
                            : (_loadingHpNumber
                                ? l10n.loansHpNumberLoading
                                : l10n.loansHpNumberAuto),
                        enabled: false,
                        controller: _loanNumberController),
                    _buildCustomerField(l10n),
                  ),
                  const SizedBox(height: 16),
                  _buildDynamicMiddleInputs(isNarrow, l10n),
                  const SizedBox(height: 16),
                  _responsiveRow(
                    isNarrow,
                    _buildAgentField(l10n),
                    _buildTextField(
                        l10n.loansProcessingFeeLabel, l10n.loansProcessingFeeHint,
                        controller: _feeController),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _buildPenaltyConfiguration(l10n),
          const SizedBox(height: 16),
          _buildTextField(l10n.loansNotesLabel, l10n.loansNotesHint,
              maxLines: 2, controller: _notesController),
          const SizedBox(height: 24),

          _buildDynamicSummarySection(l10n),
          const SizedBox(height: 24),

          _buildScheduleSection(l10n),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _saving ? null : () => _handleSave(),
                child: Text(l10n.loansSave),
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
                label: Text(l10n.loansApprove),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCustomerField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.loansCustomerRequiredLabel,
            style: const TextStyle(
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
              decoration: InputDecoration(
                hintText: l10n.loansCustomerHint,
                isDense: true,
                suffixIcon: const Icon(Icons.expand_more, size: 20),
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
  Widget _buildAgentField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.loansAgentLabel,
            style: const TextStyle(
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
              decoration: InputDecoration(
                hintText: l10n.loansAgentHint,
                isDense: true,
                suffixIcon: const Icon(Icons.expand_more, size: 20),
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

  Widget _buildCollectionTypeSelector(AppLocalizations l10n) {
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
            localizedCollectionTypeOption(option.key, l10n),
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
        Text(l10n.loansCollectionTypeLabel,
            style: const TextStyle(
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
  Widget _buildDynamicMiddleInputs(bool isNarrow, AppLocalizations l10n) {
    switch (_collectionType) {
      case 'Monthly EMI':
        return Column(
          children: [
            _responsiveRow(
              isNarrow,
              _buildTextField(l10n.loansLoanAmountLabel, l10n.loansLoanAmountHint,
                  controller: _amountController),
              _buildTextField(l10n.loansInterestRateMonthlyLabel,
                  l10n.loansInterestRateHint25,
                  controller: _interestController),
            ),
            const SizedBox(height: 16),
            _responsiveRow(
              isNarrow,
              _buildTextField(
                  l10n.loansDurationMonthsLabel, l10n.loansDurationHint10,
                  controller: _durationController),
              _buildStartDateField(l10n),
            ),
          ],
        );

      case 'Monthly Interest':
        return Column(
          children: [
            _buildTextField(l10n.loansLoanAmountLabel, l10n.loansLoanAmountHint,
                controller: _amountController),
            const SizedBox(height: 16),
            _buildInterestOnlyInfoBox(l10n),
            const SizedBox(height: 16),
            _responsiveRow(
              isNarrow,
              _buildRateFieldWithChips(
                  l10n.loansMonthlyInterestRateLabel, const [2, 2.5, 3, 4, 5]),
              _buildTextField(
                  l10n.loansLoanTenureLabel, l10n.loansDurationHint10,
                  controller: _durationController),
            ),
            const SizedBox(height: 16),
            _buildStartDateField(l10n),
          ],
        );

      case 'Weekly':
        return Column(
          children: [
            _responsiveRow(
              isNarrow,
              _buildTextField(l10n.loansLoanAmountLabel, l10n.loansLoanAmountHint,
                  controller: _amountController),
              _buildRateFieldWithChips(l10n.loansInterestRateLabel, const [10, 12]),
            ),
            const SizedBox(height: 16),
            _responsiveRow(
              isNarrow,
              _buildDisabledField(
                  l10n.loansDurationFixedLabel, l10n.loansDurationWeeksFixed),
              _buildStartDateField(l10n),
            ),
          ],
        );

      default: // Daily
        return Column(
          children: [
            _responsiveRow(
              isNarrow,
              _buildTextField(l10n.loansLoanAmountLabel, l10n.loansLoanAmountHint,
                  controller: _amountController),
              _buildRateFieldWithChips(l10n.loansInterestRateLabel, const [15, 20]),
            ),
            const SizedBox(height: 16),
            _responsiveRow(
              isNarrow,
              _buildDailyPlanDropdown(l10n),
              _buildStartDateField(l10n),
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
  Widget _buildDailyPlanDropdown(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.loansCollectionPlanLabel,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _dailyDays,
          isExpanded: true,
          decoration: const InputDecoration(isDense: true),
          items: [
            DropdownMenuItem(
              value: 60,
              child: Text(l10n.loansPlan60Days,
                  overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 100,
              child: Text(l10n.loansPlan100Days,
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

  Widget _buildInterestOnlyInfoBox(AppLocalizations l10n) {
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
              children: [
                Text(
                  l10n.loansInterestOnlyBoxTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.kTextDark),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.loansInterestOnlyBoxBody,
                  style: const TextStyle(fontSize: 12, color: AppColors.kInfo),
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
  Widget _buildPenaltyConfiguration(AppLocalizations l10n) {
    final bool showDaily = _collectionType == 'Monthly EMI' || _collectionType == 'Monthly Interest';
    final bool showWeekly = _collectionType == 'Weekly';

    if (!showDaily && !showWeekly) {
      return const SizedBox.shrink();
    }

    final String title =
        showWeekly ? l10n.loansWeeklyPenaltyTitle : l10n.loansDailyPenaltyTitle;
    final String helper = showWeekly
        ? l10n.loansWeeklyPenaltyHelper
        : l10n.loansDailyPenaltyHelper;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kGold.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.kWarning, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.kTextDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: _penaltyEnabled,
                onChanged: (value) => setState(() => _penaltyEnabled = value),
                activeColor: AppColors.kGold,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            helper,
            style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 12),
          if (showDaily)
            Row(
              children: [
                Expanded(
                  child: _buildTextField(l10n.loansDailyPenaltyRateLabel,
                      l10n.loansDailyPenaltyRateHint,
                      controller: _penaltyRateController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.kBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.loansDailyPenaltyExample,
                      style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildTextField(l10n.loansWeeklyPenaltyAmountLabel,
                      l10n.loansWeeklyPenaltyAmountHint,
                      controller: _weeklyPenaltyController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.kBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.loansWeeklyPenaltyAutoNote,
                      style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDynamicSummarySection(AppLocalizations l10n) {
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
                _buildSummaryCard(l10n.loansSummaryMonthlyEmi,
                    '₹${emi.toStringAsFixed(0)}',
                    const Color(0xFFFFFBEB), AppColors.kWarning,
                    subtitle: l10n.loansSummaryPerMonth(_duration)),
                _buildSummaryCard(
                    l10n.loansSummaryTotalInterest,
                    '₹${totalInterest.toStringAsFixed(0)}',
                    const Color(0xFFFFFBEB),
                    AppColors.kWarning,
                    subtitle: l10n.loansSummaryPerMonthAmount(
                        '₹${perMonth.toStringAsFixed(0)}')),
                _buildSummaryCard(
                    l10n.loansSummaryTotalRepayment,
                    '₹${totalRepayment.toStringAsFixed(0)}',
                    const Color(0xFFF0FDF4),
                    AppColors.kSuccess,
                    subtitle: l10n.loansSummaryPrincipalPlusInterest),
              ];
              break;
            }

          case 'Monthly Interest':
            {
              final due = _calcMonthlyInterestDue();
              cards = [
                _buildSummaryCard(
                    l10n.loansSummaryMonthlyInterestDue,
                    '₹${due.toStringAsFixed(0)}',
                    const Color(0xFFF0F5FF),
                    AppColors.kInfo,
                    subtitle: l10n.loansSummaryRateOfPrincipal(
                        fmtRate(_interestRate),
                        LoanRecord.formatRupees(_principal))),
                _buildSummaryCard(
                    l10n.loansSummaryPrincipalRepayment,
                    l10n.loansSummaryFlexibleInstallments,
                    const Color(0xFFF0FDF4),
                    AppColors.kSuccess,
                    subtitle: l10n.loansSummaryRepayAnytime),
                _buildSummaryCard(
                    l10n.loansSummaryPrincipalDisbursed,
                    LoanRecord.formatRupees(_principal),
                    const Color(0xFFFFFBEB),
                    AppColors.kWarning,
                    subtitle: l10n.loansSummaryTenureMonths(_duration)),
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
                    l10n.loansSummaryWeeklyInstallment,
                    '₹${installment.toStringAsFixed(0)}',
                    const Color(0xFFF0F5FF),
                    AppColors.kInfo,
                    subtitle: l10n.loansSummaryWeeksEqual(
                        LoanRecord.formatRupees(_principal))),
                _buildSummaryCard(
                    l10n.loansSummaryInterestDeducted,
                    '₹${deductedInterest.toStringAsFixed(0)}',
                    const Color(0xFFFFFBEB),
                    AppColors.kWarning,
                    subtitle: l10n.loansSummaryDeductedUpfront),
                _buildSummaryCard(
                    l10n.loansSummaryAmountDisbursed,
                    '₹${disbursed.toStringAsFixed(0)}',
                    const Color(0xFFF0FDF4),
                    AppColors.kSuccess,
                    subtitle: l10n.loansSummaryPrincipalMinusInterest),
              ];
              break;
            }

          default: // Daily
            {
              final installment = _calcDailyInstallment();
              final interest = _calcDailyAddedInterest();
              final totalRepayment = _calcDailyTotalRepayment();
              final isUpfrontDeduction = _dailyDays == 100;

              cards = [
                _buildSummaryCard(
                    l10n.loansSummaryDailyInstallment,
                    '₹${installment.toStringAsFixed(0)}',
                    const Color(0xFFF0F5FF),
                    AppColors.kInfo,
                    subtitle: l10n.loansSummaryDaysEqual(_dailyDays,
                        LoanRecord.formatRupees(totalRepayment))),
                _buildSummaryCard(
                    isUpfrontDeduction
                        ? l10n.loansSummaryInterestDeducted
                        : l10n.loansSummaryInterestAdded,
                    '₹${interest.toStringAsFixed(0)}',
                    const Color(0xFFFFFBEB),
                    AppColors.kWarning,
                    subtitle: isUpfrontDeduction
                        ? l10n.loansSummaryDeductedUpfront
                        : l10n.loansSummaryAddedToRepayment),
                _buildSummaryCard(
                    l10n.loansSummaryAmountDisbursedToBorrower,
                    LoanRecord.formatRupees(_calcDailyDisbursed()),
                    const Color(0xFFF0FDF4),
                    AppColors.kSuccess,
                    subtitle: isUpfrontDeduction
                        ? l10n.loansSummaryPrincipalMinusInterest
                        : l10n.loansSummaryFullLoanAmount),
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

  Widget _buildScheduleSection(AppLocalizations l10n) {
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

    final frequency =
        (_collectionType == 'Weekly' || _collectionType == 'Daily')
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
        Row(
          children: [
            const Icon(Icons.description_outlined,
                size: 18, color: AppColors.kTextMuted),
            const SizedBox(width: 8),
            Text(l10n.loansScheduleSectionTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.kTextDark)),
          ],
        ),
        if (_collectionType == 'Monthly Interest') ...[
          const SizedBox(height: 4),
          Text(
            l10n.loansInterestOnlyScheduleNote,
            style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
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

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          tryParseFlexibleDate(_startDateController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;

    _startDateController.text =
        '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}';
  }

  Widget _buildStartDateField(AppLocalizations l10n) {
    return _buildTextField(
      l10n.loansStartDateLabel,
      l10n.loansStartDateHint,
      controller: _startDateController,
      readOnly: true,
      onTap: _selectStartDate,
    );
  }

  Widget _buildTextField(String label, String hint,
      {bool enabled = true,
      TextEditingController? controller,
      int maxLines = 1,
      bool readOnly = false,
      VoidCallback? onTap}) {
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
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          keyboardType: label.contains('AMOUNT') ||
                  label.contains('INTEREST') ||
                  label.contains('DURATION')
              ? TextInputType.number
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            suffixIcon: onTap != null ? const Icon(Icons.calendar_today) : null,
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