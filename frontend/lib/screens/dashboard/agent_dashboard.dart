import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/loan_record.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/session_service.dart';
import '../Promotional Popup/promotional_popup.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';

String _formatIndianCurrency(double? amount) {
  if (amount == null) return '₹0';
  final format =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  return format.format(amount);
}

// ============================================================================
// MODELS
// ============================================================================

class AgentDashboardData {
  AgentDashboardData({required this.summary, required this.todayRoute});

  final AgentSummary summary;
  final List<RouteStop> todayRoute;
}

class AgentSummary {
  AgentSummary({
    required this.todayCustomers,
    required this.pending,
    required this.completed,
    required this.collectedToday,
  });

  final int todayCustomers;
  final int pending;
  final int completed;
  final double collectedToday;
}

class RouteStop {
  RouteStop({
    required this.order,
    required this.loanId,
    required this.customerName,
    required this.loanNumber,
    required this.amount,
    required this.status,
  });

  final int order;
  final String loanId;
  final String customerName;
  final String loanNumber;
  final double amount;
  final String status; // 'overdue' | 'active' | 'paid'

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      order: (json['order'] ?? 0) as int,
      loanId: json['loan_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      loanNumber: json['loan_number'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
    );
  }
}

// ============================================================================
// SERVICE (REST)
// ============================================================================

class AgentReportService {
  AgentReportService._();
  static final AgentReportService instance = AgentReportService._();

  Future<AgentDashboardData> fetchAgentDashboard(String agentId) async {
    final loans = await ApiClient.instance.list(
      'loans',
      query: {'assigned_agent': 'eq.$agentId'},
    );
    final collections = await ApiClient.instance.list(
      'collections',
      query: {'agent_id': 'eq.$agentId'},
    );

    final loanRecords = loans.map(LoanRecord.fromJson).toList();
    final routeStops = loanRecords
        .take(10)
        .map(
          (loan) => RouteStop(
            order: loanRecords.indexOf(loan) + 1,
            loanId: loan.id,
            customerName: loan.customerName,
            loanNumber: loan.loanNumber,
            amount: loan.outstandingBalance > 0
                ? loan.outstandingBalance
                : loan.principalAmount,
            status: loan.status.toLowerCase(),
          ),
        )
        .toList();

    final collectedToday = collections.fold<double>(
      0,
      (sum, row) => sum + _asDouble(row['collection_amount'] ?? row['amount']),
    );

    final pending = loanRecords
        .where((loan) =>
            loan.status.toLowerCase() == 'pending' ||
            loan.status.toLowerCase() == 'active' ||
            loan.status.toLowerCase() == 'overdue')
        .length;
    final completed = loanRecords
        .where((loan) => loan.status.toLowerCase() == 'closed')
        .length;

    return AgentDashboardData(
      summary: AgentSummary(
        todayCustomers: loanRecords.length,
        pending: pending,
        completed: completed,
        collectedToday: collectedToday,
      ),
      todayRoute: routeStops,
    );
  }
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String _greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

// ============================================================================
// SCREEN
// ============================================================================

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  late Future<AgentDashboardData> _future;
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

  Future<AgentDashboardData> _load() {
    final user = SessionService.instance.currentUser!;
    return AgentReportService.instance.fetchAgentDashboard(user.userId);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final AppUser user = SessionService.instance.currentUser!;
    final todayLabel = DateFormat('dd MMM y').format(_now);
    final firstName = user.name.split(' ').first;
    final greeting = _greetingForHour(_now.hour);

    return AppShell(
      currentRoute:
          AppRoutes.agentDashboard, // TODO: add this const to AppRoutes
      title: 'My Dashboard',
      body: FutureBuilder<AgentDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final loading = snapshot.connectionState != ConnectionState.done;
          final error = snapshot.hasError ? snapshot.error.toString() : null;

          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              Positioned(
                top: -60,
                left: -40,
                child: _blurOrb(220, AppColors.kGold.withValues(alpha: 0.35)),
              ),
              Positioned(
                top: 220,
                right: -60,
                child: _blurOrb(200, AppColors.kInfo.withValues(alpha: 0.28)),
              ),
              Positioned(
                bottom: 100,
                left: -50,
                child: _blurOrb(240, AppColors.kSuccess.withValues(alpha: 0.22)),
              ),
              RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeroBanner(
                      context,
                      todayLabel,
                      greeting,
                      firstName,
                      data,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileRow(user),
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
                      _buildRouteCard(context, data.todayRoute),
                      const SizedBox(height: 16),
                      _buildQuickActionsRow(context),
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

  // -- helpers --------------------------------------------------------------

  Widget _buildHeroBanner(
    BuildContext context,
    String today,
    String greeting,
    String firstName,
    AgentDashboardData? data,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final collectedToday = data?.summary.collectedToday ?? 0;
    final stopsToday = data?.todayRoute.length ?? 0;

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
                AppColors.kGoldDark.withValues(alpha: 0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
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
                'Live figures from the database: ${_formatIndianCurrency(collectedToday)} collected today and $stopsToday stops scheduled.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.routeMap),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.kGoldDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View Route'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kDanger.withValues(alpha: 0.25)),
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
              gradient: RadialGradient(
                colors: [color, color.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 20,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildProfileRow(AppUser user) {
    final initials = user.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.kGoldDark,
            shape: BoxShape.circle,
          ),
          child: Text(initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.kTextDark)),
            const Text('Field Collection Agent',
                style: TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatGrid(AgentSummary summary) {
    final stats = [
      _AgentStat(
          'TODAY\'S CUSTOMERS',
          '${summary.todayCustomers}',
          'assigned visits',
          Icons.group_outlined,
          const Color(0xFFFEF3C7),
          AppColors.kGoldDark),
      _AgentStat(
          'PENDING',
          '${summary.pending}',
          'awaiting collection',
          Icons.access_time_rounded,
          const Color(0xFFFEF3C7),
          AppColors.kWarning),
      _AgentStat(
          'COMPLETED',
          '${summary.completed}',
          'collected today',
          Icons.check_circle_outline,
          const Color(0xFFDCFCE7),
          AppColors.kSuccess),
      _AgentStat(
          'COLLECTED',
          _formatIndianCurrency(summary.collectedToday),
          "today's total",
          Icons.account_balance_wallet_outlined,
          const Color(0xFFEDE9FE),
          const Color(0xFF7C3AED)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: stats.map((s) => _statTile(s)).toList(),
    );
  }

  Widget _statTile(_AgentStat s) {
    return _card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(s.label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: AppColors.kTextMuted)),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: s.iconBg, borderRadius: BorderRadius.circular(9)),
                child: Icon(s.icon, size: 16, color: s.iconColor),
              ),
            ],
          ),
          const Spacer(),
          Text(s.value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextDark)),
          const SizedBox(height: 2),
          Text(s.subtitle,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, List<RouteStop> stops) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.navigation_outlined,
                    size: 18, color: AppColors.kGoldDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Route",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.kTextDark)),
                    Text('${stops.length} stops scheduled',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.kTextMuted)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.routeMap),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('View map'),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.kGoldDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stops.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No stops scheduled for today.',
                  style: TextStyle(color: AppColors.kTextMuted)),
            )
          else
            ...stops.map((s) => _routeStopRow(context, s)),
        ],
      ),
    );
  }

  Widget _routeStopRow(BuildContext context, RouteStop s) {
    final statusColor = switch (s.status.toLowerCase()) {
      'overdue' => AppColors.kDanger,
      'active' => AppColors.kSuccess,
      _ => AppColors.kTextMuted,
    };
    final statusBg = switch (s.status.toLowerCase()) {
      'overdue' => AppColors.kDanger.withValues(alpha: 0.12),
      'active' => AppColors.kSuccess.withValues(alpha: 0.12),
      _ => AppColors.kTextMuted.withValues(alpha: 0.12),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${s.order}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.kTextDark)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.customerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.kTextDark)),
                Text('${s.loanNumber} • ${_formatIndianCurrency(s.amount)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.kTextMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              s.status[0].toUpperCase() + s.status.substring(1),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => _startCollection(context, s),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kGoldDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Collect'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickActionTile(
            icon: Icons.location_on_outlined,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: AppColors.kGoldDark,
            title: 'View Route',
            subtitle: 'Open map & stops',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.routeMap),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickActionTile(
            icon: Icons.currency_rupee,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: AppColors.kSuccess,
            title: 'Start Collection',
            subtitle: 'Log a payment',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.agentCollection),
          ),
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: _card(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.kTextDark)),
            const SizedBox(height: 2),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
          ],
        ),
      ),
    );
  }

  void _startCollection(BuildContext context, RouteStop stop) {
    // TODO: wire to your real collection flow / arguments contract.
    Navigator.of(context).pushNamed(
      AppRoutes.agentCollection,
      arguments: {
        'loanId': stop.loanId,
        'loanNumber': stop.loanNumber,
        'customerName': stop.customerName,
        'amount': stop.amount,
      },
    );
  }
}

class _AgentStat {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  const _AgentStat(this.label, this.value, this.subtitle, this.icon,
      this.iconBg, this.iconColor);
}
