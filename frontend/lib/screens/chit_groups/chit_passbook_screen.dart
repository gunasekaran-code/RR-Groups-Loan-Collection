import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/chit_group.dart';
import '../../models/chit_member.dart';
import '../../models/chit_passbook.dart';
import '../../services/chit_group_api_service.dart';
import '../../widgets/app_shell.dart';
import '../../routes/app_routes.dart';

String _fmtCurrency(double? amount) {
  if (amount == null) return '₹0';
  final format =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  return format.format(amount);
}

String _fmtDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('dd MMM yyyy').format(date);
}

// Narrow-screen breakpoint: below this we stack cards instead of a table
// and wrap the header stats instead of a fixed 4-column row.
const double _kMobileBreakpoint = 640;

class ChitPassbookScreen extends StatefulWidget {
  const ChitPassbookScreen({
    super.key,
    required this.group,
    required this.member,
  });

  final ChitGroup group;
  final ChitMember member;

  @override
  State<ChitPassbookScreen> createState() => _ChitPassbookScreenState();
}

class _ChitPassbookScreenState extends State<ChitPassbookScreen> {
  bool _isLoading = true;
  String? _loadError;
  ChitPassbookData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await ChitGroupApiService.fetchPassbook(widget.member.id);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Replaced standard Scaffold with AppShell
    return AppShell(
      currentRoute: AppRoutes.customers, // Keeps the relevant nav icon highlighted
      title: 'Chit Passbook',
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? _buildError()
                  : _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Text(_loadError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.kDanger)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final data = _data!;
    final isMobile = MediaQuery.of(context).size.width < _kMobileBreakpoint;

    return LayoutBuilder(builder: (context, constraints) {
      final mobile = constraints.maxWidth < _kMobileBreakpoint || isMobile;
      return ListView(
        padding: EdgeInsets.all(mobile ? 12 : 20),
        children: [
          _PassbookHeaderCard(
            group: widget.group,
            member: widget.member,
            data: data,
            mobile: mobile,
          ),
          const SizedBox(height: 20),
          _SectionTitleRow(
            title: 'Installment Draw Schedule & Payment Passbook',
            trailing: 'Total Draws: ${data.totalDraws ?? data.draws.length}',
          ),
          const SizedBox(height: 12),
          if (data.nextDueDraw != null)
            _NextPaymentBanner(draw: data.nextDueDraw!, mobile: mobile),
          const SizedBox(height: 16),
          if (data.draws.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No draw schedule available yet.',
                    style: TextStyle(color: AppColors.kTextMuted)),
              ),
            )
          else if (mobile)
            _DrawCardList(draws: data.draws)
          else
            _DrawTable(draws: data.draws),
          const SizedBox(height: 28),
          Text('Recorded Payment Receipts (${data.receipts.length})',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.kTextDark)),
          const SizedBox(height: 12),
          if (data.receipts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No payment receipts recorded yet.',
                    style: TextStyle(color: AppColors.kTextMuted)),
              ),
            )
          else
            ...data.receipts.map((r) => _ReceiptCard(receipt: r)),
          const SizedBox(height: 24),
        ],
      );
    });
  }
}

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({required this.title, required this.trailing});
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.kTextDark)),
        Text(trailing,
            style:
                const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
      ],
    );
  }
}

/// ----------------------------------------------------------------------
/// HEADER — purple/indigo gradient card
/// ----------------------------------------------------------------------
class _PassbookHeaderCard extends StatelessWidget {
  const _PassbookHeaderCard({
    required this.group,
    required this.member,
    required this.data,
    required this.mobile,
  });

  final ChitGroup group;
  final ChitMember member;
  final ChitPassbookData data;
  final bool mobile;

  static const _gradientStart = Color(0xFF1E1B4B);
  static const _gradientEnd = Color(0xFF4C1D95);
  static const _gold = Color(0xFFFACC15);

  Color get _statusFg {
    switch (member.status) {
      case ChitPaymentStatus.paid:
        return const Color(0xFF34D399);
      case ChitPaymentStatus.partial:
        return const Color(0xFF60A5FA);
      case ChitPaymentStatus.overdue:
        return const Color(0xFFF87171);
      case ChitPaymentStatus.pending:
        return const Color(0xFFFBBF24);
    }
  }

  Color get _statusBg => _statusFg.withOpacity(0.18);

  String get _statusLabel {
    final s = member.status.name;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      _HeaderStat('Base Contribution', _fmtCurrency(member.contributionAmount)),
      _HeaderStat('Max Scheme Value', _fmtCurrency(group.groupValue)),
      _HeaderStat('Draw Schedule', data.drawScheduleLabel, gold: true),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.menu_book_rounded, color: _gold, size: 18),
              SizedBox(width: 8),
              Text(
                'OFFICIAL CHIT PASSBOOK',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            group.name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: mobile ? 22 : 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Group No: ${group.code} | Account Holder: ${member.memberName}',
            style: const TextStyle(color: Color(0xFFC7C6E8), fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 28,
            runSpacing: 16,
            children: [
              ...stats,
              _HeaderStatusStat(
                label: 'Current Status',
                value: _statusLabel,
                fg: _statusFg,
                bg: _statusBg,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat(this.label, this.value, {this.gold = false});
  final String label;
  final String value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Color(0xFFC7C6E8), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: gold ? const Color(0xFFFACC15) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatusStat extends StatelessWidget {
  const _HeaderStatusStat({
    required this.label,
    required this.value,
    required this.fg,
    required this.bg,
  });

  final String label;
  final String value;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Color(0xFFC7C6E8), fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// NEXT PAYMENT DUE banner
/// ----------------------------------------------------------------------
class _NextPaymentBanner extends StatelessWidget {
  const _NextPaymentBanner({required this.draw, required this.mobile});
  final ChitDraw draw;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFB45309);
    final content = [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8B8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: amber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NEXT PAYMENT DUE',
                    style: TextStyle(
                        color: amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  'Draw #${draw.drawNumber} · ${_fmtDate(draw.scheduledDate)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.kTextDark),
                ),
                if (draw.amountPaid > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtCurrency(draw.amountPaid)} already paid against this draw',
                    style: const TextStyle(
                        color: AppColors.kTextMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      Column(
        crossAxisAlignment:
            mobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          const Text('Amount to pay',
              style: TextStyle(color: AppColors.kTextMuted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(_fmtCurrency(draw.amountDue),
              style: const TextStyle(
                  color: amber, fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCE3A6)),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content[0],
                const SizedBox(height: 12),
                content[1],
              ],
            )
          : Row(
              children: [
                Expanded(child: content[0]),
                content[1],
              ],
            ),
    );
  }
}

/// ----------------------------------------------------------------------
/// DRAW SCHEDULE — table on wide screens
/// ----------------------------------------------------------------------
class _DrawTable extends StatelessWidget {
  const _DrawTable({required this.draws});
  final List<ChitDraw> draws;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        // tightFor, not minWidth alone: a minWidth-only BoxConstraints
        // leaves maxWidth at infinity, which the header/data Rows below
        // (Expanded cells) can't lay out against — "RenderFlex children
        // have non-zero flex but incoming width constraints are
        // unbounded", and the table silently fails to paint.
        constraints: const BoxConstraints.tightFor(width: 640),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.kBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F5F1),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Row(
                  children: [
                    _HCell('DRAW #', flex: 1),
                    _HCell('SCHEDULED DATE', flex: 2),
                    _HCell('PAYABLE CONTRIBUTION', flex: 2),
                    _HCell('DIVIDEND POOL VALUE', flex: 2),
                    _HCell('PAYMENT STATUS', flex: 2),
                  ],
                ),
              ),
              ...draws.map((d) => _DrawRow(draw: d)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  const _HCell(this.label, {required this.flex});
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.kTextMuted)),
    );
  }
}

class _DrawRow extends StatelessWidget {
  const _DrawRow({required this.draw});
  final ChitDraw draw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text('#${draw.drawNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(_fmtDate(draw.scheduledDate))),
          Expanded(
            flex: 2,
            child: Text(_fmtCurrency(draw.payableContribution),
                style: const TextStyle(
                    color: AppColors.kSuccess, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(_fmtCurrency(draw.dividendPoolValue),
                style: const TextStyle(
                    color: Color(0xFF4C1D95), fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(status: draw.status),
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// DRAW SCHEDULE — stacked cards on narrow/mobile screens
/// ----------------------------------------------------------------------
class _DrawCardList extends StatelessWidget {
  const _DrawCardList({required this.draws});
  final List<ChitDraw> draws;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: draws.map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.kBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Draw #${d.drawNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  _StatusPill(status: d.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(_fmtDate(d.scheduledDate),
                  style: const TextStyle(
                      color: AppColors.kTextMuted, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Payable',
                      value: _fmtCurrency(d.payableContribution),
                      color: AppColors.kSuccess,
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Dividend Pool',
                      value: _fmtCurrency(d.dividendPoolValue),
                      color: const Color(0xFF4C1D95),
                    ),
                  ),
                ],
              ),
              if (!d.isSettled && d.amountPaid > 0) ...[
                const SizedBox(height: 10),
                _MiniStat(
                  label: 'Balance due',
                  value: _fmtCurrency(d.balance),
                  color: AppColors.kDanger,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.kTextMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Colors and labels for the four statuses the backend passbook stores —
/// kept in step with the pill on the header card and the status column on
/// the group's member table so the same draw reads the same way everywhere.
String chitDrawStatusLabel(ChitDrawStatus status) {
  switch (status) {
    case ChitDrawStatus.paid:
      return 'Paid';
    case ChitDrawStatus.partial:
      return 'Partial';
    case ChitDrawStatus.overdue:
      return 'Overdue';
    case ChitDrawStatus.pending:
      return 'Pending';
  }
}

Color chitDrawStatusColor(ChitDrawStatus status) {
  switch (status) {
    case ChitDrawStatus.paid:
      return AppColors.kSuccess;
    case ChitDrawStatus.partial:
      return const Color(0xFF2563EB);
    case ChitDrawStatus.overdue:
      return AppColors.kDanger;
    case ChitDrawStatus.pending:
      return const Color(0xFFD97706);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final ChitDrawStatus status;

  @override
  Widget build(BuildContext context) {
    final fg = chitDrawStatusColor(status);
    final bg = fg.withOpacity(0.15);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(chitDrawStatusLabel(status),
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// ----------------------------------------------------------------------
/// RECORDED PAYMENT RECEIPTS
/// ----------------------------------------------------------------------
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt});
  final ChitPaymentReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.kBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.kSuccess.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.kSuccess, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(receipt.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextDark)),
                if (receipt.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(receipt.subtitle,
                      style: const TextStyle(
                          color: AppColors.kTextMuted, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmtCurrency(receipt.amount),
                  style: const TextStyle(
                      color: AppColors.kSuccess, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(_fmtDate(receipt.date),
                  style: const TextStyle(
                      color: AppColors.kTextMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}