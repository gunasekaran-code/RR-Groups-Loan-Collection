import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../theme/confirm_dialog.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/page_header.dart';
import '../../models/chit_group.dart';
import '../../models/chit_member.dart';
import '../../models/user_role.dart';
import '../../services/chit_group_api_service.dart';
import '../../services/collection_api_service.dart';
import '../../services/session_service.dart';
import 'chit_passbook_screen.dart';
import 'package:intl/intl.dart';
import '../../models/chit_schedule.dart';
import '../../l10n/generated/app_localizations.dart';

class _OverrideScheduleSheet extends StatefulWidget {
  const _OverrideScheduleSheet({required this.schedule});

  final ChitSchedule schedule;

  @override
  State<_OverrideScheduleSheet> createState() => _OverrideScheduleSheetState();
}

class _OverrideScheduleSheetState extends State<_OverrideScheduleSheet> {
  late DateTime _dueDate;
  late final TextEditingController _payableController;
  late final TextEditingController _poolController;
  late final TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.schedule.dueDate;
    _payableController = TextEditingController(
        text: widget.schedule.payableAmount.toStringAsFixed(0));
    _poolController = TextEditingController(
        text: widget.schedule.poolAmount.toStringAsFixed(0));
    _notesController =
        TextEditingController(text: widget.schedule.overrideNotes ?? '');
  }

  @override
  void dispose() {
    _payableController.dispose();
    _poolController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final payable = double.tryParse(_payableController.text.trim());
    final pool = double.tryParse(_poolController.text.trim());
    if (payable == null || payable < 0 || pool == null || pool < 0) {
      final l10n = AppLocalizations.of(context);
      ToastService.show(
        title: l10n.invalidScheduleValuesTitle,
        message: l10n.invalidScheduleValuesMessage,
        type: ToastType.error,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await ChitGroupApiService.overrideSchedule(
        scheduleId: widget.schedule.id,
        dueDate: _dueDate,
        payableAmount: payable,
        poolAmount: pool,
        notes: _notesController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ToastService.show(
          title: AppLocalizations.of(context).scheduleUpdateFailedTitle,
          message: e.toString(),
          type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // This padding ensures the bottom sheet moves up with the keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      // FIX: Added a solid white background so the content underneath doesn't show through
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)), // Rounds the top corners
      ),
      child: Padding(
        // Apply the keyboard inset dynamically
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          // Makes the content scrollable
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.overrideDrawTitle(widget.schedule.installmentNo),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.kTextDark,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                      ),
                      icon: const Icon(Icons.close,
                          size: 20, color: AppColors.kTextDark),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _overrideField(l10n.payableAmountLabel, _payableController),
                const SizedBox(height: 16),
                _overrideField(
                    l10n.poolDividendValueLabel, _poolController),
                const SizedBox(height: 16),
                Text(l10n.dueDateLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.kTextMuted)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      suffixIcon: const Icon(Icons.calendar_today_outlined,
                          color: AppColors.kTextMuted, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Text(
                      formatDate(_dueDate),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.kTextDark),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _overrideField(l10n.notesLabel, _notesController,
                    maxLines: 2),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _saving ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Text(l10n.cancelButton,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kGold,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_outlined, size: 20),
                        label: Text(
                          _saving ? l10n.savingButton : l10n.saveOverrideButton,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Upgraded custom field method with modern styling
  Widget _overrideField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: maxLines == 1
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.kTextDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kGold, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _SchemePreset {
  const _SchemePreset({
    required this.chipLabel,
    required this.groupName,
    required this.totalMembers,
    required this.durationMonths,
    required this.groupValue,
    required this.monthlyContribution,
    required this.drawFrequencyLabel,
    required this.drawInterval,
    required this.color,
  });

  final String chipLabel;
  final String groupName;
  final int totalMembers;
  final int durationMonths;
  final double groupValue;
  final double monthlyContribution;
  final String drawFrequencyLabel;
  final int drawInterval;
  final Color color;
}

const _schemePresets = <_SchemePreset>[
  _SchemePreset(
    chipLabel: 'Load ₹750 5-Day Scheme',
    groupName: '₹750 5-Day Chit Scheme',
    totalMembers: 30,
    durationMonths: 30,
    groupValue: 28500,
    monthlyContribution: 750,
    drawFrequencyLabel: 'Custom Day Interval',
    drawInterval: 5,
    color: Color(0xFF7C3AED),
  ),
  _SchemePreset(
    chipLabel: 'Load ₹1,420 10-Day Scheme',
    groupName: '₹1,420 10-Day Chit Scheme',
    totalMembers: 30,
    durationMonths: 30,
    groupValue: 57000,
    monthlyContribution: 1420,
    drawFrequencyLabel: 'Every 10 Days',
    drawInterval: 10,
    color: Color(0xFF16A34A),
  ),
  _SchemePreset(
    chipLabel: 'Load ₹5,000 21-Month Scheme',
    groupName: '₹5,000 21-Month Fixed/Variable Scheme',
    totalMembers: 20,
    durationMonths: 21,
    groupValue: 125000,
    monthlyContribution: 5000,
    drawFrequencyLabel: '1 Draw / Month (Monthly)',
    drawInterval: 1,
    color: Color(0xFFCA8A04),
  ),
];

// Draw frequency options for the create/edit group form. Each maps to a
// day-gap between consecutive draw dates (null = calendar-month stepping,
// or "N/A" = dates are picked individually, no auto interval).
const _drawFrequencyOptions = <String>[
  '1 Draw / Month (Monthly)',
  '2 Draws / Month (Bi-Monthly)',
  '3 Draws / Month (Tri-Monthly)',
  'Every 10 Days',
  'Custom Day Interval',
  'Custom Calendar Days',
];

/// Fixed day-gap implied by a draw frequency, or null when the gap is either
/// calendar-month based (Monthly) or user-defined (Custom Day Interval /
/// Custom Calendar Days).
int? _fixedIntervalDaysFor(String frequency) {
  switch (frequency) {
    case '2 Draws / Month (Bi-Monthly)':
      return 15;
    case '3 Draws / Month (Tri-Monthly)':
      return 10;
    case 'Every 10 Days':
      return 10;
    default:
      return null;
  }
}

String formatIndianCurrency(double? amount) {
  if (amount == null) return '₹0';
  final format =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  return format.format(amount);
}

String formatDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('dd MMM yyyy').format(date);
}

class ChitGroupsScreen extends StatefulWidget {
  const ChitGroupsScreen({super.key});

  @override
  State<ChitGroupsScreen> createState() => _ChitGroupsScreenState();
}

class _ChitGroupsScreenState extends State<ChitGroupsScreen> {
  bool _isLoading = true;
  String? _loadError;
  List<ChitGroup> _groups = [];
  final TextEditingController _searchCtrl = TextEditingController();

  UserRole? get _role => SessionService.instance.role;
  bool get _isAdmin => _role == UserRole.admin || _role == UserRole.owner;
  bool get _isAgent => _role == UserRole.agent;
  bool get _isCustomer => _role == UserRole.customer;

  List<ChitGroup> get _filteredGroups {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _groups;

    return _groups.where((group) {
      return group.name.toLowerCase().contains(query) ||
          group.code.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openGroupDetails(ChitGroup group) async {
    if (_isCustomer) {
      await _openCustomerPassbook(group);
      return;
    }
    final updated = await showChitGroupDetailsSheet(context, group);
    if (updated != null && mounted) {
      await _loadGroups();
    }
  }

  /// Customers only ever see their own passbook — never the admin/agent
  /// member-management sheet.
  Future<void> _openCustomerPassbook(ChitGroup group) async {
    try {
      final member = await ChitGroupApiService.fetchMyMembership(group.id);
      if (!mounted) return;
      if (member == null) {
        final l10n = AppLocalizations.of(context);
        ToastService.show(
          title: l10n.notAMemberTitle,
          message: l10n.notAMemberMessage,
          type: ToastType.error,
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChitPassbookScreen(group: group, member: member),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: AppLocalizations.of(context).failedOpenPassbookTitle,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final groups = _isCustomer
          ? await ChitGroupApiService.fetchMyGroups()
          : await ChitGroupApiService.fetchAll();
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
        title: AppLocalizations.of(context).failedLoadGroupsTitle,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _showCreateGroupModal() async {
    final created = await showModalBottomSheet<ChitGroup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => const _GroupFormSheet(),
    );
    if (created == null || !mounted) return;
    await _loadGroups();
  }

  Future<void> _showEditGroupModal(ChitGroup group) async {
    final updated = await showModalBottomSheet<ChitGroup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _GroupFormSheet(group: group),
    );
    if (updated == null || !mounted) return;
    await _loadGroups();
  }

  Future<void> _confirmDeleteGroup(ChitGroup group) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.deleteGroupTitle,
      message: l10n.deleteGroupMessage(group.name),
      confirmLabel: l10n.deleteButton,
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true || !mounted) return;
    try {
      await ChitGroupApiService.delete(group.id);
      if (!mounted) return;
      await _loadGroups();
      ToastService.show(
        title: l10n.groupDeletedTitle,
        message: l10n.groupRemovedMessage(group.name),
        type: ToastType.warning,
      );
    } catch (e) {
      ToastService.show(
        title: l10n.deleteFailedTitle,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visibleGroups = _filteredGroups;
    final hasSearchQuery = _searchCtrl.text.trim().isNotEmpty;

    return AppShell(
      currentRoute: AppRoutes.chitGroups,
      title: l10n.chitGroupsTitle,
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: RefreshIndicator(
          onRefresh: _loadGroups,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(
                title: l10n.chitGroupsTitle,
                subtitle: l10n.chitGroupsSubtitle,
                actions: [
                  if (_isAdmin)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 150,
                        child: ElevatedButton.icon(
                          onPressed: _showCreateGroupModal,
                          icon: const Icon(Icons.add),
                          label: Text(
                            l10n.createGroupButton,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.kSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.kBorder)),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: hasSearchQuery
                        ? IconButton(
                            tooltip: l10n.clearSearchTooltip,
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear, size: 20),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_loadError != null)
                Column(
                  children: [
                    Text(_loadError!,
                        style: const TextStyle(color: AppColors.kDanger)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadGroups,
                      child: Text(l10n.retryButton),
                    ),
                  ],
                )
              else if (visibleGroups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      hasSearchQuery
                          ? l10n.noSearchResultsMessage
                          : _isCustomer
                              ? l10n.customerNoGroupMessage
                              : l10n.noGroupsFoundMessage,
                    ),
                  ),
                )
              else
                ...visibleGroups
                    .map((group) => _buildGroupCard(group))
                    .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(ChitGroup group) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _openGroupDetails(group),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24), // Smoother, modern corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.kBorder.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.kTextDark)),
                      const SizedBox(height: 4),
                      Text(l10n.groupNumberLabel(group.code),
                          style: const TextStyle(
                              color: AppColors.kTextMuted, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: group.status == ChitGroupStatus.active
                        ? AppColors.kSuccess.withOpacity(0.1)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    group.status.name.toUpperCase(),
                    style: TextStyle(
                      color: group.status == ChitGroupStatus.active
                          ? AppColors.kSuccess
                          : AppColors.kTextMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoItem(
                      label: l10n.membersLabel,
                      value: '${group.totalMembers}'),
                  _InfoItem(
                      label: l10n.durationLabel,
                      value: l10n.durationMonthsShort(group.durationMonths)),
                  _InfoItem(
                      label: l10n.valueLabel,
                      value: formatIndianCurrency(group.groupValue)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.collectionProgressLabel,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                Text(
                  '${group.collectedPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kGold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (group.collectedPercent / 100).clamp(0, 1).toDouble(),
                minHeight: 8,
                backgroundColor: const Color(0xFFEEEDE9),
                valueColor: const AlwaysStoppedAnimation(AppColors.kGold),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_isAdmin || _isAgent)
                  ElevatedButton.icon(
                    onPressed: () => _openGroupDetails(group),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kGold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.currency_rupee, size: 18),
                    label: Text(l10n.collectButton,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                if (_isCustomer)
                  ElevatedButton.icon(
                    onPressed: () => _openGroupDetails(group),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kGold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: Text(l10n.viewPassbookButton),
                  ),
                if (_isAdmin) ...[
                  IconButton(
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9)),
                    icon: const Icon(Icons.edit,
                        color: AppColors.kTextDark, size: 20),
                    onPressed: () => _showEditGroupModal(group),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2)),
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.kDanger, size: 20),
                    onPressed: () => _confirmDeleteGroup(group),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextDark)),
      ],
    );
  }
}

class _ScheduleItemConfig {
  _ScheduleItemConfig({
    required this.installmentNo,
    required this.dueDate,
    required this.payableAmount,
    required this.poolAmount,
    this.isCustomDate = false,
  });

  final int installmentNo;
  DateTime dueDate;
  double payableAmount;
  double poolAmount;
  bool isCustomDate;
}

class _GroupFormSheet extends StatefulWidget {
  const _GroupFormSheet({this.group});

  final ChitGroup? group;

  @override
  State<_GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<_GroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _membersCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _contributionCtrl;
  late final TextEditingController _startDateCtrl;
  ChitGroupStatus _status = ChitGroupStatus.active;
  DateTime? _startDate;
  bool _saving = false;
  String _drawFrequency = _drawFrequencyOptions.first;
  late final TextEditingController _drawIntervalCtrl;

  List<_ScheduleItemConfig> _scheduleConfigs = [];
  bool _loadingSchedule = false;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    final generatedCode = group?.code ??
        'CG-${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';
    _nameCtrl = TextEditingController(text: group?.name ?? '');
    _codeCtrl = TextEditingController(text: generatedCode);
    _membersCtrl =
        TextEditingController(text: group?.totalMembers.toString() ?? '');
    _durationCtrl =
        TextEditingController(text: group?.durationMonths.toString() ?? '');
    _valueCtrl =
        TextEditingController(text: group?.groupValue.toStringAsFixed(0) ?? '');
    _contributionCtrl = TextEditingController(
        text: group?.monthlyContribution.toStringAsFixed(0) ?? '');
    _startDate = group?.startDate ?? DateTime.now();
    _startDateCtrl = TextEditingController(text: formatDate(_startDate));
    // '1 Draw / Month (Monthly)' is the default frequency — it steps by
    // calendar month, not a fixed day gap, so the interval field starts blank.
    _drawIntervalCtrl = TextEditingController();
    if (group != null) _status = group.status;

    _durationCtrl.addListener(_recalculateSchedule);
    _valueCtrl.addListener(_recalculateSchedule);
    _contributionCtrl.addListener(_recalculateSchedule);
    _drawIntervalCtrl.addListener(_recalculateSchedule);

    if (group != null) {
      _loadExistingSchedules(group.id);
    } else {
      _recalculateSchedule();
    }
  }

  @override
  void dispose() {
    _durationCtrl.removeListener(_recalculateSchedule);
    _valueCtrl.removeListener(_recalculateSchedule);
    _contributionCtrl.removeListener(_recalculateSchedule);
    _drawIntervalCtrl.removeListener(_recalculateSchedule);

    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _membersCtrl.dispose();
    _durationCtrl.dispose();
    _valueCtrl.dispose();
    _contributionCtrl.dispose();
    _startDateCtrl.dispose();
    _drawIntervalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSchedules(String groupId) async {
    setState(() => _loadingSchedule = true);
    try {
      final schedules = await ChitGroupApiService.fetchSchedules(groupId);
      if (!mounted) return;
      if (schedules.isNotEmpty) {
        setState(() {
          _scheduleConfigs = schedules
              .map((s) => _ScheduleItemConfig(
                    installmentNo: s.installmentNo,
                    dueDate: s.dueDate,
                    payableAmount: s.payableAmount,
                    poolAmount: s.poolAmount,
                    isCustomDate:
                        s.dateType == ChitScheduleDateType.customOverridden,
                  ))
              .toList();
          _loadingSchedule = false;
        });
      } else {
        _loadingSchedule = false;
        _recalculateSchedule();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingSchedule = false);
        _recalculateSchedule();
      }
    }
  }

  // The interval field is only user-editable for 'Custom Day Interval' — the
  // other frequencies imply a fixed gap (or, for 'Custom Calendar Days', no
  // gap at all since every draw date is hand-picked below).
  bool get _isCustomDayInterval => _drawFrequency == 'Custom Day Interval';
  bool get _isCustomCalendarDays => _drawFrequency == 'Custom Calendar Days';
  bool get _isMonthly => _drawFrequency == '1 Draw / Month (Monthly)';
  bool get _showIntervalField => !_isCustomCalendarDays;

  void _onDrawFrequencyChanged(String frequency) {
    setState(() {
      _drawFrequency = frequency;
      final fixed = _fixedIntervalDaysFor(frequency);
      if (fixed != null) {
        _drawIntervalCtrl.text = '$fixed';
      } else if (_isMonthly) {
        _drawIntervalCtrl.clear();
      }
      // Custom Day Interval / Custom Calendar Days: leave whatever the user
      // already typed (or the default '1') in place.
    });
    _recalculateSchedule();
  }

  void _recalculateSchedule() {
    if (_loadingSchedule) return;
    final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    final startDate = _startDate ?? DateTime.now();
    final groupVal = double.tryParse(_valueCtrl.text.trim()) ?? 0;
    final contribution = double.tryParse(_contributionCtrl.text.trim()) ?? 0;

    if (duration <= 0) {
      if (_scheduleConfigs.isNotEmpty) {
        setState(() => _scheduleConfigs = []);
      }
      return;
    }

    // Days between consecutive draws for non-monthly, non-manual frequencies.
    // Falls back to the fixed gap for Bi-Monthly/Tri-Monthly/Every 10 Days,
    // or whatever the admin typed for Custom Day Interval.
    final intervalDays = _isMonthly || _isCustomCalendarDays
        ? null
        : (int.tryParse(_drawIntervalCtrl.text.trim()) ??
            _fixedIntervalDaysFor(_drawFrequency) ??
            30);

    final newConfigs = <_ScheduleItemConfig>[];
    for (int i = 1; i <= duration; i++) {
      DateTime date;
      bool isCustom = false;
      if (i - 1 < _scheduleConfigs.length &&
          _scheduleConfigs[i - 1].isCustomDate) {
        // A date the admin hand-picked in the schedule list below always
        // wins, regardless of frequency.
        date = _scheduleConfigs[i - 1].dueDate;
        isCustom = true;
      } else if (_isCustomCalendarDays) {
        // No auto-computed gap — keep the previous value as a starting
        // point (monthly-spaced) so there's something to edit per row.
        date = i - 1 < _scheduleConfigs.length
            ? _scheduleConfigs[i - 1].dueDate
            : DateTime(startDate.year, startDate.month + (i - 1), startDate.day);
      } else if (_isMonthly) {
        date = DateTime(
          startDate.year,
          startDate.month + (i - 1),
          startDate.day,
        );
      } else {
        date = startDate.add(Duration(days: intervalDays! * (i - 1)));
      }
      newConfigs.add(_ScheduleItemConfig(
        installmentNo: i,
        dueDate: date,
        payableAmount: contribution > 0
            ? contribution
            : (duration > 0 ? groupVal / duration : 0),
        poolAmount: groupVal,
        isCustomDate: isCustom,
      ));
    }

    setState(() {
      _scheduleConfigs = newConfigs;
    });
  }

  void _applyPreset(_SchemePreset preset) {
    setState(() {
      _nameCtrl.text = preset.groupName;
      _membersCtrl.text = preset.totalMembers.toString();
      _durationCtrl.text = preset.durationMonths.toString();
      _valueCtrl.text = preset.groupValue.toStringAsFixed(0);
      _contributionCtrl.text = preset.monthlyContribution.toStringAsFixed(0);
      _drawFrequency = preset.drawFrequencyLabel;
      _drawIntervalCtrl.text = preset.drawInterval.toString();
    });
    _recalculateSchedule();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      _startDateCtrl.text = formatDate(_startDate);
    });
    _recalculateSchedule();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) return;

    if (_codeCtrl.text.trim().isEmpty) {
      _codeCtrl.text =
          'CG-${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';
    }

    setState(() => _saving = true);
    final group = ChitGroup(
      id: widget.group?.id ?? '',
      code: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      status: _status,
      totalMembers: int.tryParse(_membersCtrl.text.trim()) ?? 0,
      durationMonths: int.tryParse(_durationCtrl.text.trim()) ?? 0,
      groupValue: double.tryParse(_valueCtrl.text.trim()) ?? 0,
      monthlyContribution: double.tryParse(_contributionCtrl.text.trim()) ?? 0,
      startDate: _startDate!,
      collectedAmount: widget.group?.collectedAmount ?? 0,
    );

    try {
      final result = widget.group == null
          ? await ChitGroupApiService.create(group)
          : await ChitGroupApiService.update(group);

      if (widget.group != null) {
        try {
          await ChitGroupApiService.deleteSchedulesForGroup(result.id);
        } catch (_) {}
      }

      if (_scheduleConfigs.isNotEmpty) {
        final scheduleRows = _scheduleConfigs.map((cfg) {
          return {
            'group_id': result.id,
            'installment_no': cfg.installmentNo,
            'due_date': cfg.dueDate.toIso8601String().split('T').first,
            'payable_amount': cfg.payableAmount,
            'pool_amount': cfg.poolAmount,
            'is_custom': cfg.isCustomDate ? 1 : 0,
          };
        }).toList();
        await ChitGroupApiService.saveSchedules(scheduleRows);
      }

      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      Navigator.of(context).pop(result);
      ToastService.show(
        title:
            widget.group == null ? l10n.groupCreatedTitle : l10n.groupUpdatedTitle,
        message: group.name,
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ToastService.show(
        title: AppLocalizations.of(context).saveFailedTitle,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Widget _buildScheduleConfigSection() {
    if (_scheduleConfigs.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.installmentScheduleHeader(_scheduleConfigs.length),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextMuted,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.autoGeneratedBadge(_scheduleConfigs.length),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kSuccess,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F8F4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Column(
            children: _scheduleConfigs
                .map((cfg) => _ScheduleConfigItemCard(
                      config: cfg,
                      onDateChanged: (newDate) {
                        setState(() {
                          cfg.dueDate = newDate;
                          cfg.isCustomDate = true;
                        });
                      },
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.group != null;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? l10n.editGroupTitle
                            : l10n.createGroupSheetTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextDark,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close,
                            color: AppColors.kTextMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EEFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 16, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 6),
                            Text(l10n.quickSchemePresetsLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4C1D95),
                                    fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _schemePresets
                              .map((p) => _PresetChip(
                                    preset: p,
                                    onTap: () => _applyPreset(p),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.groupNameLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(isDense: true),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? l10n.requiredValidation
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.membersFieldLabel,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.kTextMuted)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _membersCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return l10n.requiredValidation;
                                if (int.tryParse(v.trim()) == null)
                                  return l10n.enterNumberValidation;
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.durationFieldLabel,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.kTextMuted)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _durationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return l10n.requiredValidation;
                                if (int.tryParse(v.trim()) == null)
                                  return l10n.enterNumberValidation;
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.groupValueLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return l10n.requiredValidation;
                      if (double.tryParse(v.trim()) == null)
                        return l10n.enterNumberValidation;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.monthlyContributionLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _contributionCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return l10n.requiredValidation;
                      if (double.tryParse(v.trim()) == null)
                        return l10n.enterNumberValidation;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.startDateLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _startDateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(isDense: true),
                    onTap: _pickStartDate,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? l10n.requiredValidation
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.drawFrequencyLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _drawFrequency,
                    isExpanded: true,
                    items: _drawFrequencyOptions
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _onDrawFrequencyChanged(v);
                    },
                    decoration: const InputDecoration(isDense: true),
                  ),
                  if (_showIntervalField) ...[
                    const SizedBox(height: 16),
                    Text(l10n.drawIntervalLabel,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextMuted)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _drawIntervalCtrl,
                      keyboardType: TextInputType.number,
                      readOnly: !_isCustomDayInterval,
                      style: TextStyle(
                          color: _isCustomDayInterval
                              ? AppColors.kTextDark
                              : AppColors.kTextMuted),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: l10n.drawIntervalHint,
                        filled: !_isCustomDayInterval,
                        fillColor: const Color(0xFFF3F4F6),
                      ),
                      validator: (v) {
                        if (!_isCustomDayInterval) return null;
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) {
                          return l10n.enterDaysValidation;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isMonthly
                          ? l10n.monthlyIntervalHelp
                          : _isCustomDayInterval
                              ? l10n.customIntervalHelp
                              : l10n.fixedIntervalHelp,
                      style: const TextStyle(
                          color: AppColors.kTextMuted, fontSize: 12),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.manualDatesHelp,
                      style: const TextStyle(
                          color: AppColors.kTextMuted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(l10n.statusLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ChitGroupStatus>(
                    value: _status,
                    items: ChitGroupStatus.values
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() {
                      if (value != null) _status = value;
                    }),
                    decoration: const InputDecoration(isDense: true),
                  ),
                  _buildScheduleConfigSection(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancelButton),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saving ? null : _handleSave,
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isEditing
                                ? l10n.saveChangesButton
                                : l10n.createGroupSheetTitle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleConfigItemCard extends StatelessWidget {
  const _ScheduleConfigItemCard({
    required this.config,
    required this.onDateChanged,
  });

  final _ScheduleItemConfig config;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.installmentNumberLabel(config.installmentNo),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.kTextDark,
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: config.dueDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) onDateChanged(picked);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: config.isCustomDate
                        ? const Color(0xFFEDE9FE)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: config.isCustomDate
                          ? const Color(0xFFC4B5FD)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: config.isCustomDate
                            ? const Color(0xFF7C3AED)
                            : AppColors.kTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(config.dueDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: config.isCustomDate
                              ? const Color(0xFF7C3AED)
                              : AppColors.kTextDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.payableLabel,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMuted)),
                    Text(
                      formatIndianCurrency(config.payableAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kSuccess,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.poolDividendValueShortLabel,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMuted)),
                    Text(
                      formatIndianCurrency(config.poolAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4C1D95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.preset, required this.onTap});
  final _SchemePreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: preset.color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, size: 14, color: preset.color),
            const SizedBox(width: 6),
            Text(preset.chipLabel,
                style: TextStyle(
                    color: preset.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

Future<ChitGroup?> showChitGroupDetailsSheet(
  BuildContext context,
  ChitGroup group,
) {
  return showModalBottomSheet<ChitGroup>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (context) => _GroupDetailsFrame(group: group),
  );
}

class _GroupDetailsFrame extends StatefulWidget {
  const _GroupDetailsFrame({required this.group});

  final ChitGroup group;

  @override
  State<_GroupDetailsFrame> createState() => _GroupDetailsFrameState();
}

class _GroupDetailsFrameState extends State<_GroupDetailsFrame> {
  late ChitGroup _group;
  List<ChitMember> _members = [];
  bool _isLoading = true;
  String? _loadError;
  bool _changed = false;

  int _activeTab = 0; // 0 = Member Collections, 1 = Installment Schedule
  List<ChitSchedule> _schedules = [];
  bool _loadingSchedules = false;
  String? _scheduleLoadError;

  UserRole? get _role => SessionService.instance.role;

  bool get _canAddOrDeleteMembers =>
      _role == UserRole.admin || _role == UserRole.owner;

  /// Only admin/owner can edit or delete installment schedule rows.
  /// Agents get a read-only view — the "Override Date & Amount" action
  /// is not rendered as tappable for them.
  bool get _canManageSchedule =>
      _role == UserRole.admin || _role == UserRole.owner;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadMembers();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _loadingSchedules = true;
      _scheduleLoadError = null;
    });
    try {
      final schedules = await ChitGroupApiService.fetchSchedules(_group.id);
      if (!mounted) return;
      setState(() {
        _schedules = schedules;
        _loadingSchedules = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scheduleLoadError = e.toString();
        _loadingSchedules = false;
      });
    }
  }

  Future<void> _openOverrideDialog(ChitSchedule schedule) async {
    if (!_canManageSchedule) return; // hard guard, agents never reach here
    final updated = await showModalBottomSheet<ChitSchedule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _OverrideScheduleSheet(schedule: schedule),
    );
    if (updated == null || !mounted) return;
    setState(() {
      final idx = _schedules.indexWhere((s) => s.id == updated.id);
      if (idx != -1) _schedules[idx] = updated;
      _changed = true;
    });
    final l10n = AppLocalizations.of(context);
    ToastService.show(
      title: l10n.installmentUpdatedTitle,
      message: l10n.drawOverriddenMessage(updated.installmentNo),
      type: ToastType.success,
    );
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final members = await ChitGroupApiService.fetchMembers(_group.id);
      if (!mounted) return;
      setState(() {
        _members = members;
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

  Future<void> _openAddMember() async {
    final added = await showModalBottomSheet<ChitMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _AddMemberFrame(group: _group),
    );
    if (added == null || !mounted) return;
    setState(() {
      _members = [..._members, added];
      _changed = true;
    });
    ToastService.show(
      title: AppLocalizations.of(context).memberAddedTitle,
      message: added.memberName,
      type: ToastType.success,
    );
  }

  Future<void> _confirmDeleteMember(ChitMember member) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.removeMemberTitle,
      message: l10n.removeMemberMessage(member.memberName),
      confirmLabel: l10n.removeButton,
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ChitGroupApiService.deleteMember(member.id);
      if (!mounted) return;
      setState(() {
        _members.removeWhere((m) => m.id == member.id);
        _changed = true;
      });
      ToastService.show(
        title: l10n.memberRemovedTitle,
        message: member.memberName,
        type: ToastType.warning,
      );
    } catch (e) {
      ToastService.show(
        title: l10n.removeFailedTitle,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _collect(ChitMember member) async {
    ChitSchedule? nextDraw;
    if (member.customerId != null) {
      final passbook = await ChitGroupApiService.fetchPassbook(member.id);
      final nextDrawNumber = passbook.nextDueDraw?.drawNumber;
      for (final schedule in _schedules) {
        if (schedule.installmentNo == nextDrawNumber) {
          nextDraw = schedule;
          break;
        }
      }
    }
    final draw = nextDraw ?? (_schedules.isEmpty ? null : _schedules.first);
    if (draw == null) {
      final l10n = AppLocalizations.of(context);
      ToastService.show(
        title: l10n.collectionUnavailableTitle,
        message: l10n.noScheduleMessage,
        type: ToastType.error,
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChitCollectionSheet(
        member: member,
        group: _group,
        draw: draw,
        onSubmit: (amount, method, date, notes) =>
            _saveCollection(member, draw, amount, method, date, notes),
      ),
    );
  }

  Future<void> _saveCollection(ChitMember member, ChitSchedule draw,
      double amount, String method, DateTime date, String? notes) async {
    try {
      await CollectionApiService.createCollection({
        'receipt_number': 'CHIT-${DateTime.now().millisecondsSinceEpoch}',
        'customer_id': member.customerId,
        'customer_name': member.memberName,
        'loan_number': _group.code,
        'collection_amount': amount,
        'payment_method': method,
        'collection_date': DateFormat('yyyy-MM-dd').format(date),
        'notes': 'Chit group: ${_group.id}; Draw #${draw.installmentNo}'
            '${notes == null || notes.trim().isEmpty ? '' : '; ${notes.trim()}'}',
        'agent_id': SessionService.instance.currentUser?.userId,
        'agent_name': SessionService.instance.currentUser?.name,
      });

      final updatedMember = await ChitGroupApiService.collectFromMember(
        memberId: member.id,
        status: amount >= draw.payableAmount
            ? ChitPaymentStatus.paid
            : ChitPaymentStatus.partial,
      );

      final updatedGroup = await ChitGroupApiService.recordCollection(
        groupId: _group.id,
        collectedAmount: _group.collectedAmount + amount,
        pendingAmount: (_group.groupValue - _group.collectedAmount - amount)
            .clamp(0, _group.groupValue)
            .toDouble(),
        status: _group.groupValue <= _group.collectedAmount + amount
            ? 'closed'
            : 'active',
      );

      if (!mounted) return;
      setState(() {
        _group = updatedGroup;
        final memberIndex = _members.indexWhere((item) => item.id == member.id);
        if (memberIndex != -1) _members[memberIndex] = updatedMember;
        _changed = true;
      });
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ToastService.show(
        title: l10n.collectionRecordedTitle,
        message: l10n.collectionRecordedMessage(
            member.memberName, formatIndianCurrency(amount)),
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: AppLocalizations.of(context).collectionFailedTitle,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: const BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _group.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.close, color: AppColors.kTextMuted),
                      onPressed: () =>
                          Navigator.of(context).pop(_changed ? _group : null),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _loadError != null
                          ? Column(
                              children: [
                                Text(_loadError!,
                                    style: const TextStyle(
                                        color: AppColors.kDanger)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                    onPressed: _loadMembers,
                                    child: Text(l10n.retryButton)),
                              ],
                            )
                          : _buildContent(l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _DetailStat(
                    label: l10n.groupNumberShortLabel, value: _group.code)),
            Expanded(
                child: _DetailStat(
                    label: l10n.membersLabel,
                    value: '${_group.totalMembers}')),
            Expanded(
                child: _DetailStat(
                    label: l10n.valueLabel,
                    value: formatIndianCurrency(_group.groupValue))),
            Expanded(
                child: _DetailStat(
                    label: l10n.durationLabel,
                    value: l10n.durationMonthsShort(_group.durationMonths))),
          ],
        ),
        const SizedBox(height: 20),

        // Upgraded Progress Container with shadow and clean borders
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)), // Softer border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.collectionProgressLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(
                    '${formatIndianCurrency(_group.collectedAmount)} / ${formatIndianCurrency(_group.groupValue)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (_group.collectedPercent / 100).clamp(0, 1).toDouble(),
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF1EFE8),
                  valueColor: const AlwaysStoppedAnimation(AppColors.kGold),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dot(color: AppColors.kSuccess),
                      const SizedBox(width: 8),
                      Text(
                          'Collected ${formatIndianCurrency(_group.collectedAmount)}',
                          style: const TextStyle(
                              color: AppColors.kSuccess,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dot(color: AppColors.kDanger),
                      const SizedBox(width: 8),
                      Text(
                          'Pending ${formatIndianCurrency(_group.pendingAmount)}',
                          style: const TextStyle(
                              color: AppColors.kDanger,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // FIX: Scrollable row prevents the "out of screen" overflow error
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _TabButton(
                icon: Icons.people_alt_outlined,
                label: l10n.memberCollectionsTab(_members.length),
                selected: _activeTab == 0,
                onTap: () => setState(() => _activeTab = 0),
              ),
              const SizedBox(width: 24),
              _TabButton(
                icon: Icons.calendar_month_outlined,
                label: l10n.installmentScheduleTab(_schedules.length),
                selected: _activeTab == 1,
                onTap: () => setState(() => _activeTab = 1),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        const SizedBox(height: 20),

        if (_activeTab == 0)
          _buildMemberSection(l10n)
        else
          _buildScheduleSection(l10n),
      ],
    );
  }

  Widget _buildMemberSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(l10n.memberCollectionTrackingTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.kTextDark)),
            ),
            if (_canAddOrDeleteMembers)
              TextButton.icon(
                onPressed: _openAddMember,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(
                      0xFF6B46C1), // Matches the purple "Add Member" in the image
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: Text(l10n.addMemberButton,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_members.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(l10n.noMembersMessage,
                  style: const TextStyle(
                      color: AppColors.kTextMuted, fontSize: 15)),
            ),
          )
        else
          // Wrapping the table in a horizontal scroll view makes it mobile responsive
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              // Ensures the table expands to at least the full width of the screen
              constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC), // Light gray header background
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader(l10n.memberColumnHeader, 180),
                        _buildTableHeader(l10n.contributionColumnHeader, 120),
                        _buildTableHeader(l10n.dueDateColumnHeader, 130),
                        _buildTableHeader(l10n.statusColumnHeader, 100),
                        _buildTableHeader(l10n.actionColumnHeader, 140,
                            alignRight: true),
                      ],
                    ),
                  ),
                  // Table Data Rows
                  ..._members.map((m) => _buildTableRow(m, l10n)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Helper for consistent table headers
  Widget _buildTableHeader(String title, double width,
      {bool alignRight = false}) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _paymentStatusLabel(ChitPaymentStatus status, AppLocalizations l10n) {
    switch (status) {
      case ChitPaymentStatus.paid:
        return l10n.paidStatus;
      case ChitPaymentStatus.partial:
        return l10n.partialStatus;
      case ChitPaymentStatus.overdue:
        return l10n.overdueStatus;
      case ChitPaymentStatus.pending:
        return l10n.pendingStatus;
    }
  }

  Color _paymentStatusBackground(ChitPaymentStatus status) {
    switch (status) {
      case ChitPaymentStatus.paid:
        return const Color(0xFFD1FAE5);
      case ChitPaymentStatus.partial:
        return const Color(0xFFDBEAFE);
      case ChitPaymentStatus.overdue:
        return const Color(0xFFFEE2E2);
      case ChitPaymentStatus.pending:
        return const Color(0xFFFEF3C7);
    }
  }

  Color _paymentStatusForeground(ChitPaymentStatus status) {
    switch (status) {
      case ChitPaymentStatus.paid:
        return const Color(0xFF059669);
      case ChitPaymentStatus.partial:
        return const Color(0xFF2563EB);
      case ChitPaymentStatus.overdue:
        return AppColors.kDanger;
      case ChitPaymentStatus.pending:
        return const Color(0xFFD97706);
    }
  }

  // Helper replacing the old _MemberRow to match the table format.
  Widget _buildTableRow(ChitMember member, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // 1. MEMBER COLUMN
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.memberName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextDark,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(member.phone ?? 'N/A',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),

          // 2. CONTRIBUTION COLUMN
          SizedBox(
            width: 120,
            child: Text(formatIndianCurrency(member.contributionAmount),
                style: const TextStyle(
                    color: AppColors.kTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),

          // 3. DUE DATE COLUMN
          SizedBox(
            width: 130,
            child: Row(
              children: [
                Text(formatDate(member.dueDate ?? DateTime.now()),
                    style: const TextStyle(
                        color: AppColors.kTextDark, fontSize: 14)),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
          ),

          // 4. STATUS COLUMN
          SizedBox(
            width: 100,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _paymentStatusBackground(member.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _paymentStatusLabel(member.status, l10n),
                  style: TextStyle(
                    color: _paymentStatusForeground(member.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // 5. ACTION COLUMN
          SizedBox(
            width: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: member.status == ChitPaymentStatus.paid
                      ? null
                      : () => _collect(member),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF059669), // Green matching the image
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.currency_rupee, size: 18),
                  label: Text(l10n.collectButton,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (_canAddOrDeleteMembers) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.person_remove_outlined,
                        color: AppColors.kDanger, size: 20),
                    onPressed: () => _confirmDeleteMember(member),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Installment Schedule',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.kTextDark)),
        const SizedBox(height: 4),
        Text(
          l10n.installmentScheduleSubtitle,
          style: const TextStyle(
              color: AppColors.kTextMuted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        if (_loadingSchedules)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_scheduleLoadError != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(_scheduleLoadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.kDanger)),
                const SizedBox(height: 12),
                ElevatedButton(
                    onPressed: _loadSchedules,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kDanger,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.retryButton)),
              ],
            ),
          )
        else if (_schedules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(l10n.noScheduleFoundMessage,
                  style: const TextStyle(
                      color: AppColors.kTextMuted, fontSize: 15)),
            ),
          )
        else
          _ScheduleTable(
            schedules: _schedules,
            canOverride: _canManageSchedule,
            onOverride: _openOverrideDialog,
          ),
      ],
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.kTextMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.kTextDark)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _ChitCollectionSheet extends StatefulWidget {
  const _ChitCollectionSheet({
    required this.member,
    required this.group,
    required this.draw,
    required this.onSubmit,
  });

  final ChitMember member;
  final ChitGroup group;
  final ChitSchedule draw;
  final void Function(double, String, DateTime, String?) onSubmit;

  @override
  State<_ChitCollectionSheet> createState() => _ChitCollectionSheetState();
}

class _ChitCollectionSheetState extends State<_ChitCollectionSheet> {
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  String _method = 'Cash';
  DateTime _date = DateTime.now();

  static const _methods = ['Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Card'];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.draw.payableAmount.round().toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;
    final method = {
      'Cash': 'cash',
      'UPI': 'upi',
      'Bank Transfer': 'bank',
      'Cheque': 'cheque',
      'Card': 'card',
    }[_method]!;
    widget.onSubmit(amount, method, _date, _notesController.text);
    Navigator.of(context).pop();
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.kGold, width: 1.5),
        ),
      );

  Widget _label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              color: AppColors.kTextMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.kDanger),
                    ),
                  ]
                : null,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: AppColors.kSurface,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 22, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.recordChitCollectionTitle,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon:
                          const Icon(Icons.close, color: AppColors.kTextMuted),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.member.memberName,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              '${formatIndianCurrency(widget.member.contributionAmount)} ${widget.group.name} (${widget.group.code})',
                              style: const TextStyle(
                                  color: AppColors.kTextMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Text(formatIndianCurrency(widget.draw.payableAmount),
                          style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _label(l10n.collectionAmountLabel, required: true),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration('0'),
                ),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(l10n.paymentMethodLabel, required: true),
                          DropdownButtonFormField<String>(
                            value: _method,
                            decoration: _decoration(l10n.selectMethodHint),
                            items: _methods
                                .map((method) => DropdownMenuItem(
                                    value: method, child: Text(method)))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _method = value ?? 'Cash'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(l10n.collectionDateLabel, required: true),
                          InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: _decoration(l10n.dateHint),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(DateFormat('dd/MM/yyyy').format(_date)),
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 19),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _label(l10n.notesOptionalLabel),
                TextField(
                  controller: _notesController,
                  decoration: _decoration(l10n.receiptNotesHint),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 17),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: Text(l10n.cancelButton),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.currency_rupee),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB47A05),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 17),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      label: Text(l10n.confirmCollectionButton),
                    ),
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

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.canDelete,
    required this.onCollect,
    required this.onDelete,
  });

  final ChitMember member;
  final bool canDelete;
  final VoidCallback? onCollect;
  final VoidCallback onDelete;

  Color get _statusBg {
    switch (member.status) {
      case ChitPaymentStatus.paid:
        return const Color(0xFFDCFCE7);
      case ChitPaymentStatus.partial:
        return const Color(0xFFDBEAFE);
      case ChitPaymentStatus.overdue:
        return const Color(0xFFFEE2E2);
      case ChitPaymentStatus.pending:
        return const Color(0xFFFEF3C7);
    }
  }

  Color get _statusFg {
    switch (member.status) {
      case ChitPaymentStatus.paid:
        return AppColors.kSuccess;
      case ChitPaymentStatus.partial:
        return const Color(0xFF2563EB);
      case ChitPaymentStatus.overdue:
        return AppColors.kDanger;
      case ChitPaymentStatus.pending:
        return AppColors.kWarning;
    }
  }

  String get _statusLabel {
    final s = member.status.name;
    return s[0].toUpperCase() + s.substring(1);
  }

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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.memberName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextDark)),
                if (member.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(member.phone!,
                      style: const TextStyle(
                          color: AppColors.kTextMuted, fontSize: 12)),
                ],
                const SizedBox(height: 4),
                Text(
                  member.dueDate != null
                      ? '${formatIndianCurrency(member.contributionAmount)} · Due ${formatDate(member.dueDate!)}'
                      : formatIndianCurrency(member.contributionAmount),
                  style: const TextStyle(
                      color: AppColors.kTextMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _statusBg, borderRadius: BorderRadius.circular(999)),
            child: Text(
              _statusLabel,
              style: TextStyle(
                  color: _statusFg, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (onCollect != null) ...[
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: onCollect,
              icon: const Icon(Icons.currency_rupee_rounded, size: 16),
              label: const Text('Collect'),
            ),
          ],
          if (canDelete) ...[
            const SizedBox(width: 2),
            IconButton(
              icon: const Icon(Icons.person_remove_alt_1_outlined,
                  color: AppColors.kDanger, size: 20),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.kGold : AppColors.kTextMuted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 2,
              color: selected ? AppColors.kGold : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

const _scheduleHeaderStyle = TextStyle(
    fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.kTextMuted);

class _ScheduleTable extends StatelessWidget {
  const _ScheduleTable({
    required this.schedules,
    required this.canOverride,
    required this.onOverride,
  });

  final List<ChitSchedule> schedules;
  final bool canOverride;
  final ValueChanged<ChitSchedule> onOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return Column(
            children: schedules
                .map((s) => _MobileScheduleCard(
                      schedule: s,
                      canOverride: canOverride,
                      onOverride: () => onOverride(s),
                    ))
                .toList(),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth:
                    constraints.maxWidth > 680 ? constraints.maxWidth : 680),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.kBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF6F5F1),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Text(l10n.instNumberColumnHeader,
                                style: _scheduleHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text(l10n.dueDateColumnHeader,
                                style: _scheduleHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text(l10n.payableAmountColumnHeader,
                                style: _scheduleHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text(l10n.poolDividendValueColumnHeader,
                                style: _scheduleHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text(l10n.dateTypeColumnHeader,
                                style: _scheduleHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text(l10n.actionColumnHeader,
                                style: _scheduleHeaderStyle)),
                      ],
                    ),
                  ),
                  ...schedules.map((s) => _ScheduleRow(
                        schedule: s,
                        canOverride: canOverride,
                        onOverride: () => onOverride(s),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileScheduleCard extends StatelessWidget {
  const _MobileScheduleCard({
    required this.schedule,
    required this.canOverride,
    required this.onOverride,
  });

  final ChitSchedule schedule;
  final bool canOverride;
  final VoidCallback onOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCustom = schedule.dateType == ChitScheduleDateType.customOverridden;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.kBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.installmentNumberLabel(schedule.installmentNo),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.kTextDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCustom
                      ? const Color(0xFFEDE9FE)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCustom
                      ? l10n.customOverriddenBadge
                      : l10n.autoScheduledBadge,
                  style: TextStyle(
                    color:
                        isCustom ? const Color(0xFF7C3AED) : AppColors.kSuccess,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.dueDateCardLabel,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMuted)),
                    const SizedBox(height: 2),
                    Text(
                      formatDate(schedule.dueDate),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.payableAmountCardLabel,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMuted)),
                    const SizedBox(height: 2),
                    Text(
                      formatIndianCurrency(schedule.payableAmount),
                      style: const TextStyle(
                          color: AppColors.kSuccess,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.poolValueCardLabel,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMuted)),
                    const SizedBox(height: 2),
                    Text(
                      formatIndianCurrency(schedule.poolAmount),
                      style: const TextStyle(
                          color: Color(0xFF4C1D95),
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (canOverride)
                TextButton.icon(
                  onPressed: onOverride,
                  icon: const Icon(Icons.edit_calendar_outlined, size: 14),
                  label: Text(l10n.overrideButton,
                      style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.schedule,
    required this.canOverride,
    required this.onOverride,
  });

  final ChitSchedule schedule;
  final bool canOverride;
  final VoidCallback onOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCustom = schedule.dateType == ChitScheduleDateType.customOverridden;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text('#${schedule.installmentNo}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(formatDate(schedule.dueDate),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(formatIndianCurrency(schedule.payableAmount),
                style: const TextStyle(
                    color: AppColors.kSuccess, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(formatIndianCurrency(schedule.poolAmount),
                style: const TextStyle(
                    color: Color(0xFF4C1D95), fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCustom
                      ? const Color(0xFFEDE9FE)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCustom)
                      const Icon(Icons.schedule,
                          size: 12, color: Color(0xFF7C3AED)),
                    if (isCustom) const SizedBox(width: 4),
                    Text(
                      isCustom
                          ? l10n.customOverriddenBadge
                          : l10n.autoScheduledBadge,
                      style: TextStyle(
                        color: isCustom
                            ? const Color(0xFF7C3AED)
                            : AppColors.kSuccess,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: canOverride
                ? TextButton.icon(
                    onPressed: onOverride,
                    icon: const Icon(Icons.edit_calendar_outlined, size: 15),
                    label: Text(l10n.overrideDateAmountButton,
                        style: const TextStyle(fontSize: 12)),
                  )
                : Text(l10n.viewOnlyLabel,
                    style: const TextStyle(
                        color: AppColors.kTextMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// ADD MEMBER SHEET (image 1 mockup)
/// -----------------------------------------------------------------------
class _AddMemberFrame extends StatefulWidget {
  const _AddMemberFrame({required this.group});
  final ChitGroup group;

  @override
  State<_AddMemberFrame> createState() => _AddMemberFrameState();
}

class _AddMemberFrameState extends State<_AddMemberFrame> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  List<ChitCustomerOption> _customers = [];
  ChitCustomerOption? _selectedCustomer;
  bool _loadingCustomers = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: widget.group.monthlyContribution.round().toString());
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _loadingCustomers = true;
      _loadError = null;
    });
    try {
      final customers = await ChitGroupApiService.fetchCustomers();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _loadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingCustomers = false;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_selectedCustomer == null) {
      final l10n = AppLocalizations.of(context);
      ToastService.show(
        title: l10n.selectCustomerTitle,
        message: l10n.selectCustomerMessage,
        type: ToastType.error,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final member = await ChitGroupApiService.addMember(
        groupId: widget.group.id,
        customerId: _selectedCustomer!.id,
        memberName: _selectedCustomer!.name,
        phone: _selectedCustomer!.phone,
        contributionAmount: double.parse(_amountCtrl.text),
      );
      if (!mounted) return;
      Navigator.of(context).pop(member);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ToastService.show(
        title: AppLocalizations.of(context).addMemberFailedTitle,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.addMemberTitle,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextDark)),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close,
                            color: AppColors.kTextMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.customerLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  _loadingCustomers
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        )
                      : _loadError != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_loadError!,
                                    style: const TextStyle(
                                        color: AppColors.kDanger)),
                                TextButton(
                                    onPressed: _loadCustomers,
                                    child: Text(l10n.retryButton)),
                              ],
                            )
                          : DropdownButtonFormField<ChitCustomerOption>(
                              value: _selectedCustomer,
                              isExpanded: true,
                              decoration: const InputDecoration(isDense: true),
                              hint: Text(l10n.selectCustomerHint),
                              items: _customers
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c.displayLabel,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCustomer = v),
                              validator: (v) =>
                                  v == null ? l10n.requiredValidation : null,
                            ),
                  if (_selectedCustomer != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 16, color: AppColors.kTextMuted),
                        const SizedBox(width: 6),
                        Text(
                          _selectedCustomer!.phone?.trim().isNotEmpty == true
                              ? l10n.customerRolePhone(
                                  _selectedCustomer!.role.toUpperCase(),
                                  _selectedCustomer!.phone!)
                              : l10n.customerNumberNotAvailable(
                                  _selectedCustomer!.role.toUpperCase()),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.kTextMuted),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(l10n.contributionAmountLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(isDense: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return l10n.requiredValidation;
                      if (num.tryParse(v) == null)
                        return l10n.enterValidNumberValidation;
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.defaultsToAmount(formatIndianCurrency(
                        widget.group.monthlyContribution)),
                    style: const TextStyle(
                        color: AppColors.kTextMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancelButton),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _handleSave,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.person_add_alt_1),
                        label: Text(l10n.addMemberButton),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
