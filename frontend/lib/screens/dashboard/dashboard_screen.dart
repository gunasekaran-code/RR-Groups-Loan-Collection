import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/stat_card.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ---- Mock data (TODO(backend): replace with real aggregates from API) ----

  static const List<double> _collectionTrend = [
    0.15, 0.22, 0.18, 0.35, 0.5, 1.0
  ];
  static const List<String> _collectionTrendLabels = [
    'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'
  ];

  static const List<_DonutSlice> _loanStatusSlices = [
    _DonutSlice('Active', 4, AppColors.kSuccess),
    _DonutSlice('Overdue', 1, AppColors.kDanger),
    _DonutSlice('Pending', 1, AppColors.kWarning),
    _DonutSlice('Closed', 1, AppColors.kTextMuted),
  ];

  static const List<_BarDatum> _branchPerformance = [
    _BarDatum('Main', 0.16, color: AppColors.kInfo),
    _BarDatum('North', 0.3, color: AppColors.kSuccess),
    _BarDatum('South', 0.40, color: AppColors.kWarning),
  ];

  static const List<_BarDatum> _agentPerformance = [
    _BarDatum('Arjun', 0.67, color: AppColors.kInfo),
    _BarDatum('Sneha', 0.55, color: AppColors.kSuccess),
    _BarDatum('Priya', 0.70, color: AppColors.kWarning),
  ];

  static const int _monthlyCollected = 340000;
  static const int _monthlyTarget = 1550000;

  static const List<_ActivityItem> _recentCollections = [
    _ActivityItem(name: 'Lakshmi Iyer', sub: 'LN-627299 • Cash', amount: '₹4,349', date: '10 Jul 2026'),
    _ActivityItem(name: 'Vikram Naidu', sub: 'LN-AB12C3 • Cash', amount: '₹5,000', date: '08 Jul 2026'),
    _ActivityItem(name: 'Lakshmi Iyer', sub: 'LN-627299 • Cash', amount: '₹4,349', date: '22 Jun 2026'),
    _ActivityItem(name: 'Anjali Singh', sub: 'LN-GH6718 • Bank Transfer', amount: '₹17,156', date: '01 Jul 2026'),
  ];

  static const List<_LoanItem> _recentLoans = [
    _LoanItem(name: 'Lakshmi Iyer', sub: 'LN-232037 • Monthly', amount: '₹50,000', status: 'Active'),
    _LoanItem(name: 'Lakshmi Iyer', sub: 'LN-627299 • Monthly', amount: '₹50,000', status: 'Active'),
    _LoanItem(name: 'Vikram Naidu', sub: 'LN-AB12C3 • Monthly', amount: '₹5,00,000', status: 'Active'),
    _LoanItem(name: 'Lakshmi Iyer', sub: 'LN-DE34F5 • Monthly', amount: '₹2,00,000', status: 'Overdue'),
    _LoanItem(name: 'Anjali Singh', sub: 'LN-GH6718 • Monthly', amount: '₹1,00,000', status: 'Closed'),
  ];

  void _quickAction(BuildContext context, String label) {
    // TODO(backend): wire these up to their real destinations/dialogs.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppUser user = SessionService.instance.currentUser!;
    final theme = Theme.of(context);
    final String today = DateFormat('EEEE, d MMMM y').format(DateTime.now());
    final String firstName = user.name.split(' ').first;

    return AppShell(
      currentRoute: AppRoutes.dashboard,
      title: 'Dashboard',
      body: Stack(
        children: [
          // ---- Glass background: base color + soft blurred color orbs ----
          Positioned.fill(
            child: Container(color: theme.scaffoldBackgroundColor),
          ),
          Positioned(
            top: -60,
            left: -40,
            child: _blurOrb(220, AppColors.kGold.withOpacity(0.35)),
          ),
          Positioned(
            top: 220,
            right: -60,
            child: _blurOrb(200, AppColors.kInfo.withOpacity(0.28)),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _blurOrb(240, AppColors.kSuccess.withOpacity(0.22)),
          ),
          Positioned(
            bottom: -40,
            right: -30,
            child: _blurOrb(180, const Color(0xFF7C3AED).withOpacity(0.22)),
          ),

          // ---- Foreground content ----
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeroBanner(context, today, firstName),
              const SizedBox(height: 16),
              _buildStatGrid(),
              const SizedBox(height: 16),
              _buildCollectionTrendCard(),
              const SizedBox(height: 16),
              _buildLoanStatusCard(),
              const SizedBox(height: 16),
              _buildBranchPerformanceCard(),
              const SizedBox(height: 16),
              _buildAgentPerformanceCard(),
              const SizedBox(height: 16),
              _buildMonthlyProgressCard(),
              const SizedBox(height: 16),
              _buildQuickActionsCard(context),
              const SizedBox(height: 16),
              _buildRecentCollectionsCard(context),
              const SizedBox(height: 16),
              _buildRecentLoansCard(context),
            ],
          ),
        ],
      ),
    );
  }

  // Decorative soft-focus color blob used behind the glass layers.
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
                colors: [color, color.withOpacity(0.0)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Core glass card wrapper
  // ==========================================
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
            border: Border.all(
              color: Colors.white.withOpacity(0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
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

  // ---- Hero banner (glass over gold gradient) ----
  Widget _buildHeroBanner(BuildContext context, String today, String firstName) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.kGoldDark.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(today.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Text('Good morning, $firstName',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'You have 1 pending approval and 1 overdue account requiring your attention.',
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _glassPillButton(
                      label: 'View Approvals',
                      filled: true,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.loans),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _glassPillButton(
                      label: 'Review Overdue',
                      filled: false,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.overdue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassPillButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: filled ? Colors.white.withOpacity(0.92) : Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(filled ? 0.0 : 0.5),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: filled ? AppColors.kGoldDark : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ---- Stat grid ----
  Widget _buildStatGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15, // Adjusted slightly to provide extra vertical safety for trends & currency text
      children: const [
        StatCard(
          label: 'Active Loans',
          value: '4',
          trend: '+8%',
          trendUp: true,
          icon: Icons.account_balance_outlined,
          iconColor: Colors.blue, // Replace with AppColors.kInfo if setup
          iconBackground: Color(0xFFDCEAFE),
        ),
        StatCard(
          label: 'Total Customers',
          value: '5',
          trend: '+3',
          trendUp: true,
          icon: Icons.people_outline,
          iconColor: Colors.blue, // Replace with AppColors.kInfo
          iconBackground: Color(0xFFDCEAFE),
        ),
        StatCard(
          label: "Today's Collections",
          value: '₹0',
          icon: Icons.currency_rupee,
          iconColor: Colors.green, // Replace with AppColors.kSuccess
          iconBackground: Color(0xFFDCFCE7),
        ),
        StatCard(
          label: 'Overdue Accounts',
          value: '1',
          trend: '+1',
          trendUp: false,
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red, // Replace with AppColors.kDanger
          iconBackground: Color(0xFFFEE2E2),
        ),
        StatCard(
          label: 'Pending Approvals',
          value: '1',
          icon: Icons.access_time_rounded,
          iconColor: Colors.orange, // Replace with AppColors.kWarning
          iconBackground: Color(0xFFFEF3C7),
        ),
        StatCard(
          label: 'Total Loan Amount',
          value: '₹19,50,000',
          icon: Icons.credit_card_outlined,
          iconColor: Color(0xFF7C3AED),
          iconBackground: Color(0xFFEDE9FE),
        ),
        StatCard(
          label: 'Interest Revenue',
          value: '₹1,25,000',
          trend: '+5%',
          trendUp: true,
          icon: Icons.trending_up_rounded,
          iconColor: Colors.green, // Replace with AppColors.kSuccess
          iconBackground: Color(0xFFDCFCE7),
        ),
        StatCard(
          label: 'Monthly Collection',
          value: '₹3,40,000',
          icon: Icons.calendar_month_outlined,
          iconColor: Colors.blue, // Replace with AppColors.kInfo
          iconBackground: Color(0xFFDCEAFE),
        ),
      ],
    );
  }

  // ---- Collection Trend (line chart) ----
  Widget _buildCollectionTrendCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Collection Trend', 'Last 6 months'),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(values: _collectionTrend, color: AppColors.kInfo),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _collectionTrendLabels
                .map((m) => Text(m, style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ---- Loan Status (donut chart) ----
  Widget _buildLoanStatusCard() {
    final total = _loanStatusSlices.fold<double>(0, (sum, s) => sum + s.value);
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Loan Status', 'Active vs Overdue vs Pending'),
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
                      painter: _DonutChartPainter(slices: _loanStatusSlices),
                      size: const Size(120, 120),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${total.toInt()}',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
                        const Text('Total', style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _loanStatusSlices
                      .map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(s.label,
                                        style: const TextStyle(fontSize: 13, color: AppColors.kTextDark))),
                                Text('${s.value.toInt()}',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextDark)),
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

  // ---- Branch / Agent performance (bar charts) ----
  Widget _buildBranchPerformanceCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionHeader('Branch Performance', 'Collection by branch'),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildBarChart(_branchPerformance, defaultColor: AppColors.kInfo),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentPerformanceCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionHeader('Agent Performance', 'Top field agents'),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildBarChart(_agentPerformance, defaultColor: AppColors.kInfo),
          ),
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
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: barColor)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: chartHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        child: Container(
                          height: barHeight < 4 && d.value > 0 ? 4 : barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                barColor.withOpacity(d.value == 0 ? 0.3 : 0.85),
                                barColor.withOpacity(d.value == 0 ? 0.15 : 0.55),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(d.label, style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---- Monthly Collection Progress ----
  Widget _buildMonthlyProgressCard() {
    final progress = (_monthlyCollected / _monthlyTarget).clamp(0.0, 1.0);
    final percentLabel = (progress * 100).toStringAsFixed(1);
    final fmt = NumberFormat.decimalPattern('en_IN');

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Monthly Collection Progress',
            '₹${fmt.format(_monthlyCollected)} of ₹${fmt.format(_monthlyTarget)} target',
            trailing: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.kSuccess.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.kSuccess.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.kSuccess),
                      const SizedBox(width: 4),
                      Text('$percentLabel%',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kSuccess)),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
              Text('50%', style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
              Text('100%', style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Quick Actions ----
  Widget _buildQuickActionsCard(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction('Add Customer', Icons.person_add_alt_outlined, AppColors.kInfo,
          () => _quickAction(context, 'Add Customer')),
      _QuickAction('Create Loan', Icons.account_balance_outlined, AppColors.kSuccess,
          () => Navigator.of(context).pushNamed(AppRoutes.loans)),
      _QuickAction('Chit Group', Icons.groups_outlined, const Color(0xFF7C3AED),
          () => _quickAction(context, 'Chit Group')),
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
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: actions.map((a) => _QuickActionButton(action: a)).toList(),
          ),
        ],
      ),
    );
  }

  // ---- Recent Collections ----
  Widget _buildRecentCollectionsCard(BuildContext context) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Recent Collections',
            'Latest payments received',
            trailing: TextButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.collections),
              child: const Text('View all'),
            ),
          ),
          Divider(height: 20, color: Colors.white.withOpacity(0.6)),
          ..._recentCollections.map((item) => _glassListRow(
                icon: Icons.call_received_rounded,
                iconColor: AppColors.kSuccess,
                iconBg: const Color(0xFFDCFCE7),
                title: item.name,
                subtitle: item.sub,
                trailingTop: item.amount,
                trailingBottom: item.date,
              )),
        ],
      ),
    );
  }

  // ---- Recent Loans ----
  Widget _buildRecentLoansCard(BuildContext context) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Recent Loans',
            'Newly disbursed loans',
            trailing: TextButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.loans),
              child: const Text('View all'),
            ),
          ),
          Divider(height: 20, color: Colors.white.withOpacity(0.6)),
          ..._recentLoans.map((item) {
            final statusColor = switch (item.status) {
              'Active' => AppColors.kSuccess,
              'Overdue' => AppColors.kDanger,
              _ => AppColors.kTextMuted,
            };
            return _glassListRow(
              icon: Icons.account_balance_outlined,
              iconColor: AppColors.kInfo,
              iconBg: const Color(0xFFDCEAFE),
              title: item.name,
              subtitle: item.sub,
              trailingTop: item.amount,
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
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.kTextDark),
                          overflow: TextOverflow.ellipsis),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(trailingTop,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.kTextDark)),
                    Text(trailingBottom,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: trailingBottomColor != null ? FontWeight.w600 : FontWeight.normal,
                            color: trailingBottomColor ?? AppColors.kTextMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// Data holders
// ==========================================

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

class _ActivityItem {
  final String name;
  final String sub;
  final String amount;
  final String date;
  const _ActivityItem({required this.name, required this.sub, required this.amount, required this.date});
}

class _LoanItem {
  final String name;
  final String sub;
  final String amount;
  final String status;
  const _LoanItem({required this.name, required this.sub, required this.amount, required this.status});
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _QuickAction(this.label, this.icon, this.color, this.onTap);
}

// ==========================================
// Small widgets
// ==========================================

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
                  decoration:
                      BoxDecoration(color: action.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(action.icon, color: action.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextDark),
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

// ==========================================
// Chart painters (unchanged logic)
// ==========================================

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
        colors: [color.withOpacity(0.28), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
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
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    const strokeWidth = 16.0;
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);

    double startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweep = (slice.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      final gap = slices.length > 1 ? 0.04 : 0.0;
      canvas.drawArc(rect, startAngle + gap / 2, sweep - gap, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => oldDelegate.slices != slices;
}
