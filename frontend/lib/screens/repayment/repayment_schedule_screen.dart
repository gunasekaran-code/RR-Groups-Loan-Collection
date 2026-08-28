import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/status_badge.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../models/loan_record.dart';
import '../../models/repayment_installment.dart';
import '../../models/user_role.dart';
import '../../services/api_service_repayment.dart';
import '../../services/collection_api_service.dart';
import '../../services/loan_service.dart';
import '../../services/session_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../loans/loans_screen.dart' show friendlyCollectionTypeLabel;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadLoans();
    });
  }

  Future<void> _loadLoans() async {
    setState(() {
      _loading = true;
      _error = null;
      _loanOptions = [];
      _selectedLoan = null;
      _installments = [];
    });

    final l10n = AppLocalizations.of(context);

    try {
      final customers = await LoanService.instance.fetchCustomers();
      final agents = await LoanService.instance.fetchAgents();
      final loans = await LoanService.instance.fetchLoans(
        customers: customers,
        agents: agents,
      );
      // A closed loan has nothing left to schedule, so it never belongs in
      // this picker — only Active / Overdue / Pending loans do.
      final filteredLoans = loans.where((loan) {
        if (loan.status == 'Closed') return false;
        if (_isCustomer && _customerId != null) {
          return loan.customerId == _customerId;
        }
        return true;
      }).toList();
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
        _error = l10n.repaymentCouldNotLoadLoans;
        _loading = false;
      });
      ToastService.show(
        title: l10n.repaymentLoanLoadFailedTitle,
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

    final l10n = AppLocalizations.of(context);

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
        _error = l10n.repaymentCouldNotLoadSchedule;
        _loading = false;
      });
      ToastService.show(
        title: l10n.repaymentLoadFailedTitle,
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

  /// Sorted list of installments not yet fully paid — used to find the
  /// "next due" row and to default-select an installment when recording
  /// a new collection.
  List<RepaymentInstallment> get _unpaidInstallments {
    final unpaid =
        _installments.where((i) => i.status != 'paid').toList();
    unpaid.sort((a, b) {
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return unpaid;
  }

  // ---- Record Collection -------------------------------------------

  void _showRecordCollectionSheet() {
    final l10n = AppLocalizations.of(context);
    final loan = _selectedLoan;
    if (loan == null) {
      ToastService.show(
        title: l10n.repaymentRecordCollectionSelectLoanFirst,
        type: ToastType.warning,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (sheetContext) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: _RecordCollectionSheet(
          loan: loan,
          installments: _unpaidInstallments,
          onSubmit: _recordCollection,
        ),
      ),
    );
  }

  String _apiMethodValue(String uiMethod) {
    switch (uiMethod) {
      case 'UPI':
        return 'upi';
      case 'Bank Transfer':
        return 'bank';
      case 'Cheque':
        return 'cheque';
      case 'Card':
        return 'card';
      default:
        return 'cash';
    }
  }

  Future<bool> _recordCollection({
    required RepaymentInstallment? installment,
    required double amount,
    required String method,
    required DateTime date,
    required String notes,
  }) async {
    final l10n = AppLocalizations.of(context);
    final loan = _selectedLoan;
    if (loan == null) return false;

    final currentUser = SessionService.instance.currentUser;
    final isAgentRole = currentUser?.role == UserRole.agent;
    final receipt =
        'RCP-${(DateTime.now().millisecondsSinceEpoch % 100000000).toString().padLeft(8, '0')}';
    final isoDate = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    try {
      final payload = {
        'receipt_number': receipt,
        'customer_id': loan.customerId,
        'customer_name': loan.customerName,
        'loan_id': loan.id,
        'loan_number': loan.loanNumber,
        'loan_type': loan.collectionType.toLowerCase(),
        'collection_amount': amount,
        'payment_method': _apiMethodValue(method),
        'collection_date': isoDate,
        'agent_id': isAgentRole ? currentUser?.userId : loan.agentId,
        'agent_name': isAgentRole ? currentUser?.name : loan.agentName,
        'notes': [
          if (installment != null) 'Installment #${installment.installmentNo}',
          if (notes.trim().isNotEmpty) notes.trim(),
        ].join(' | '),
      };
      await CollectionApiService.createCollection(payload);
      if (!mounted) return true;
      ToastService.show(
        title: l10n.repaymentRecordCollectionSuccessTitle,
        message: loan.loanNumber,
        type: ToastType.success,
      );
      await _loadSchedule();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ToastService.show(
        title: l10n.repaymentRecordCollectionFailedTitle,
        message: e.toString(),
        type: ToastType.error,
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        return AppShell(
          currentRoute: AppRoutes.repayment,
          title: l10n.repaymentTitle,
          body: RefreshIndicator(
            onRefresh: _loadSchedule,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 12 : 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isNarrow, l10n),
                  const SizedBox(height: 24),
                  _buildLoanSelector(l10n),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _buildErrorState(l10n)
                  else ...[
                    if (_buildPenaltyBanner(l10n) case final banner?) ...[
                      banner,
                      const SizedBox(height: 20),
                    ],
                    _buildSummaryGrid(isNarrow, l10n),
                    const SizedBox(height: 24),
                    _buildSectionLabel(l10n.repaymentInstallmentBreakdown),
                    const SizedBox(height: 12),
                    _buildInstallmentsTable(isNarrow, l10n),
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

  Widget _buildErrorState(AppLocalizations l10n) {
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
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  // Header — subtitle + the "Record Collection" action. Only admins/agents
  // may write collections (the backend rejects a customer's POST with a
  // 403), so the button is hidden for customer accounts rather than shown
  // and left to fail.
  Widget _buildHeader(BuildContext context, bool isNarrow, AppLocalizations l10n) {
    final subtitle = Text(
      l10n.repaymentSubtitle,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
    );

    final recordButton = _isCustomer
        ? null
        : ElevatedButton.icon(
            onPressed: _selectedLoan == null ? null : _showRecordCollectionSheet,
            icon: const Icon(Icons.payments_outlined, size: 20),
            label: Text(l10n.repaymentRecordCollectionButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kGold,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.kGold.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: 0,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          subtitle,
          if (recordButton != null) ...[
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: recordButton),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: subtitle),
        if (recordButton != null) recordButton,
      ],
    );
  }

  // Loan selector card
  Widget _buildLoanSelector(AppLocalizations l10n) {
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
          Text(
            l10n.repaymentSelectLoanLabel,
            style: const TextStyle(
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.kGold, width: 1.4),
              ),
            ),
            hint: Text(l10n.repaymentSelectLoanHint),
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
                        title: l10n.repaymentLoanSwitchedTitle,
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

  // Localized "N Weeks/Months/Days" label for the loan's duration, matching
  // the unit LoanRecalc actually applies penalties in.
  String _durationLabel(LoanRecord loan, AppLocalizations l10n) {
    switch (loan.collectionType) {
      case 'Weekly':
        return l10n.repaymentDurationWeeks(loan.durationUnits);
      case 'Daily':
        return l10n.repaymentDurationDays(loan.durationUnits);
      default:
        return l10n.repaymentDurationMonths(loan.durationUnits);
    }
  }

  // Penalty rule banner — mirrors the exact rule LoanRecalc.php applies on
  // the backend, so this never promises something the server won't do:
  //   * Weekly loans: a fixed ₹100-per-₹10,000-principal penalty per missed
  //     week (see core/LoanRecalc.php `syncRegular`).
  //   * Monthly/Daily loans: only when `penalty_enabled` and a per-day rate
  //     are actually configured on the loan.
  // Returns null (no banner) when neither rule is active for this loan.
  Widget? _buildPenaltyBanner(AppLocalizations l10n) {
    final loan = _selectedLoan;
    if (loan == null) return null;

    final isWeekly = loan.collectionType == 'Weekly';
    final hasDailyRate =
        !isWeekly && loan.penaltyEnabled && loan.penaltyRatePerDay > 0;
    if (!isWeekly && !hasDailyRate) return null;

    final title = l10n.repaymentPenaltyBannerTitle(
      friendlyCollectionTypeLabel(loan, l10n),
      _durationLabel(loan, l10n),
    );
    final body = isWeekly
        ? l10n.repaymentPenaltyBannerWeeklyBody
        : l10n.repaymentPenaltyBannerRateBody(
            LoanRecord.formatRupees(loan.penaltyRatePerDay));

    final totalPenalty =
        _installments.fold<double>(0, (sum, i) => sum + i.penaltyAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kWarning.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kWarning.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.kWarning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.kTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.kTextDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (totalPenalty > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.kDanger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.repaymentAccruedPenaltyLabel(
                    LoanRecord.formatRupees(totalPenalty)),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kDanger,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Summary cards grid — responsive: 2 columns narrow, 4 columns wide.
  // All figures below are derived from the fetched schedule rows.
  Widget _buildSummaryGrid(bool isNarrow, AppLocalizations l10n) {
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
    final totalPenalty =
        _installments.fold<double>(0, (sum, i) => sum + i.penaltyAmount);
    final totalDueWithPenalty = outstanding + totalPenalty;

    final nextDue = _unpaidInstallments;
    final nextDueDisplay =
        nextDue.isNotEmpty ? nextDue.first.dueDateDisplay : '-';

    String fmt(double v) => LoanRecord.formatRupees(v);

    final cards = <Widget>[
      _buildStatCard(l10n.repaymentStatLoanNumber, _selectedLoan?.loanNumber ?? '-', icon: Icons.badge_outlined),
      _buildStatCard(l10n.repaymentStatCustomer, _selectedLoan?.customerName ?? '-', icon: Icons.person_outline),
      _buildStatCard(l10n.repaymentStatLoanAmount, _selectedLoan?.formattedAmount ?? '-',
          icon: Icons.account_balance_wallet_outlined),
      _buildStatCard(l10n.repaymentStatEmi, fmt(emi), icon: Icons.calendar_month_outlined),
      _buildStatCard(l10n.repaymentStatTotalRepayment, fmt(totalRepayment),
          icon: Icons.summarize_outlined),
      _buildStatCard(l10n.repaymentStatTotalDuePenalty, fmt(totalDueWithPenalty),
          icon: Icons.account_balance, textColor: AppColors.kDanger),
      _buildStatCard(l10n.repaymentStatTotalInstallments, '$total',
          icon: Icons.format_list_numbered),
      _buildStatCard(l10n.repaymentStatPaid, '$paidCount',
          icon: Icons.check_circle_outline,
          textColor: AppColors.kSuccess,
          borderColor: AppColors.kSuccess.withOpacity(0.3),
          bgColor: AppColors.kSuccess.withOpacity(0.05)),
      _buildStatCard(l10n.repaymentStatPending, '$pendingCount',
          icon: Icons.hourglass_empty,
          textColor: AppColors.kWarning,
          borderColor: AppColors.kWarning.withOpacity(0.3),
          bgColor: AppColors.kWarning.withOpacity(0.05)),
      _buildStatCard(l10n.repaymentStatOverdue, '$overdueCount',
          icon: Icons.error_outline,
          textColor: AppColors.kDanger,
          borderColor: AppColors.kDanger.withOpacity(0.3),
          bgColor: AppColors.kDanger.withOpacity(0.05)),
      _buildStatCard(l10n.repaymentStatNextDue, nextDueDisplay,
          icon: Icons.event_outlined,
          textColor: AppColors.kGoldDark,
          borderColor: AppColors.kGold.withOpacity(0.35),
          bgColor: AppColors.kGold.withOpacity(0.08)),
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
  // from live `_installments` fetched via ApiServiceRepayment, with rows
  // tinted by status so paid / next-due / overdue installments stand out.
  Widget _buildInstallmentsTable(bool isNarrow, AppLocalizations l10n) {
    if (_installments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          border: Border.all(color: AppColors.kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l10n.repaymentNoInstallmentsFound,
          style: const TextStyle(color: AppColors.kTextMuted),
        ),
      );
    }

    final nextDueId = _unpaidInstallments.isNotEmpty
        ? _unpaidInstallments.first.id
        : null;

    Color? rowColor(RepaymentInstallment inst) {
      if (inst.status == 'paid') return AppColors.kSuccess.withOpacity(0.07);
      if (inst.status == 'overdue') return AppColors.kDanger.withOpacity(0.06);
      if (inst.id == nextDueId) return AppColors.kGold.withOpacity(0.10);
      return null;
    }

    final table = DataTable(
      headingRowColor:
          WidgetStateProperty.all(AppColors.kBackground),
      headingTextStyle: const TextStyle(
        color: AppColors.kTextMuted,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      dataTextStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.kTextDark,
      ),
      dividerThickness: 0.4,
      columns: [
        DataColumn(label: Text(l10n.repaymentColInstNo)),
        DataColumn(label: Text(l10n.repaymentColDueDate)),
        DataColumn(label: Text(l10n.repaymentColEmiAmount)),
        DataColumn(label: Text(l10n.repaymentColPaid)),
        DataColumn(label: Text(l10n.repaymentColBalance)),
        DataColumn(label: Text(l10n.repaymentColPenalty)),
        DataColumn(label: Text(l10n.repaymentColStatus)),
      ],
      rows: _installments.map((inst) {
        return DataRow(
          color: WidgetStateProperty.all(rowColor(inst)),
          cells: [
            DataCell(Text('#${inst.installmentNo}',
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(inst.dueDateDisplay)),
            DataCell(Text(inst.amountDisplay)),
            DataCell(Text(inst.paidDisplay)),
            DataCell(Text(inst.balanceDisplay,
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(inst.penaltyDisplay,
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(StatusBadge(
                label: inst.statusLabel, tone: _toneFor(inst.statusLabel))),
          ],
        );
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

// ---------------------------------------------------------------------
// Record Collection bottom sheet
// ---------------------------------------------------------------------

class _RecordCollectionSheet extends StatefulWidget {
  final LoanRecord loan;
  final List<RepaymentInstallment> installments; // unpaid only, sorted
  final Future<bool> Function({
    required RepaymentInstallment? installment,
    required double amount,
    required String method,
    required DateTime date,
    required String notes,
  }) onSubmit;

  const _RecordCollectionSheet({
    required this.loan,
    required this.installments,
    required this.onSubmit,
  });

  @override
  State<_RecordCollectionSheet> createState() =>
      _RecordCollectionSheetState();
}

class _RecordCollectionSheetState extends State<_RecordCollectionSheet> {
  static const List<String> _paymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Cheque',
    'Card',
  ];

  RepaymentInstallment? _selectedInstallment;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _method = 'Cash';
  DateTime _date = DateTime.now();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.installments.isNotEmpty) {
      _selectedInstallment = widget.installments.first;
      _prefillAmount(_selectedInstallment);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _prefillAmount(RepaymentInstallment? inst) {
    final due = inst != null
        ? (inst.balance + inst.penaltyAmount)
        : widget.loan.emiAmount;
    if (due > 0) {
      _amountController.text = due.round().toString();
    }
  }

  String _localizedMethod(String key, AppLocalizations l10n) {
    switch (key) {
      case 'UPI':
        return l10n.collectionsMethodUpi;
      case 'Bank Transfer':
        return l10n.collectionsMethodBank;
      case 'Cheque':
        return l10n.collectionsMethodCheque;
      case 'Card':
        return l10n.collectionsMethodCard;
      default:
        return l10n.collectionsMethodCash;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ToastService.show(
        title: l10n.repaymentRecordCollectionAmountRequired,
        type: ToastType.error,
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await widget.onSubmit(
      installment: _selectedInstallment,
      amount: amount,
      method: _method,
      date: _date,
      notes: _notesController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: const BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.kBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payments_outlined,
                        color: AppColors.kGoldDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.repaymentRecordCollectionSheetTitle,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.repaymentRecordCollectionSubtitle(
                              widget.loan.loanNumber, widget.loan.customerName),
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.kTextMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (widget.installments.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.kSuccess.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.kSuccess.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.kSuccess, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.repaymentRecordCollectionAllPaidMessage,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                _fieldLabel(l10n.repaymentRecordCollectionInstallmentLabel),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedInstallment?.id ?? 'general',
                  isExpanded: true,
                  decoration: _inputDecoration(),
                  items: [
                    DropdownMenuItem(
                      value: 'general',
                      child: Text(l10n.repaymentRecordCollectionGeneralPayment),
                    ),
                    ...widget.installments.map((inst) => DropdownMenuItem(
                          value: inst.id,
                          child: Text(
                            '#${inst.installmentNo} · ${inst.dueDateDisplay} · ${inst.balanceDisplay}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedInstallment = value == null || value == 'general'
                          ? null
                          : widget.installments
                              .where((i) => i.id == value)
                              .firstOrNull;
                      _prefillAmount(_selectedInstallment);
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              _fieldLabel(l10n.repaymentRecordCollectionAmountLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(prefixText: '₹ '),
              ),
              const SizedBox(height: 16),
              _fieldLabel(l10n.repaymentRecordCollectionMethodLabel),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _method,
                isExpanded: true,
                decoration: _inputDecoration(),
                items: _paymentMethods
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(_localizedMethod(m, l10n)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel(l10n.repaymentRecordCollectionDateLabel),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: _inputDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmtDate(_date)),
                      const Icon(Icons.calendar_today_outlined,
                          size: 17, color: AppColors.kTextMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _fieldLabel(l10n.repaymentRecordCollectionNotesLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 3,
                decoration: _inputDecoration(
                    hintText: l10n.repaymentRecordCollectionNotesHint),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.repaymentRecordCollectionSubmit,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.repaymentRecordCollectionCancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.kTextMuted,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      );

  InputDecoration _inputDecoration({String? prefixText, String? hintText}) {
    return InputDecoration(
      prefixText: prefixText,
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.kGold, width: 1.4),
      ),
    );
  }
}
