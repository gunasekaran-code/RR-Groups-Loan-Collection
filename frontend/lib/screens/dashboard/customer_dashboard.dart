import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/loan_record.dart';
import '../../models/repayment_installment.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/api_service_repayment.dart';
import '../../services/collection_api_service.dart';
import '../../services/session_service.dart';
import '../Promotional Popup/promotional_popup.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/stat_card.dart';

// ---------------------------------------------------------------------------
// Currency helper (mirrors the one in the admin dashboard)
// ---------------------------------------------------------------------------
String formatIndianCurrency(double? amount) {
  if (amount == null) return '₹0';
  final format =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  return format.format(amount);
}

// ============================================================================
// MODELS
// ============================================================================

class CustomerDashboardData {
  CustomerDashboardData({
    required this.summary,
    required this.loans,
    required this.upcomingInstallments,
    required this.recentPayments,
  });

  final CustomerSummary summary;
  final List<CustomerLoanEntry> loans;
  final List<InstallmentEntry> upcomingInstallments;
  final List<PaymentEntry> recentPayments;

  factory CustomerDashboardData.fromJson(Map<String, dynamic> json) {
    return CustomerDashboardData(
      summary: CustomerSummary.fromJson(json['summary'] ?? {}),
      loans: (json['loans'] as List? ?? [])
          .map((e) => CustomerLoanEntry.fromJson(e))
          .toList(),
      upcomingInstallments: (json['upcoming_installments'] as List? ?? [])
          .map((e) => InstallmentEntry.fromJson(e))
          .toList(),
      recentPayments: (json['recent_payments'] as List? ?? [])
          .map((e) => PaymentEntry.fromJson(e))
          .toList(),
    );
  }
}

class CustomerSummary {
  CustomerSummary({
    required this.activeLoans,
    required this.totalOutstanding,
    required this.totalPaid,
    required this.nextEmiAmount,
    required this.nextEmiDueDate,
    required this.installmentsPaidCount,
    required this.installmentsPendingCount,
  });

  final int activeLoans;
  final double totalOutstanding;
  final double totalPaid;
  final double nextEmiAmount;
  final String? nextEmiDueDate;
  final int installmentsPaidCount;
  final int installmentsPendingCount;

  factory CustomerSummary.fromJson(Map<String, dynamic> json) {
    return CustomerSummary(
      activeLoans: _asInt(json['active_loans']),
      totalOutstanding: _asDouble(json['total_outstanding']),
      totalPaid: _asDouble(json['total_paid']),
      nextEmiAmount: _asDouble(json['next_emi_amount']),
      nextEmiDueDate: json['next_emi_due_date'] as String?,
      installmentsPaidCount: _asInt(json['installments_paid']),
      installmentsPendingCount: _asInt(json['installments_pending']),
    );
  }
}

class CustomerLoanEntry {
  CustomerLoanEntry({
    required this.loanNumber,
    required this.principal,
    required this.emiAmount,
    required this.outstanding,
    required this.status,
  });

  final String loanNumber;
  final double principal;
  final double emiAmount;
  final double outstanding;
  final String status;

  factory CustomerLoanEntry.fromJson(Map<String, dynamic> json) {
    return CustomerLoanEntry(
      loanNumber: json['loan_number'] ?? '',
      principal: _asDouble(json['principal']),
      emiAmount: _asDouble(json['emi_amount']),
      outstanding: _asDouble(json['outstanding']),
      status: json['status'] ?? 'unknown',
    );
  }
}

class InstallmentEntry {
  InstallmentEntry({
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  final int installmentNumber;
  final double amount;
  final String dueDate;
  final String status; // 'paid' | 'pending' | 'overdue'

  factory InstallmentEntry.fromJson(Map<String, dynamic> json) {
    return InstallmentEntry(
      installmentNumber: _asInt(json['installment_number']),
      amount: _asDouble(json['amount']),
      dueDate: json['due_date'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}

class PaymentEntry {
  PaymentEntry({
    required this.receiptNumber,
    required this.loanNumber,
    required this.amount,
    required this.method,
    required this.date,
  });

  final String receiptNumber;
  final String loanNumber;
  final double amount;
  final String method;
  final String date;

  factory PaymentEntry.fromJson(Map<String, dynamic> json) {
    return PaymentEntry(
      receiptNumber: json['receipt_number'] ?? '',
      loanNumber: json['loan_number'] ?? '',
      amount: _asDouble(json['amount']),
      method: json['method'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

// ============================================================================
// SERVICE (REST)
// ============================================================================

class CustomerReportService {
  CustomerReportService._();
  static final CustomerReportService instance = CustomerReportService._();

  Future<CustomerDashboardData> fetchCustomerDashboard(
      String customerId) async {
    final loans = await ApiClient.instance.list(
      'loans',
      query: {'customer_id': 'eq.$customerId'},
    );
    final loanRecords = loans.map(LoanRecord.fromJson).toList();
    final loanIds = loanRecords
        .map((loan) => loan.id)
        .where((id) => id.isNotEmpty)
        .toList();
    final paymentHistory =
        await CollectionApiService.fetchPaymentHistory(
      customerId: customerId,
      loanIds: loanIds,
    );
    final scheduleRows = await _fetchSchedules(loanIds);

    final totalOutstanding = loanRecords.fold<double>(
      0,
      (sum, loan) => sum + loan.outstandingBalance,
    );
    final totalPaid = paymentHistory.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final activeLoans = loanRecords
        .where((loan) => loan.status.toLowerCase() == 'active')
        .length;

    final sortedSchedules = List<RepaymentInstallment>.from(scheduleRows)
      ..sort(_sortScheduleByDueDate);
    final paidInstallments = sortedSchedules
        .where((item) => item.status.toLowerCase() == 'paid')
        .length;
    final pendingInstallments = sortedSchedules.where((item) {
      final status = item.status.toLowerCase();
      return status == 'pending' ||
          status == 'partial' ||
          status == 'overdue';
    }).length;
    final nextDueInstallment = sortedSchedules.firstWhere(
      (item) {
        final status = item.status.toLowerCase();
        return status == 'pending' ||
            status == 'partial' ||
            status == 'overdue';
      },
      orElse: () => RepaymentInstallment(
        id: '',
        loanId: '',
        installmentNo: 0,
        dueDate: null,
        emiAmount: 0,
        paidAmount: 0,
        balance: 0,
        status: 'pending',
      ),
    );
    final nextEmiAmount = nextDueInstallment.emiAmount;
    final nextEmiDueDate =
        nextDueInstallment.dueDate?.toIso8601String().split('T').first;

    return CustomerDashboardData.fromJson({
      'summary': {
        'active_loans': activeLoans,
        'total_outstanding': totalOutstanding,
        'total_paid': totalPaid,
        'next_emi_amount': nextEmiAmount,
        'next_emi_due_date': nextEmiDueDate,
        'installments_paid': paidInstallments,
        'installments_pending': pendingInstallments,
      },
      'loans': loanRecords
          .map(
            (loan) => {
              'loan_number': loan.loanNumber,
              'principal': loan.principalAmount,
              'emi_amount': loan.emiAmount,
              'outstanding': loan.outstandingBalance,
              'status': loan.status,
            },
          )
          .toList(),
      'upcoming_installments': sortedSchedules
          .where((item) {
            final status = item.status.toLowerCase();
            return status == 'pending' ||
                status == 'partial' ||
                status == 'overdue';
          })
          .take(10)
          .map(
            (item) => {
              'installment_number': item.installmentNo,
              'amount': item.emiAmount,
              'due_date': item.dueDate?.toIso8601String().split('T').first ?? '',
              'status': item.status,
            },
          )
          .toList(),
      'recent_payments': paymentHistory
          .take(10)
          .map(
            (payment) => {
              'receipt_number': payment.displayReceipt,
              'loan_number': payment.loanNumber,
              'amount': payment.amount,
              'method': payment.displayMode,
              'date': payment.formattedDate,
            },
          )
          .toList(),
    });
  }
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

Future<List<RepaymentInstallment>> _fetchSchedules(List<String> loanIds) async {
  if (loanIds.isEmpty) return const [];

  final results = await Future.wait(
    loanIds.map((loanId) async {
      try {
        return await ApiServiceRepayment.instance.fetchSchedule(loanId);
      } catch (_) {
        return <RepaymentInstallment>[];
      }
    }),
  );

  return results.expand((items) => items).toList();
}

int _sortScheduleByDueDate(RepaymentInstallment a, RepaymentInstallment b) {
  final ad = a.dueDate;
  final bd = b.dueDate;
  if (ad == null && bd == null) {
    return a.installmentNo.compareTo(b.installmentNo);
  }
  if (ad == null) return 1;
  if (bd == null) return -1;
  final dateCompare = ad.compareTo(bd);
  if (dateCompare != 0) return dateCompare;
  return a.installmentNo.compareTo(b.installmentNo);
}

String _greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

// ============================================================================
// SCREEN
// ============================================================================

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  late Future<CustomerDashboardData> _future;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _future = _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showActivePromoPopup(context);
    });
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<CustomerDashboardData> _load() {
    final user = SessionService.instance.currentUser!;
    final customerKey = user.customerId ?? user.userId;
    return CustomerReportService.instance.fetchCustomerDashboard(customerKey);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final AppUser user = SessionService.instance.currentUser!;
    final theme = Theme.of(context);
    final todayLabel = DateFormat('EEEE, d MMMM y').format(_now);
    final firstName = user.name.split(' ').first;
    final greeting = _greetingForHour(_now.hour);

    return AppShell(
      currentRoute: AppRoutes.customerDashboard, // TODO: add this route const
      title: 'My Dashboard',
      body: FutureBuilder<CustomerDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final loading = snapshot.connectionState != ConnectionState.done;
          final error = snapshot.hasError ? snapshot.error.toString() : null;

          return Stack(
            children: [
              Positioned.fill(
                  child: Container(color: theme.scaffoldBackgroundColor)),
              Positioned(
                  top: -60,
                  left: -40,
                  child: _blurOrb(220, AppColors.kGold.withOpacity(0.35))),
              Positioned(
                  top: 220,
                  right: -60,
                  child: _blurOrb(200, AppColors.kInfo.withOpacity(0.28))),
              Positioned(
                  bottom: 100,
                  left: -50,
                  child: _blurOrb(240, AppColors.kSuccess.withOpacity(0.22))),
              Positioned(
                  bottom: -40,
                  right: -30,
                  child:
                      _blurOrb(180, const Color(0xFF7C3AED).withOpacity(0.22))),
              RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeroBanner(context, todayLabel, greeting, firstName, data),
                    const SizedBox(height: 16),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (error != null)
                      _errorCard(error)
                    else if (data != null) ...[
                      _buildStatGrid(data.summary),
                      const SizedBox(height: 16),
                      _buildRepaymentProgressCard(data.summary),
                      const SizedBox(height: 16),
                      _buildInstallmentStatusCard(data.summary),
                      const SizedBox(height: 16),
                      _buildMyLoansCard(context, data.loans),
                      const SizedBox(height: 16),
                      _buildUpcomingInstallmentsCard(
                          context, data.upcomingInstallments),
                      const SizedBox(height: 16),
                      _buildRecentPaymentsCard(context, data.recentPayments),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // -- shared glass helpers (identical to admin dashboard for consistency) --

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kDanger.withOpacity(0.25)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.kDanger)),
    );
  }

  Widget _blurOrb(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 24,
    double blur = 18,
    double opacity = 0.55,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border:
                Border.all(color: Colors.white.withOpacity(0.65), width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kTextDark)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.kTextMuted)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // -- sections specific to the customer view --

  Widget _buildHeroBanner(BuildContext context, String today, String greeting,
      String firstName, CustomerDashboardData? data) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nextEmi = data?.summary.nextEmiAmount ?? 0;
    final nextDue = data?.summary.nextEmiDueDate;
    final dueLabel = nextDue != null ? _prettyDate(nextDue) : '—';

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.92),
                AppColors.kGoldDark.withValues(alpha: 0.92)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(today.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('$greeting, $firstName',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Your next installment of ${formatIndianCurrency(nextEmi)} is due on $dueLabel.',
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.loans),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.kGoldDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View My Loans'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatGrid(CustomerSummary summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        StatCard(
          label: 'Active Loans',
          value: '${summary.activeLoans}',
          icon: Icons.account_balance_outlined,
          iconColor: Colors.blue,
          iconBackground: const Color(0xFFDCEAFE),
        ),
        StatCard(
          label: 'Total Outstanding',
          value: formatIndianCurrency(summary.totalOutstanding),
          icon: Icons.credit_card_outlined,
          iconColor: Colors.red,
          iconBackground: const Color(0xFFFEE2E2),
        ),
        StatCard(
          label: 'Next EMI',
          value: formatIndianCurrency(summary.nextEmiAmount),
          icon: Icons.calendar_today_outlined,
          iconColor: Colors.orange,
          iconBackground: const Color(0xFFFEF3C7),
        ),
        StatCard(
          label: 'Total Paid',
          value: formatIndianCurrency(summary.totalPaid),
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          iconBackground: const Color(0xFFDCFCE7),
        ),
      ],
    );
  }

  Widget _buildRepaymentProgressCard(CustomerSummary summary) {
    final paid = summary.totalPaid;
    final balance = summary.totalOutstanding;
    final total = paid + balance;
    final percent = total <= 0 ? 0.0 : (paid / total) * 100;
    final slices = [
      _DonutSlice('Paid', paid, AppColors.kSuccess),
      _DonutSlice('Balance', balance, AppColors.kGoldDark),
    ];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Repayment Progress', 'Paid vs balance to repay'),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: _DonutChartPainter(slices: slices),
                      size: const Size(120, 120),
                    ),
                    Text('${percent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: slices
                      .map((s) => _legendRow(
                          s.label, formatIndianCurrency(s.value), s.color,
                          percentOf: total, value: s.value))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentStatusCard(CustomerSummary summary) {
    final paid = summary.installmentsPaidCount.toDouble();
    final pending = summary.installmentsPendingCount.toDouble();
    final total = paid + pending;
    final slices = [
      _DonutSlice('Paid', paid, AppColors.kSuccess),
      _DonutSlice('Pending', pending, AppColors.kWarning),
    ];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Installment Status', 'Across your schedule'),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: _DonutChartPainter(slices: slices),
                      size: const Size(120, 120),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${total.toInt()}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.kTextDark)),
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.kTextMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: slices
                      .map((s) => _legendRow(
                          s.label, '${s.value.toInt()}', s.color,
                          percentOf: total, value: s.value))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String label, String valueLabel, Color color,
      {required double percentOf, required double value}) {
    final pct = percentOf <= 0 ? 0 : ((value / percentOf) * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.kTextDark))),
          Text('$valueLabel  $pct%',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextDark)),
        ],
      ),
    );
  }

  Widget _buildMyLoansCard(
      BuildContext context, List<CustomerLoanEntry> loans) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'My Loans',
            'All your loan accounts',
            trailing: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.loans),
                child: const Text('View all')),
          ),
          Divider(height: 20, color: Colors.white.withOpacity(0.6)),
          if (loans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('You have no loans yet.',
                  style: TextStyle(color: AppColors.kTextMuted)),
            )
          else
            ...loans.map((loan) {
              final statusColor = switch (loan.status.toLowerCase()) {
                'active' => AppColors.kSuccess,
                'overdue' => AppColors.kDanger,
                _ => AppColors.kTextMuted,
              };
              return _glassListRow(
                icon: Icons.account_balance_outlined,
                iconColor: AppColors.kInfo,
                iconBg: const Color(0xFFDCEAFE),
                title: loan.loanNumber,
                subtitle:
                    '${formatIndianCurrency(loan.principal)} • EMI ${formatIndianCurrency(loan.emiAmount)}',
                trailingTop: formatIndianCurrency(loan.outstanding),
                trailingBottom: loan.status,
                trailingBottomColor: statusColor,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildUpcomingInstallmentsCard(
      BuildContext context, List<InstallmentEntry> items) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Upcoming Installments',
            'Next payments due',
            trailing: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.repayment),
                child: const Text('Full schedule')),
          ),
          Divider(height: 20, color: Colors.white.withOpacity(0.6)),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No upcoming installments.',
                  style: TextStyle(color: AppColors.kTextMuted)),
            )
          else
            ...items.take(5).map((item) {
              final statusColor = switch (item.status.toLowerCase()) {
                'paid' => AppColors.kSuccess,
                'overdue' => AppColors.kDanger,
                _ => AppColors.kWarning,
              };
              return _glassListRow(
                icon: Icons.event_outlined,
                iconColor: AppColors.kWarning,
                iconBg: const Color(0xFFFEF3C7),
                title: '#${item.installmentNumber}',
                subtitle: 'Due ${_prettyDate(item.dueDate)}',
                trailingTop: formatIndianCurrency(item.amount),
                trailingBottom: item.status,
                trailingBottomColor: statusColor,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentPaymentsCard(
      BuildContext context, List<PaymentEntry> items) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Recent Payments',
            'Your payment history',
            trailing: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.paymentHistory),
                child: const Text('View all')),
          ),
          Divider(height: 20, color: Colors.white.withOpacity(0.6)),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No payments recorded yet.',
                  style: TextStyle(color: AppColors.kTextMuted)),
            )
          else
            ...items.take(6).map((item) => _glassListRow(
                  icon: Icons.currency_rupee,
                  iconColor: AppColors.kSuccess,
                  iconBg: const Color(0xFFDCFCE7),
                  title: item.receiptNumber,
                  subtitle: '${item.loanNumber} • ${item.method}',
                  trailingTop: formatIndianCurrency(item.amount),
                  trailingBottom: _prettyDate(item.date),
                )),
        ],
      ),
    );
  }

  Widget _glassListRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String trailingTop,
    required String trailingBottom,
    Color? trailingBottomColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: iconBg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: iconColor, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextDark),
                          overflow: TextOverflow.ellipsis),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.kTextMuted),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(trailingTop,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextDark)),
                    Text(trailingBottom,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: trailingBottomColor != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: trailingBottomColor ?? AppColors.kTextMuted,
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _prettyDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy').format(parsed);
  }
}

// ============================================================================
// SHARED SMALL TYPES / PAINTERS (mirrors admin dashboard's donut painter)
// ============================================================================

class _DonutSlice {
  final String label;
  final double value;
  final Color color;
  const _DonutSlice(this.label, this.value, this.color);
}

class _DonutChartPainter extends CustomPainter {
  final List<_DonutSlice> slices;
  _DonutChartPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    double start = -math.pi / 2;
    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = (slice.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.slices != slices;
}
