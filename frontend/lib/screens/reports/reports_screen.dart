import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart'; // adjust path if your app_theme.dart lives elsewhere
import '../../widgets/app_shell.dart';
import '../../theme/glass_toast.dart';

/// -----------------------------------------------------------------------
/// HELPERS
/// -----------------------------------------------------------------------
String formatIndianCurrency(num value, {bool withSymbol = true}) {
  final isNegative = value < 0;
  final intVal = value.abs().round();
  final str = intVal.toString();

  String formatted;
  if (str.length <= 3) {
    formatted = str;
  } else {
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      final posFromEnd = rest.length - i;
      buffer.write(rest[i]);
      if (posFromEnd > 1 && posFromEnd % 2 == 1) {
        buffer.write(',');
      }
    }
    formatted = '${buffer.toString()},$lastThree';
  }

  return '${withSymbol ? '₹' : ''}${isNegative ? '-' : ''}$formatted';
}

String formatCompact(num value) {
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
  return value.round().toString();
}

String formatSlashDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

/// -----------------------------------------------------------------------
/// MODELS
/// -----------------------------------------------------------------------
enum ReportTab { daily, monthly, agent }

class MonthPoint {
  const MonthPoint(this.label, this.value);
  final String label;
  final double value;
}

class AgentPerf {
  const AgentPerf({
    required this.name,
    required this.assigned,
    required this.collectedCount,
    required this.collectedAmount,
  });
  final String name;
  final int assigned;
  final int collectedCount;
  final double collectedAmount;
}

/// -----------------------------------------------------------------------
/// SCREEN
/// -----------------------------------------------------------------------
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ScrollController _scrollController =
      ScrollController(); // Fixes web scrollbar controller exceptions
  ReportTab _tab = ReportTab.daily;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 13));
  DateTime _endDate = DateTime.now();

  // TODO(backend): replace all sample data below with real API responses.
  final List<Map<String, String>> _todaysCollections = const [];
  final List<Map<String, String>> _newLoansToday = const [];

  final double _loanDisbursement = 150000;
  final double _interestEarned = 17627;
  final double _collectionTotal = 13699;
  final int _newCustomers = 0;

  final List<MonthPoint> _collectionsTrend = const [
    MonthPoint('Feb 26', 0),
    MonthPoint('Mar 26', 0),
    MonthPoint('Apr 26', 0),
    MonthPoint('May 26', 0),
    MonthPoint('Jun 26', 100),
    MonthPoint('Jul 26', 14),
  ];

  final List<MonthPoint> _loanDisbursementByMonth = const [
    MonthPoint('Feb 26', 0),
    MonthPoint('Mar 26', 0),
    MonthPoint('Apr 26', 0),
    MonthPoint('May 26', 0),
    MonthPoint('Jun 26', 1900000),
    MonthPoint('Jul 26', 150000),
  ];

  final List<AgentPerf> _agentPerformance = const [
    AgentPerf(
        name: 'Arjun Mehta',
        assigned: 4,
        collectedCount: 3,
        collectedAmount: 13699),
    AgentPerf(
        name: 'Sneha Reddy',
        assigned: 0,
        collectedCount: 0,
        collectedAmount: 0),
    AgentPerf(
        name: 'Priya Sharma',
        assigned: 0,
        collectedCount: 0,
        collectedAmount: 0),
    AgentPerf(
        name: 'Unassigned', assigned: 1, collectedCount: 0, collectedAmount: 0),
  ];

  List<MonthPoint> get _collectionsByAgent => _agentPerformance
      .where((a) => a.name != 'Unassigned')
      .map((a) => MonthPoint(a.name.split(' ').first, a.collectedAmount))
      .toList();

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              Theme.of(context).colorScheme.copyWith(primary: AppColors.kGold),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _exportPdf() async {
    // 1. Show the initial "Loading/Info" status
    ToastService.show(
      title: 'Exporting PDF',
      message: 'Your report is being prepared...',
      type: ToastType.info,
    );

    try {
      // TODO(backend): Hook up real PDF export here
      // Example: await backendService.generatePdf();

      // 2. Show success toast if it works
      ToastService.show(
        title: 'Export Complete',
        message: 'PDF has been downloaded successfully.',
        type: ToastType.success,
      );
    } catch (error) {
      // 3. Catch any failures and display the error message
      ToastService.show(
        title: 'Export Failed',
        message: error.toString(), // Passes the actual error message
        type: ToastType.error, // Triggers the iOS System Red style
      );
    }
  }

  Future<void> _exportExcel() async {
    ToastService.show(
      title: 'Exporting Excel',
      message: 'Compiling spreadsheet cells...',
      type: ToastType.info,
    );

    try {
      // TODO(backend): Hook up real Excel export here
      // Example: await backendService.generateExcel();

      ToastService.show(
        title: 'Export Complete',
        message: 'Excel sheet generated successfully.',
        type: ToastType.success,
      );
    } catch (error) {
      ToastService.show(
        title: 'Export Failed',
        message: 'Could not generate spreadsheet. Technical reason: $error',
        type: ToastType.error,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Properly dispose the scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.reports,
      title: 'Reports & Analytics',
      body: ListView(
        controller: _scrollController, // Connected scroll controller
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Added the missing main page heading widget here
          const SizedBox(height: 6),
          const Text(
            'Daily, monthly and agent performance insights',
            style: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final pdfBtn = OutlinedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Export PDF'),
              );
              final excelBtn = ElevatedButton.icon(
                onPressed: _exportExcel,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Export Excel',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              );
              if (narrow) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: pdfBtn),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: excelBtn),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: pdfBtn),
                  const SizedBox(width: 12),
                  Expanded(child: excelBtn),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _SegmentedTabs(
            selected: _tab,
            onChanged: (t) => setState(() => _tab = t),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppColors.kTextMuted),
              const SizedBox(width: 8),
              Expanded(
                child: _DateField(
                  date: _startDate,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    size: 16, color: AppColors.kTextMuted),
              ),
              Expanded(
                child: _DateField(
                  date: _endDate,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          switch (_tab) {
            ReportTab.daily => _DailyReportSection(
                collections: _todaysCollections,
                newLoans: _newLoansToday,
              ),
            ReportTab.monthly => _MonthlyReportSection(
                loanDisbursement: _loanDisbursement,
                interestEarned: _interestEarned,
                collectionTotal: _collectionTotal,
                newCustomers: _newCustomers,
                trend: _collectionsTrend,
                disbursementByMonth: _loanDisbursementByMonth,
              ),
            ReportTab.agent => _AgentPerformanceSection(
                agents: _agentPerformance,
                collectionsByAgent: _collectionsByAgent,
              ),
          },
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// SEGMENTED TABS
/// -----------------------------------------------------------------------
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.selected, required this.onChanged});
  final ReportTab selected;
  final ValueChanged<ReportTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFE8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tabButton(context, ReportTab.daily, 'Daily\nReport'),
          _tabButton(context, ReportTab.monthly, 'Monthly\nReport'),
          _tabButton(context, ReportTab.agent, 'Agent\nPerformance'),
        ],
      ),
    );
  }

  Widget _tabButton(BuildContext context, ReportTab tab, String label) {
    final isSelected = tab == selected;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(tab),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.kSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.kTextDark : AppColors.kTextMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// DATE FIELD
/// -----------------------------------------------------------------------
class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Text(
          formatSlashDate(date),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.kTextDark, fontSize: 14),
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// SECTION CARD (header with icon + title + count badge)
/// -----------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextDark,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _EmptyMini extends StatelessWidget {
  const _EmptyMini(
      {required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EFE8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// DAILY REPORT
/// -----------------------------------------------------------------------
class _DailyReportSection extends StatelessWidget {
  const _DailyReportSection(
      {required this.collections, required this.newLoans});
  final List<Map<String, String>> collections;
  final List<Map<String, String>> newLoans;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.kInfo,
          title: "Today's Collections",
          count: collections.length,
          child: collections.isEmpty
              ? const _EmptyMini(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No collections today',
                  message: 'Collections made today will appear here.',
                )
              : Column(
                  children: collections
                      .map(
                        (c) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(c['customer'] ?? ''),
                          subtitle: Text(c['time'] ?? ''),
                          trailing: Text(
                            c['amount'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.kSuccess),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          icon: Icons.currency_rupee_rounded,
          iconColor: const Color(0xFF7C3AED),
          title: 'New Loans Created Today',
          count: newLoans.length,
          child: newLoans.isEmpty
              ? const _EmptyMini(
                  icon: Icons.description_outlined,
                  title: 'No new loans today',
                  message: 'Loans created today will appear here.',
                )
              : Column(
                  children: newLoans
                      .map(
                        (l) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l['customer'] ?? ''),
                          subtitle: Text(l['loanNo'] ?? ''),
                          trailing: Text(
                            l['amount'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.kTextDark),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

/// -----------------------------------------------------------------------
/// MONTHLY REPORT
/// -----------------------------------------------------------------------
class _MonthlyReportSection extends StatelessWidget {
  const _MonthlyReportSection({
    required this.loanDisbursement,
    required this.interestEarned,
    required this.collectionTotal,
    required this.newCustomers,
    required this.trend,
    required this.disbursementByMonth,
  });

  final double loanDisbursement;
  final double interestEarned;
  final double collectionTotal;
  final int newCustomers;
  final List<MonthPoint> trend;
  final List<MonthPoint> disbursementByMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricRow(
          label: 'LOAN DISBURSEMENT',
          value: formatIndianCurrency(loanDisbursement),
          icon: Icons.account_balance_wallet_outlined,
          iconBg: const Color(0xFFDCEAFE),
          iconColor: AppColors.kInfo,
        ),
        const SizedBox(height: 12),
        _MetricRow(
          label: 'INTEREST EARNED',
          value: formatIndianCurrency(interestEarned),
          icon: Icons.trending_up_rounded,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: AppColors.kSuccess,
        ),
        const SizedBox(height: 12),
        _MetricRow(
          label: 'COLLECTION TOTAL',
          value: formatIndianCurrency(collectionTotal),
          icon: Icons.currency_rupee_rounded,
          iconBg: const Color(0xFFEDE9FE),
          iconColor: const Color(0xFF7C3AED),
        ),
        const SizedBox(height: 12),
        _MetricRow(
          label: 'NEW CUSTOMERS',
          value: '$newCustomers',
          icon: Icons.people_alt_outlined,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: AppColors.kWarning,
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Collections Trend',
          subtitle: 'Last ${trend.length} months',
          child: _SimpleLineChart(points: trend),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Loan Disbursement',
          subtitle: 'By month',
          child: _SimpleBarChart(
              points: disbursementByMonth, valueFormatter: formatCompact),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kTextMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextDark),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// AGENT PERFORMANCE
/// -----------------------------------------------------------------------
class _AgentPerformanceSection extends StatelessWidget {
  const _AgentPerformanceSection(
      {required this.agents, required this.collectionsByAgent});
  final List<AgentPerf> agents;
  final List<MonthPoint> collectionsByAgent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          icon: Icons.people_alt_outlined,
          iconColor: AppColors.kInfo,
          title: 'Agent Performance',
          count: agents.length,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 52,
              columnSpacing: 28,
              headingTextStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextMuted,
                letterSpacing: 0.3,
              ),
              dataTextStyle:
                  const TextStyle(fontSize: 14, color: AppColors.kTextDark),
              columns: const [
                DataColumn(label: Text('AGENT')),
                DataColumn(label: Text('ASSIGNED')),
                DataColumn(label: Text('COLLECTED')),
              ],
              rows: agents
                  .map(
                    (a) => DataRow(
                      cells: [
                        DataCell(Text(a.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text('${a.assigned}')),
                        DataCell(Text(
                            '${a.collectedCount} / ${formatIndianCurrency(a.collectedAmount)}')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Collections by Agent',
          subtitle: 'Total amount collected',
          child: _SimpleBarChart(
              points: collectionsByAgent, valueFormatter: formatCompact),
        ),
      ],
    );
  }
}

/// -----------------------------------------------------------------------
/// CHART CARD WRAPPER
/// -----------------------------------------------------------------------
class _ChartCard extends StatelessWidget {
  const _ChartCard(
      {required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextDark)),
          Text(subtitle,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
          const SizedBox(height: 16),
          SizedBox(height: 180, width: double.infinity, child: child),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// SIMPLE LINE / AREA CHART (no external chart package required)
/// -----------------------------------------------------------------------
class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({required this.points});
  final List<MonthPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
          child:
              Text('No data', style: TextStyle(color: AppColors.kTextMuted)));
    }
    return CustomPaint(
      painter: _LineChartPainter(points: points),
      child: Container(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.points});
  final List<MonthPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const bottomAxisHeight = 20.0;
    final chartHeight = size.height - bottomAxisHeight;
    final maxVal =
        points.map((p) => p.value).fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1 : maxVal;
    final stepX =
        points.length > 1 ? size.width / (points.length - 1) : size.width;

    final linePath = Path();
    final fillPath = Path();
    final dotOffsets = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = stepX * i;
      final y = chartHeight - (points[i].value / safeMax) * chartHeight;
      dotOffsets.add(Offset(x, y));
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(stepX * (points.length - 1), chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.kInfo.withOpacity(0.25),
          AppColors.kInfo.withOpacity(0.0)
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.kInfo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = AppColors.kInfo;
    for (final o in dotOffsets) {
      canvas.drawCircle(o, 3, dotPaint);
    }

    final basePaint = Paint()
      ..color = AppColors.kBorder
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, chartHeight), Offset(size.width, chartHeight), basePaint);

    const textStyle = TextStyle(color: AppColors.kTextMuted, fontSize: 10);
    for (int i = 0; i < points.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: points[i].label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (stepX * i - tp.width / 2).clamp(0, size.width - tp.width);
      tp.paint(canvas, Offset(x.toDouble(), chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

/// -----------------------------------------------------------------------
/// SIMPLE BAR CHART (no external chart package required)
/// -----------------------------------------------------------------------
class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart({required this.points, required this.valueFormatter});
  final List<MonthPoint> points;
  final String Function(num) valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
          child:
              Text('No data', style: TextStyle(color: AppColors.kTextMuted)));
    }
    final maxVal =
        points.map((p) => p.value).fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1 : maxVal;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((p) {
        final heightFraction = (p.value / safeMax).clamp(0.02, 1.0);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  valueFormatter(p.value),
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.kTextMuted,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: heightFraction,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.kInfo,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.kTextMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
