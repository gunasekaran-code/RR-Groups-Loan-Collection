import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/glass_toast.dart';
import '../../models/agent_collection.dart';
import '../../services/agent_collection_api_service.dart';
import '../../utils/location_launcher.dart';
import '../../screens/agent_collection/agent_collection_detail_screen.dart';
import '../../widgets/collect_payment_sheet.dart';

const Color _kGold = Color(0xFFA9791F);
const Color _kGoldTint = Color(0xFFFBF3E1);

class AgentCollectionScreen extends StatefulWidget {
  const AgentCollectionScreen({super.key});

  @override
  State<AgentCollectionScreen> createState() => _AgentCollectionScreenState();
}

class _AgentCollectionScreenState extends State<AgentCollectionScreen> {
  bool _isLoading = true;
  String? _loadError;
  List<AgentCustomerGroup> _groups = [];
  String _query = '';

  int _collectedToday = 0;

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
      final groups =
          await AgentCollectionApiService.fetchAssignedCollectionGroups();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
      ToastService.show(
        title: 'Failed to load collections',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  List<AgentCustomerGroup> get _filteredGroups =>
      _groups.where((g) => g.matchesQuery(_query)).toList();

  double get _totalDue =>
      _groups.fold(0.0, (sum, g) => sum + g.totalDueWithPenalty);

  void _openDetail(AgentCustomerGroup group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgentCollectionDetailScreen(
          group: group,
          onReload: _load,
        ),
      ),
    );
    // The detail screen keeps its own local state but the underlying data
    // may have changed (payments recorded), so refresh the list on return.
    _load();
  }

  void _showCollectSheet(AgentCustomerGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => CollectPaymentSheet(
        customerName: group.customerName,
        subtitleLabel: 'Loan Type',
        subtitleValue: group.displayLoanType,
        prefillAmount: group.totalDueWithPenalty,
        installmentAmount: group.items.length == 1
          ? group.items.first.installmentAmount
          : null,
        dueAmount: group.totalDue,
        penaltyAmount: group.totalPenalty,
        outstandingBalance: group.totalOutstanding,
        dueCount: group.items.length,
        onSubmit: (amount, method, date, notes) =>
            _collectForGroup(group, amount, method, date, notes),
      ),
    );
  }

  Future<void> _collectForGroup(AgentCustomerGroup group, double amount,
      String method, DateTime date, String? notes) async {
    try {
      final createdCount = await AgentCollectionApiService.collectForCustomer(
        group: group,
        amount: amount,
        paymentMethod: method,
        collectionDate: date,
        notes: notes,
      );
      if (!mounted) return;
      final now = DateTime.now();
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      setState(() {
        if (isToday) _collectedToday++;
      });
      final summary = createdCount == 1
          ? '1 installment recorded'
          : '$createdCount installments recorded';
      ToastService.show(
        title: 'Collection saved',
        message: '${group.uniqueName} • $summary',
        type: ToastType.success,
      );
      await _load();
    } catch (e) {
      ToastService.show(
        title: 'Collection failed',
        message: '${group.uniqueName}: $e',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppShell(
      currentRoute: AppRoutes.collections,
      title: 'Collections',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load collections',
                          style: TextStyle(color: scheme.error)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_loadError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _buildList(),
                ),
    );
  }

  Widget _buildList() {
    final filtered = _filteredGroups;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filtered.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader();
        final group = filtered[index - 1];
        return _CustomerGroupCard(
          group: group,
          onTap: () => _openDetail(group),
          onCollect: () => _showCollectSheet(group),
          onVisit: () => openCustomerLocation(context, group),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collections',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.kTextDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_groups.length} customers assigned • $_collectedToday collected today',
            style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 16),
          _buildTotalDueBanner(),
          const SizedBox(height: 16),
          _buildSearchBar(),
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_filteredGroups.length} result(s) for "$_query"',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
              ),
            ),
          if (_filteredGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Text(
                  _query.isEmpty
                      ? 'No collections assigned'
                      : 'No customers match "$_query"',
                  style: const TextStyle(color: AppColors.kTextMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalDueBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kGold,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Collection Due',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Text(
            AgentCollectionItem.formatAmount(_totalDue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        hintText: 'Search by name or Loan ID',
        prefixIcon: const Icon(Icons.search, color: AppColors.kTextMuted),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                onPressed: () => setState(() => _query = ''),
              )
            : null,
        filled: true,
        fillColor: AppColors.kBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
      ),
    );
  }
}

class _CustomerGroupCard extends StatelessWidget {
  final AgentCustomerGroup group;
  final VoidCallback onTap;
  final VoidCallback onCollect;
  final VoidCallback onVisit;

  const _CustomerGroupCard({
    required this.group,
    required this.onTap,
    required this.onCollect,
    required this.onVisit,
  });

  Color get _statusColor {
    switch (group.status) {
      case AgentCollectionStatus.overdue:
        return AppColors.kDanger;
      case AgentCollectionStatus.dueToday:
        return AppColors.kWarning;
      default:
        return AppColors.kSuccess;
    }
  }

  Color get _statusBg {
    switch (group.status) {
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kGoldTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    group.initials,
                    style: const TextStyle(
                        color: _kGold, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.kTextDark)),
                      const SizedBox(height: 2),
                      Text(group.uniqueName,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.kTextMuted)),
                      Text('Loan ID: ${group.loanId}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.kTextMuted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    group.statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InfoBox(
                      label: 'Total Outstanding',
                      value: AgentCollectionItem.formatAmount(
                          group.totalOutstanding)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoBox(
                      label: 'Due Now',
                      value: AgentCollectionItem.formatAmount(group.totalDueWithPenalty)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Due Amount: ${AgentCollectionItem.formatAmount(group.totalDue)}',
                    style: const TextStyle(
                        color: AppColors.kDanger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (group.totalPenalty > 0)
                  Expanded(
                    child: Text(
                      'Penalty: ${AgentCollectionItem.formatAmount(group.totalPenalty)}',
                      style: const TextStyle(
                          color: AppColors.kDanger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 16, color: AppColors.kTextMuted),
                const SizedBox(width: 6),
                Text(
                  'Due ${AgentCollectionItem.formatDate(group.nearestDueDate)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.kTextMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.category_outlined,
                    size: 16, color: AppColors.kTextMuted),
                const SizedBox(width: 6),
                Text(
                  'Loan Type: ${group.displayLoanType} • ${group.displayLoanName}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.kTextMuted),
                ),
              ],
            ),
            if (group.address != null && group.address!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.kTextMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      group.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.kTextMuted),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onCollect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.currency_rupee, size: 16),
                    label: const Text('Collect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onVisit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextDark,
                      side: const BorderSide(color: AppColors.kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.location_on_outlined, size: 16),
                    label: const Text('Visit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.kBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextDark)),
        ],
      ),
    );
  }
}
