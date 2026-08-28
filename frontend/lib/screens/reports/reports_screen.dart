import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/glass_toast.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';

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

String formatSlashDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

/// Formats an ISO-ish date/time string coming from the backend
/// (e.g. "2026-07-30 14:05:00" or "2026-07-30") into "30/07/2026".
String formatBackendDate(String raw) {
  if (raw.isEmpty) return '';
  final datePart = raw.split(' ').first.split('T').first;
  final parsed = DateTime.tryParse(datePart);
  if (parsed == null) return raw;
  return formatSlashDate(parsed);
}

/// Formats a backend timestamp into a short time string, e.g. "2:05 PM".
String formatBackendTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return '';
  return DateFormat('h:mm a').format(parsed);
}

/// -----------------------------------------------------------------------
/// MODELS (UI-local)
/// -----------------------------------------------------------------------
enum ReportTab { daily, monthly, agent }

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
  final ReportService _reportService = ReportService.instance;

  ReportTab _tab = ReportTab.daily;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 13));
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  String? _errorMessage;

  DailyReport? _dailyReport;
  MonthlyReport? _monthlyReport;
  AgentReport? _agentReport;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Properly dispose the scroll controller
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      switch (_tab) {
        case ReportTab.daily:
          // Daily report is for a single date; use the end date of the
          // selected range as "the day" being reported on.
          final report = await _reportService.fetchDailyReport(date: _endDate);
          if (!mounted) return;
          setState(() => _dailyReport = report);
          break;
        case ReportTab.monthly:
          final report = await _reportService.fetchMonthlyReport(
            start: _startDate,
            end: _endDate,
          );
          if (!mounted) return;
          setState(() => _monthlyReport = report);
          break;
        case ReportTab.agent:
          final report = await _reportService.fetchAgentReport(
            start: _startDate,
            end: _endDate,
          );
          if (!mounted) return;
          setState(() => _agentReport = report);
          break;
      }
    } on ReportApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = l10n.reportsGenericErrorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeTab(ReportTab t) {
    if (t == _tab) return;
    setState(() => _tab = t);
    _loadData();
  }

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
    _loadData();
  }

  Future<void> _exportExcel() async {
    final l10n = AppLocalizations.of(context)!;
    ToastService.show(
      title: l10n.reportsExportingExcelTitle,
      message: l10n.reportsExportingExcelMessage,
      type: ToastType.info,
    );

    try {
      // TODO(backend): Hook up real Excel export here
      // Example: await backendService.generateExcel();

      ToastService.show(
        title: l10n.reportsExportCompleteTitle,
        message: l10n.reportsExportCompleteMessage,
        type: ToastType.success,
      );
    } catch (error) {
      ToastService.show(
        title: l10n.reportsExportFailedTitle,
        message: l10n.reportsExportFailedMessage(error.toString()),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppShell(
      currentRoute: AppRoutes.reports,
      title: l10n.reportsScreenTitle,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          controller: _scrollController, // Connected scroll controller
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const SizedBox(height: 6),
            Text(
              l10n.reportsSubtitle,
              style: const TextStyle(color: AppColors.kTextMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 380;
                // final pdfBtn = OutlinedButton.icon(
                //   onPressed: _exportPdf,
                //   icon: const Icon(Icons.description_outlined, size: 18),
                //   label: Text(l10n.reportsExportPdfButton),
                // );
                // final excelBtn = ElevatedButton.icon(
                //   onPressed: _exportExcel,
                //   icon: const Icon(Icons.file_download_outlined, size: 18),
                //   label: Text(l10n.reportsExportExcelButton,
                //       style: const TextStyle(fontWeight: FontWeight.w600)),
                // );
                if (narrow) {
                  return Column(
                    children: [
                      // SizedBox(width: double.infinity, child: pdfBtn),
                      const SizedBox(height: 10),
                      // SizedBox(width: double.infinity, child: excelBtn),
                    ],
                  );
                }
                return Row(
                  children: [
                    // Expanded(child: pdfBtn),
                    const SizedBox(width: 12),
                    // Expanded(child: excelBtn),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _SegmentedTabs(
              selected: _tab,
              onChanged: _changeTab,
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
            if (_tab == ReportTab.daily) ...[
              const SizedBox(height: 6),
              Text(
                l10n.reportsDailyHint,
                style: const TextStyle(color: AppColors.kTextMuted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            _buildBody(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: AppColors.kGold)),
      );
    }

    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadData);
    }

    switch (_tab) {
      case ReportTab.daily:
        if (_dailyReport == null) return const SizedBox.shrink();
        return _DailyReportSection(report: _dailyReport!);
      case ReportTab.monthly:
        if (_monthlyReport == null) return const SizedBox.shrink();
        return _MonthlyReportSection(report: _monthlyReport!);
      case ReportTab.agent:
        if (_agentReport == null) return const SizedBox.shrink();
        return _AgentPerformanceSection(report: _agentReport!);
    }
  }
}

/// -----------------------------------------------------------------------
/// ERROR STATE
/// -----------------------------------------------------------------------
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.kTextMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.reportsRetryButton),
          ),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFE8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tabButton(context, ReportTab.daily, l10n.reportsTabDaily),
          _tabButton(context, ReportTab.monthly, l10n.reportsTabMonthly),
          _tabButton(context, ReportTab.agent, l10n.reportsTabAgent),
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
                      color: Colors.black.withValues(alpha: 0.06),
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

class _DailyReportSection extends StatelessWidget {
  const _DailyReportSection({required this.report});
  final DailyReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final collections = report.collections;
    final newLoans = report.newLoans;

    return Column(
      children: [
        _SectionCard(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.kInfo,
          title: l10n.reportsTodaysCollectionsTitle,
          count: collections.length,
          child: collections.isEmpty
              ? _EmptyMini(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.reportsNoCollectionsTodayTitle,
                  message: l10n.reportsNoCollectionsTodayMessage,
                )
              : Column(
                  children: collections
                      .map(
                        (c) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.customerName),
                          subtitle: Text(formatBackendTime(c.createdAt)),
                          trailing: Text(
                            formatIndianCurrency(c.collectionAmount),
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
          title: l10n.reportsNewLoansTodayTitle,
          count: newLoans.length,
          child: newLoans.isEmpty
              ? _EmptyMini(
                  icon: Icons.description_outlined,
                  title: l10n.reportsNoNewLoansTodayTitle,
                  message: l10n.reportsNoNewLoansTodayMessage,
                )
              : Column(
                  children: newLoans
                      .map(
                        (l) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.customerName),
                          subtitle: Text(l.loanNumber),
                          trailing: Text(
                            formatIndianCurrency(l.loanAmount),
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
  const _MonthlyReportSection({required this.report});
  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = report.summary;

    return Column(
      children: [
        _MetricRow(
          label: l10n.reportsMetricDisbursement,
          value: formatIndianCurrency(s.disbursement),
          icon: Icons.account_balance_wallet_outlined,
          iconBg: const Color(0xFFDCEAFE),
          iconColor: AppColors.kInfo,
        ),
        const SizedBox(height: 12),
        _MetricRow(
          label: l10n.reportsMetricInterest,
          value: formatIndianCurrency(s.interest),
          icon: Icons.trending_up_rounded,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: AppColors.kSuccess,
        ),
        const SizedBox(height: 12),
        _MetricRow(
          label: l10n.reportsMetricCollectionTotal,
          value: formatIndianCurrency(s.collected),
          icon: Icons.currency_rupee_rounded,
          iconBg: const Color(0xFFEDE9FE),
          iconColor: const Color(0xFF7C3AED),
        ),
        const SizedBox(height: 12),
        _MetricRow(
          label: l10n.reportsMetricNewCustomers,
          value: '${s.newCustomers}',
          icon: Icons.people_alt_outlined,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: AppColors.kWarning,
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: l10n.reportsCollectionsTrendTitle,
          subtitle: l10n.reportsLastNMonths(report.collectionTrend.length),
          child: _SimpleLineChart(points: report.collectionTrend),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: l10n.reportsLoanDisbursementTitle,
          subtitle: l10n.reportsByMonth,
          child: _SimpleBarChart(
              points: report.disbursementTrend, valueFormatter: formatCompact),
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

class _AgentPerformanceSection extends StatelessWidget {
  const _AgentPerformanceSection({required this.report});
  final AgentReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final agents = report.agents;

    return Column(
      children: [
        _SectionCard(
          icon: Icons.people_alt_outlined,
          iconColor: AppColors.kInfo,
          title: l10n.reportsAgentPerformanceTitle,
          count: agents.length,
          child: agents.isEmpty
              ? _EmptyMini(
                  icon: Icons.people_alt_outlined,
                  title: l10n.reportsNoAgentDataTitle,
                  message: l10n.reportsNoAgentDataMessage,
                )
              : SingleChildScrollView(
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
                    dataTextStyle: const TextStyle(
                        fontSize: 14, color: AppColors.kTextDark),
                    columns: [
                      DataColumn(label: Text(l10n.reportsColumnAgent)),
                      DataColumn(label: Text(l10n.reportsColumnAssigned)),
                      DataColumn(label: Text(l10n.reportsColumnCollected)),
                      DataColumn(label: Text(l10n.reportsColumnEfficiency)),
                    ],
                    rows: agents
                        .map(
                          (a) => DataRow(
                            cells: [
                              DataCell(Text(a.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                              DataCell(Text('${a.assigned}')),
                              DataCell(Text(
                                  '${a.collCount} / ${formatIndianCurrency(a.collSum)}')),
                              DataCell(Text('${a.efficiency}%')),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: l10n.reportsCollectionsByAgentTitle,
          subtitle: l10n.reportsTotalAmountCollected,
          child: _SimpleBarChart(
              points: report.chart, valueFormatter: formatCompact),
        ),
      ],
    );
  }
}

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

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({required this.points});
  final List<MonthPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
          child: Text(l10n.reportsNoData,
              style: const TextStyle(color: AppColors.kTextMuted)));
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
          AppColors.kInfo.withValues(alpha: 0.25),
          AppColors.kInfo.withValues(alpha: 0.0)
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
    textDirection: ui.TextDirection.ltr,
  )..layout();
  
  final x = (stepX * i - tp.width / 2).clamp(0.0, size.width - tp.width);
  tp.paint(canvas, Offset(x.toDouble(), chartHeight + 4));
}
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart({required this.points, required this.valueFormatter});
  final List<MonthPoint> points;
  final String Function(num) valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
          child: Text(l10n.reportsNoData,
              style: const TextStyle(color: AppColors.kTextMuted)));
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