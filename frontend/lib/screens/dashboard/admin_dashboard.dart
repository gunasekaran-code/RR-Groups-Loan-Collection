import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../models/report_model.dart';
import '../../routes/app_routes.dart';
import '../../services/report_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/stat_card.dart';

String formatIndianCurrency(double? amount) {
  if (amount == null) return '₹0';
  final format =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  return format.format(amount);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _future = _load();
        _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

    @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<_DashboardData> _load() async {
    final today = DateTime.now();
    final monthStart = DateTime(today.year, today.month, 1);
    final daily = await ReportService.instance.fetchDailyReport(date: today);
    final monthly = await ReportService.instance.fetchMonthlyReport(
      start: monthStart,
      end: today,
    );
    final agent = await ReportService.instance.fetchAgentReport(
      start: monthStart,
      end: today,
    );
    return _DashboardData(daily: daily, monthly: monthly, agent: agent);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _quickAction(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is not linked yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppUser user = SessionService.instance.currentUser!;
    final theme = Theme.of(context);
    final todayLabel = DateFormat('EEEE, d MMMM y').format(DateTime.now());
    final firstName = user.name.split(' ').first;
     final greeting = _greetingForHour(_now.hour);


    return AppShell(
      currentRoute: AppRoutes.dashboard,
      title: 'Dashboard',
      body: FutureBuilder<_DashboardData>(
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
                    _buildHeroBanner(context, todayLabel, firstName, data),
                    const SizedBox(height: 16),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (error != null)
                      _errorCard(error)
                    else if (data != null) ...[
                      _buildStatGrid(data),
                      const SizedBox(height: 16),
                      _buildCollectionTrendCard(data.monthly.collectionTrend),
                      const SizedBox(height: 16),
                      _buildLoanStatusCard(data.monthly),
                      const SizedBox(height: 16),
                      _buildAgentPerformanceCard(data.agent),
                      const SizedBox(height: 16),
                      _buildMonthlyProgressCard(data.monthly),
                      const SizedBox(height: 16),
                      _buildQuickActionsCard(context),
                      const SizedBox(height: 16),
                      _buildRecentCollectionsCard(
                          context, data.daily.collections),
                      const SizedBox(height: 16),
                      _buildRecentLoansCard(context, data.daily.newLoans),
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

  String _greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

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

  

  Widget _buildHeroBanner(BuildContext context, String today, String firstName,
      _DashboardData? data) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final collections = data?.daily.summary.totalCollected ?? 0;
    final loans = data?.monthly.summary.activeLoans ?? 0;
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
              Text('Good morning, $firstName',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Live figures from the database: ${formatIndianCurrency(collections)} collected today and $loans active loans.',
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildStatGrid(_DashboardData data) {
    final daily = data.daily;
    final monthly = data.monthly;
    final activeLoans = monthly.summary.activeLoans;
    final overdueLoans = monthly.summary.overdueLoans;
    final totalLoans = activeLoans + overdueLoans;

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
          value: '$activeLoans',
          icon: Icons.account_balance_outlined,
          iconColor: Colors.blue,
          iconBackground: const Color(0xFFDCEAFE),
        ),
        StatCard(
          label: 'New Customers',
          value: '${monthly.summary.newCustomers}',
          icon: Icons.people_outline,
          iconColor: Colors.blue,
          iconBackground: const Color(0xFFDCEAFE),
        ),
        StatCard(
          label: "Today's Collections",
          value: formatIndianCurrency(daily.summary.totalCollected),
          icon: Icons.currency_rupee,
          iconColor: Colors.green,
          iconBackground: const Color(0xFFDCFCE7),
        ),
        StatCard(
          label: 'Overdue Accounts',
          value: '$overdueLoans',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red,
          iconBackground: const Color(0xFFFEE2E2),
        ),
        StatCard(
          label: 'Pending Approvals',
          value: '$totalLoans',
          icon: Icons.access_time_rounded,
          iconColor: Colors.orange,
          iconBackground: const Color(0xFFFEF3C7),
        ),
        StatCard(
          label: 'Total Loan Amount',
          value: formatIndianCurrency(monthly.summary.disbursement),
          icon: Icons.credit_card_outlined,
          iconColor: const Color(0xFF7C3AED),
          iconBackground: const Color(0xFFEDE9FE),
        ),
        StatCard(
          label: 'Interest Revenue',
          value: formatIndianCurrency(monthly.summary.interest),
          icon: Icons.trending_up_rounded,
          iconColor: Colors.green,
          iconBackground: const Color(0xFFDCFCE7),
        ),
        StatCard(
          label: 'Monthly Collection',
          value: formatIndianCurrency(monthly.summary.collected),
          icon: Icons.calendar_month_outlined,
          iconColor: Colors.blue,
          iconBackground: const Color(0xFFDCEAFE),
        ),
      ],
    );
  }

  Widget _buildCollectionTrendCard(List<MonthPoint> trend) {
    final values = trend.map((e) => e.value).toList();
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Collection Trend', 'Last months from reports table'),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(
                  values: _normalize(values), color: AppColors.kInfo),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: trend
                .map((m) => Text(m.label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.kTextMuted)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanStatusCard(MonthlyReport monthly) {
    final active = monthly.summary.activeLoans.toDouble();
    final overdue = monthly.summary.overdueLoans.toDouble();
    final closed =
        (monthly.summary.collectionCount - overdue).clamp(0, 999999).toDouble();
    final slices = [
      _DonutSlice('Active', active, AppColors.kSuccess),
      _DonutSlice('Overdue', overdue, AppColors.kDanger),
      _DonutSlice('Closed/Other', closed, AppColors.kTextMuted),
    ];
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Loan Status', 'Live database summary'),
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
                      .map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: s.color,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(s.label,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.kTextDark))),
                                Text('${s.value.toInt()}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kTextDark)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentPerformanceCard(AgentReport agentReport) {
    final data = agentReport.chart
        .map((e) =>
            _BarDatum(e.label, _scaleValue(e.value), color: AppColors.kInfo))
        .toList();
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionHeader('Agent Performance', 'Top field agents from report'),
          const SizedBox(height: 20),
          SizedBox(
              height: 200,
              child: _buildBarChart(data, defaultColor: AppColors.kInfo)),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<_BarDatum> data, {required Color defaultColor}) {
    const double chartHeight = 120;
    return SizedBox(
      height: chartHeight + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final barColor = d.color ?? defaultColor;
          final barHeight = (d.value.clamp(0.0, 1.0)) * chartHeight;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${(d.value * 100).round()}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: barColor)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: chartHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        child: Container(
                          height: barHeight < 4 && d.value > 0 ? 4 : barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                barColor.withOpacity(d.value == 0 ? 0.3 : 0.85),
                                barColor.withOpacity(d.value == 0 ? 0.15 : 0.55)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(d.label,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.kTextMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyProgressCard(MonthlyReport monthly) {
    final target =
        monthly.summary.disbursement <= 0 ? 1.0 : monthly.summary.disbursement;
    final progress = (monthly.summary.collected / target).clamp(0.0, 1.0);
    final percentLabel = (progress * 100).toStringAsFixed(1);
    final fmt = NumberFormat.decimalPattern('en_IN');
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Monthly Collection Progress',
              '₹${fmt.format(monthly.summary.collected)} of ₹${fmt.format(target)} target',
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.kSuccess.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.kSuccess.withOpacity(0.3)),
                ),
                child: Text('$percentLabel%',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kSuccess)),
              )),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.4),
              valueColor: const AlwaysStoppedAnimation(AppColors.kInfo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction('Add Customer', Icons.person_add_alt_outlined,
          AppColors.kInfo, () => _quickAction(context, 'Add Customer')),
      _QuickAction(
          'Create Loan',
          Icons.account_balance_outlined,
          AppColors.kSuccess,
          () => Navigator.of(context).pushNamed(AppRoutes.loans)),
      _QuickAction('Chit Group', Icons.groups_outlined, const Color(0xFF7C3AED),
          () => Navigator.of(context).pushNamed(AppRoutes.chitGroups)),
      _QuickAction('Add Agent', Icons.badge_outlined, AppColors.kWarning,
          () => _quickAction(context, 'Add Agent')),
      _QuickAction('Reports', Icons.description_outlined, AppColors.kInfo,
          () => _quickAction(context, 'Reports')),
    ];
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextDark)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            children:
                actions.map((a) => _QuickActionButton(action: a)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCollectionsCard(
      BuildContext context, List<CollectionEntry> items) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Recent Collections',
            'Latest payments received',
            trailing: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.collections),
                child: const Text('View all')),
          ),
          Divider(height: 20, color: Colors.white.withOpacity(0.6)),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No collections found for today.',
                  style: TextStyle(color: AppColors.kTextMuted)),
            )
          else
            ...items.take(5).map((item) => _glassListRow(
                  icon: Icons.call_received_rounded,
                  iconColor: AppColors.kSuccess,
                  iconBg: const Color(0xFFDCFCE7),
                  title: item.customerName,
                  subtitle: '${item.loanNumber} • ${item.paymentMethod}',
                  trailingTop: formatIndianCurrency(item.collectionAmount),
                  trailingBottom: _prettyDate(item.collectionDate.isNotEmpty
                      ? item.collectionDate
                      : item.createdAt),
                )),
        ],
      ),
    );
  }

  Widget _buildRecentLoansCard(BuildContext context, List<NewLoanEntry> items) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Recent Loans',
            'Newly disbursed loans',
            trailing: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.loans),
                child: const Text('View all')),
          ),
          Divider(height: 20, color: Colors.white.withOpacity(0.6)),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No new loans found for today.',
                  style: TextStyle(color: AppColors.kTextMuted)),
            )
          else
            ...items.take(5).map((item) {
              final statusColor = switch (item.status.toLowerCase()) {
                'active' => AppColors.kSuccess,
                'overdue' => AppColors.kDanger,
                _ => AppColors.kTextMuted,
              };
              return _glassListRow(
                icon: Icons.account_balance_outlined,
                iconColor: AppColors.kInfo,
                iconBg: const Color(0xFFDCEAFE),
                title: item.customerName,
                subtitle: '${item.loanNumber} • ${item.loanType}',
                trailingTop: formatIndianCurrency(item.loanAmount),
                trailingBottom: item.status,
                trailingBottomColor: statusColor,
              );
            }),
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

  List<double> _normalize(List<double> values) {
    if (values.isEmpty) return const [];
    final maxValue =
        values.fold<double>(0, (max, value) => value > max ? value : max);
    if (maxValue <= 0) return List<double>.filled(values.length, 0);
    return values.map((v) => v / maxValue).toList();
  }

  double _scaleValue(double value) {
    if (value <= 0) return 0;
    return value;
  }

  String _prettyDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy').format(parsed);
  }
}

class _DashboardData {
  _DashboardData({
    required this.daily,
    required this.monthly,
    required this.agent,
  });

  final DailyReport daily;
  final MonthlyReport monthly;
  final AgentReport agent;
}

class _DonutSlice {
  final String label;
  final double value;
  final Color color;
  const _DonutSlice(this.label, this.value, this.color);
}

class _BarDatum {
  final String label;
  final double value;
  final Color? color;
  const _BarDatum(this.label, this.value, {this.color});
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _QuickAction(this.label, this.icon, this.color, this.onTap);
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.55)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: action.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(action.icon, color: action.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _LineChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final dx = values.length > 1 ? size.width / (values.length - 1) : 0.0;
    final points = <Offset>[
      for (int i = 0; i < values.length; i++)
        Offset(dx * i, size.height - (values[i].clamp(0.0, 1.0) * size.height)),
    ];
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      linePath.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    linePath.lineTo(points.last.dx, points.last.dy);
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.28), color.withOpacity(0.0)])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);
    final dotPaint = Paint()..color = color;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
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
