import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/status_badge.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';

class RepaymentScheduleScreen extends StatefulWidget {
  const RepaymentScheduleScreen({super.key});

  @override
  State<RepaymentScheduleScreen> createState() =>
      _RepaymentScheduleScreenState();
}

class _RepaymentScheduleScreenState extends State<RepaymentScheduleScreen> {
  String _selectedLoan = 'LN-232037';

  // Dummy data matching the screenshot
  static const List<Map<String, String>> _installments = [
    {
      'inst': '#1',
      'due': '31 Jul 2026',
      'amount': '₹9,383',
      'paid': '₹0',
      'balance': '₹9,383',
      'status': 'Pending'
    },
    {
      'inst': '#2',
      'due': '31 Aug 2026',
      'amount': '₹9,383',
      'paid': '₹0',
      'balance': '₹9,383',
      'status': 'Pending'
    },
    {
      'inst': '#3',
      'due': '30 Sep 2026',
      'amount': '₹9,383',
      'paid': '₹0',
      'balance': '₹9,383',
      'status': 'Pending'
    },
    {
      'inst': '#4',
      'due': '31 Oct 2026',
      'amount': '₹9,383',
      'paid': '₹0',
      'balance': '₹9,383',
      'status': 'Pending'
    },
    {
      'inst': '#5',
      'due': '30 Nov 2026',
      'amount': '₹9,383',
      'paid': '₹0',
      'balance': '₹9,383',
      'status': 'Pending'
    },
    {
      'inst': '#6',
      'due': '31 Dec 2026',
      'amount': '₹9,383',
      'paid': '₹0',
      'balance': '₹9,383',
      'status': 'Pending'
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        return AppShell(
          currentRoute: AppRoutes.repayment,
          title: 'Repayment Schedule',
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isNarrow),
                const SizedBox(height: 24),
                _buildLoanSelector(),
                const SizedBox(height: 20),
                _buildSummaryGrid(isNarrow),
                const SizedBox(height: 24),
                _buildSectionLabel('INSTALLMENT BREAKDOWN'),
                const SizedBox(height: 12),
                _buildInstallmentsTable(isNarrow),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // Header
  Widget _buildHeader(BuildContext context, bool isNarrow) {
    final subtitle = const Text(
      'Track installment-wise EMI collections and outstanding balances',
      style: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
    );

    final downloadButton = Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 200,
        child: ElevatedButton.icon(
          onPressed: () {
            ToastService.show(
              title: 'Download started',
              message: 'Schedule for $_selectedLoan',
              type: ToastType.info,
            );
          },
          icon: const Icon(Icons.download_outlined, size: 20),
          label: const Text('Download Schedule'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          subtitle,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: downloadButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: subtitle),
        downloadButton,
      ],
    );
  }

  // Loan selector card
  Widget _buildLoanSelector() {
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
          const Text(
            'SELECT LOAN',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.kTextMuted,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedLoan,
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
            ),
            items: const [
              DropdownMenuItem(
                  value: 'LN-232037', child: Text('LN-232037 — Lakshmi Iyer')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedLoan = val);
                ToastService.show(
                  title: 'Loan switched',
                  message: val,
                  type: ToastType.info,
                );
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

  // Summary cards grid — responsive: 2 columns narrow, 4 columns wide
  Widget _buildSummaryGrid(bool isNarrow) {
    final cards = <Widget>[
      _buildStatCard('LOAN NUMBER', 'LN-232037', icon: Icons.badge_outlined),
      _buildStatCard('CUSTOMER', 'Lakshmi Iyer', icon: Icons.person_outline),
      _buildStatCard('LOAN AMOUNT', '₹50,000',
          icon: Icons.account_balance_wallet_outlined),
      _buildStatCard('EMI', '₹9,383', icon: Icons.calendar_month_outlined),
      _buildStatCard('TOTAL REPAYMENT', '₹56,300',
          icon: Icons.summarize_outlined),
      _buildStatCard('OUTSTANDING', '₹52,500',
          icon: Icons.warning_amber_outlined, textColor: AppColors.kDanger),
      _buildStatCard('TOTAL INST.', '6', icon: Icons.format_list_numbered),
      _buildStatCard('PAID', '0',
          icon: Icons.check_circle_outline,
          textColor: AppColors.kSuccess,
          borderColor: AppColors.kSuccess.withOpacity(0.3),
          bgColor: AppColors.kSuccess.withOpacity(0.05)),
      _buildStatCard('PENDING', '6',
          icon: Icons.hourglass_empty,
          textColor: AppColors.kWarning,
          borderColor: AppColors.kWarning.withOpacity(0.3),
          bgColor: AppColors.kWarning.withOpacity(0.05)),
      _buildStatCard('OVERDUE', '0',
          icon: Icons.error_outline,
          textColor: AppColors.kDanger,
          borderColor: AppColors.kDanger.withOpacity(0.3),
          bgColor: AppColors.kDanger.withOpacity(0.05)),
      _buildStatCard('NEXT DUE', '31 Jul 2026',
          icon: Icons.event_outlined,
          textColor: AppColors.kInfo,
          borderColor: AppColors.kInfo.withOpacity(0.3),
          bgColor: AppColors.kInfo.withOpacity(0.05)),
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

  // Installments table — same visual pattern as the Loans table:
  // Card wrapper, scrollbar with visible thumb, min-width for horizontal
  // scroll on small screens, and StatusBadge for the status column.
  Widget _buildInstallmentsTable(bool isNarrow) {
    final table = DataTable(
      headingTextStyle: const TextStyle(
        color: AppColors.kTextMuted,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      dataTextStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.kTextDark,
      ),
      dividerThickness: 0,
      columns: const [
        DataColumn(label: Text('INST. NO')),
        DataColumn(label: Text('DUE DATE')),
        DataColumn(label: Text('EMI AMOUNT')),
        DataColumn(label: Text('PAID')),
        DataColumn(label: Text('BALANCE')),
        DataColumn(label: Text('STATUS')),
      ],
      rows: _installments.map((inst) {
        return DataRow(cells: [
          DataCell(Text(inst['inst']!,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(inst['due']!)),
          DataCell(Text(inst['amount']!)),
          DataCell(Text(inst['paid']!)),
          DataCell(Text(inst['balance']!,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(StatusBadge(
              label: inst['status']!, tone: _toneFor(inst['status']!))),
        ]);
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
          // Always show the horizontal scrollbar/thumb so users on mobile
          // get a clear visual affordance that the table can be swiped.
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              // Force a sensible minimum width so the table always has
              // something wider than the viewport to scroll on small
              // screens, instead of silently shrinking to fit.
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
