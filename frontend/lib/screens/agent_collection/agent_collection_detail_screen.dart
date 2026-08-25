import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../models/agent_collection.dart';
import '../../services/agent_collection_api_service.dart';
import '../../utils/location_launcher.dart';
import '../../widgets/collect_payment_sheet.dart';
import '../../widgets/app_shell.dart';
import '../../routes/app_routes.dart';

const Color _kGold = Color(0xFFA9791F);

/// Shows every separate due loan/installment for a single customer.
class AgentCollectionDetailScreen extends StatefulWidget {
  final AgentCustomerGroup group;
  final Future<void> Function() onReload;

  const AgentCollectionDetailScreen({
    super.key,
    required this.group,
    required this.onReload,
  });

  @override
  State<AgentCollectionDetailScreen> createState() =>
      _AgentCollectionDetailScreenState();
}

class _AgentCollectionDetailScreenState
    extends State<AgentCollectionDetailScreen> {
  late List<AgentCollectionItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.group.items];
  }

  double get _totalDue =>
      _items.fold(0.0, (sum, i) => sum + i.dueAmount + i.penaltyAmount);

  void _showCollectSheet(AgentCollectionItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => CollectPaymentSheet(
        customerName: widget.group.customerName,
        subtitleLabel: 'Loan',
        subtitleValue: item.loanNumber,
        prefillAmount: item.dueAmount + item.penaltyAmount,
        installmentAmount: item.installmentAmount,
        dueAmount: item.dueAmount,
        penaltyAmount: item.penaltyAmount,
        outstandingBalance: item.outstandingBalance,
        dueCount: 1,
        onSubmit: (amount, method, date, notes) =>
            _collectItem(item, amount, method, date, notes),
      ),
    );
  }

  Future<void> _collectItem(AgentCollectionItem item, double amount,
      String method, DateTime date, String? notes) async {
    try {
      final payableAmount = item.dueAmount + item.penaltyAmount;
      final fullyCovered = amount >= (payableAmount - 0.01);
      await AgentCollectionApiService.collectPayment(
        item: item,
        amount: amount,
        paymentMethod: method,
        collectionDate: date,
        notes: notes,
        markPaid: fullyCovered,
      );
      if (!mounted) return;
      ToastService.show(
        title: 'Collection recorded',
        message: '${item.loanNumber} • ${item.formattedDueAmount}',
        type: ToastType.success,
      );
      setState(() {
        if (fullyCovered) {
          _items.removeWhere((i) => i.id == item.id);
        } else {
          final idx = _items.indexWhere((i) => i.id == item.id);
          if (idx != -1) {
            final remaining = payableAmount - amount;
            _items[idx] = AgentCollectionItem(
              id: item.id,
              scheduleId: item.scheduleId,
              loanId: item.loanId,
              loanType: item.loanType,
              loanName: item.loanName,
              customerId: item.customerId,
              customerName: item.customerName,
              loanNumber: item.loanNumber,
              dueAmount: remaining < 0 ? 0 : remaining,
              installmentAmount: item.installmentAmount,
              penaltyAmount: item.penaltyAmount,
              dueDate: item.dueDate,
              rawStatus: item.rawStatus,
              contactPhone: item.contactPhone,
              agentId: item.agentId,
              agentName: item.agentName,
              address: item.address,
              latitude: item.latitude,
              longitude: item.longitude,
              outstandingBalance: item.outstandingBalance,
            );
          }
        }
      });
      // Keep the assigned-collections list in sync in the background.
      unawaited(widget.onReload());
    } catch (e) {
      ToastService.show(
        title: 'Failed to record collection',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.collections,
      title: widget.group.customerName,
      showBackButton: true,
      onBack: () => Navigator.of(context).pop(),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text('All dues settled for this customer',
                        style: TextStyle(color: AppColors.kTextMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _LoanRow(
                      item: _items[index],
                      onCollect: () => _showCollectSheet(_items[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final group = widget.group;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer ID: ${group.customerId}',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Total Outstanding',
                  value:
                      AgentCollectionItem.formatAmount(group.totalOutstanding),
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Due Now',
                  value: AgentCollectionItem.formatAmount(_totalDue),
                  highlight: true,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Penalty',
                  value: AgentCollectionItem.formatAmount(
                      _items.fold(0.0, (sum, item) => sum + item.penaltyAmount)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 16, color: AppColors.kTextMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  group.contactPhone?.isNotEmpty == true
                      ? group.contactPhone!
                      : 'Contact on file',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.kTextMuted),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => openCustomerLocation(context, group),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kTextDark,
                  side: const BorderSide(color: AppColors.kBorder),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.location_on_outlined, size: 16),
                label: const Text('Visit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _SummaryStat(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: highlight ? _kGold : AppColors.kTextDark,
          ),
        ),
      ],
    );
  }
}

class _LoanRow extends StatelessWidget {
  final AgentCollectionItem item;
  final VoidCallback onCollect;
  const _LoanRow({required this.item, required this.onCollect});

  Color get _statusColor {
    switch (item.status) {
      case AgentCollectionStatus.overdue:
        return AppColors.kDanger;
      case AgentCollectionStatus.dueToday:
        return AppColors.kWarning;
      default:
        return AppColors.kSuccess;
    }
  }

  Color get _statusBg {
    switch (item.status) {
      case AgentCollectionStatus.overdue:
        return const Color(0xFFFDEBEC);
      case AgentCollectionStatus.dueToday:
        return const Color(0xFFFFF3DC);
      default:
        return const Color(0xFFE7F7EE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(item.loanNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextDark)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.statusLabel,
                  style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Due Amount: ${item.formattedDueAmount}',
                    style: const TextStyle(
                        color: AppColors.kDanger, fontSize: 13)),
              ),
              if (item.penaltyAmount > 0)
                Expanded(
                  child: Text('Penalty: ${item.formattedPenaltyAmount}',
                      style: const TextStyle(
                          color: AppColors.kDanger, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Due date: ${item.formattedDueDate} • Total due: ${item.formattedTotalDue}',
              style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCollect,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.currency_rupee, size: 16),
              label: const Text('Collect'),
            ),
          ),
        ],
      ),
    );
  }
}

// Small helper so we don't need to import dart:async just for this.
void unawaited(Future<void> future) {}
