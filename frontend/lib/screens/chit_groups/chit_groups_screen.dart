import 'dart:math';
import '../../theme/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/glass_toast.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../models/chit_group.dart';
import '../../services/chit_group_api_service.dart'; 

/// -----------------------------------------------------------------------
/// MODEL HELPERS
/// -----------------------------------------------------------------------
extension ChitGroupStatusX on ChitGroupStatus {
  String get label {
    switch (this) {
      case ChitGroupStatus.active:
        return 'Active';
      case ChitGroupStatus.completed:
        return 'Completed';
      case ChitGroupStatus.upcoming:
        return 'Upcoming';
    }
  }

  Color get bg {
    switch (this) {
      case ChitGroupStatus.active:
        return const Color(0xFFDCFCE7);
      case ChitGroupStatus.completed:
        return const Color(0xFFE5E7EB);
      case ChitGroupStatus.upcoming:
        return const Color(0xFFFEF3C7);
    }
  }

  Color get fg {
    switch (this) {
      case ChitGroupStatus.active:
        return AppColors.kSuccess;
      case ChitGroupStatus.completed:
        return AppColors.kTextMuted;
      case ChitGroupStatus.upcoming:
        return AppColors.kWarning;
    }
  }
}

/// Formats a number in the Indian numbering system, e.g. 500000 -> "5,00,000".
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

String formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final dd = d.day.toString().padLeft(2, '0');
  return '$dd ${months[d.month - 1]} ${d.year}';
}

String _randomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rnd = Random();
  return 'GRP-${List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join()}';
}

/// -----------------------------------------------------------------------
/// SCREEN
/// -----------------------------------------------------------------------
class ChitGroupsScreen extends StatefulWidget {
  const ChitGroupsScreen({super.key});

  @override
  State<ChitGroupsScreen> createState() => _ChitGroupsScreenState();
}

class _ChitGroupsScreenState extends State<ChitGroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _statusFilter = 'All Status';

  List<ChitGroup> _groups = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final groups = await ChitGroupApiService.fetchAll();
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
        title: 'Failed to load groups',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  List<ChitGroup> get _filteredGroups {
    final query = _searchController.text.trim().toLowerCase();
    return _groups.where((g) {
      final matchesQuery =
          query.isEmpty || g.name.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'All Status' || g.status.label == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  double get _totalCollected => _groups.fold(
        0,
        (sum, g) => sum + (g.groupValue * g.collectedPercent / 100),
      );

  double get _totalPending => _groups.fold(
        0,
        (sum, g) =>
            sum + (g.groupValue - (g.groupValue * g.collectedPercent / 100)),
      );

  int get _activeCount =>
      _groups.where((g) => g.status == ChitGroupStatus.active).length;

  /// Helper to wrap form or view content inside the identical 75% max height
  /// bottom-sheet layout frame used across the app (see LoansScreen).
  Widget _buildGlobalSheetFrame({required Widget child}) {
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final double maxSheetHeight = MediaQuery.of(context).size.height * 0.75;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: const BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final result = await showModalBottomSheet<ChitGroup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: const _GroupFormDialog(),
      ),
    );
    if (result == null) return;

    try {
      final created = await ChitGroupApiService.create(result);
      setState(() => _groups.insert(0, created));
      ToastService.show(
        title: 'Group created',
        message: created.name,
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Create failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _openEditDialog(ChitGroup group) async {
    final result = await showModalBottomSheet<ChitGroup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: _GroupFormDialog(existing: group),
      ),
    );
    if (result == null) return;

    try {
      final updated = await ChitGroupApiService.update(result);
      setState(() {
        final idx = _groups.indexWhere((g) => g.id == group.id);
        if (idx != -1) _groups[idx] = updated;
      });
      ToastService.show(
        title: 'Group updated',
        message: updated.name,
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Update failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _confirmDelete(ChitGroup group) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Group',
      message:
          'Are you sure you want to delete "${group.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ChitGroupApiService.delete(group.id);
      setState(() => _groups.removeWhere((g) => g.id == group.id));
      ToastService.show(
        title: 'Group deleted',
        message: group.name,
        type: ToastType.warning,
      );
    } catch (e) {
      ToastService.show(
        title: 'Delete failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // Properly dispose the scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGroups;

    return AppShell(
      currentRoute: AppRoutes.chitGroups,
      title: 'Chit Groups',
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!,
                            style: const TextStyle(color: AppColors.kDanger)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _loadGroups, child: const Text('Retry')),
                      ],
                    ),
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'Manage chit fund groups and member contributions',
                        style: TextStyle(
                            color: AppColors.kTextMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 150,
                          child: ElevatedButton.icon(
                            onPressed: _openCreateDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Group',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _StatCard(
                            icon: Icons.qr_code_2_rounded,
                            iconBg: const Color(0xFFEDE9FE),
                            iconColor: const Color(0xFF7C3AED),
                            label: 'Total Groups',
                            value: '${_groups.length}',
                          ),
                          _StatCard(
                            icon: Icons.trending_up_rounded,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: AppColors.kWarning,
                            label: 'Active Groups',
                            value: '$_activeCount',
                          ),
                          _StatCard(
                            icon: Icons.currency_rupee_rounded,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: AppColors.kSuccess,
                            label: 'Collected',
                            value: formatIndianCurrency(_totalCollected),
                          ),
                          _StatCard(
                            icon: Icons.currency_rupee_rounded,
                            iconBg: const Color(0xFFFEE2E2),
                            iconColor: AppColors.kDanger,
                            label: 'Pending',
                            value: formatIndianCurrency(_totalPending),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search groups...',
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.kTextMuted),
                          filled: true,
                          fillColor: AppColors.kSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.kBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _statusFilter,
                            isExpanded: true,
                            icon: const Icon(Icons.unfold_more_rounded,
                                color: AppColors.kTextMuted),
                            style: const TextStyle(
                                color: AppColors.kTextDark, fontSize: 15),
                            items: const [
                              DropdownMenuItem(
                                  value: 'All Status',
                                  child: Text('All Status')),
                              DropdownMenuItem(
                                  value: 'Active', child: Text('Active')),
                              DropdownMenuItem(
                                  value: 'Completed', child: Text('Completed')),
                              DropdownMenuItem(
                                  value: 'Upcoming', child: Text('Upcoming')),
                            ],
                            onChanged: (v) => setState(
                                () => _statusFilter = v ?? 'All Status'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              'No groups match your search.',
                              style: TextStyle(color: AppColors.kTextMuted),
                            ),
                          ),
                        )
                      else
                        ...filtered.map(
                          (g) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _GroupCard(
                              group: g,
                              onEdit: () => _openEditDialog(g),
                              onDelete: () => _confirmDelete(g),
                              onViewDashboard: () {
                                // TODO: navigate to group Dashboard Route
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// STAT CARD
/// -----------------------------------------------------------------------
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          Text(label,
              style:
                  const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.kTextDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// GROUP CARD
/// -----------------------------------------------------------------------
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDashboard,
  });

  final ChitGroup group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: group.status.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        group.status.label,
                        style: TextStyle(
                          color: group.status.fg,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt_rounded,
                        size: 16, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 4),
                    Text(
                      '${group.totalMembers}',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(group.code,
              style:
                  const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoBlock(
                    label: 'Group Value',
                    value: formatIndianCurrency(group.groupValue)),
              ),
              Expanded(
                child: _InfoBlock(
                    label: 'Monthly',
                    value: formatIndianCurrency(group.monthlyContribution)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoBlock(
                    label: 'Duration', value: '${group.durationMonths} months'),
              ),
              Expanded(
                child: _InfoBlock(
                    label: 'Starts', value: formatDate(group.startDate)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Collected',
                  style: TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
              Text(
                '${group.collectedPercent}%',
                style: const TextStyle(
                  color: AppColors.kTextDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (group.collectedPercent / 100).clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1EFE8),
              valueColor: const AlwaysStoppedAnimation(AppColors.kGold),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onViewDashboard,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('View Dashboard',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              _IconButtonSquare(icon: Icons.edit_outlined, onTap: onEdit),
              const SizedBox(width: 8),
              _IconButtonSquare(
                icon: Icons.delete_outline_rounded,
                color: AppColors.kDanger,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.kTextDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _IconButtonSquare extends StatelessWidget {
  const _IconButtonSquare(
      {required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color ?? AppColors.kTextDark),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// CREATE / EDIT GROUP SHEET
/// Styled to match the bottom-sheet form pattern used in LoansScreen
/// (LoanFormDialog) and the header/close-button treatment from
/// AppEditDialog — rounded top sheet, title + close icon row, labeled
/// fields, and an outlined Cancel / filled Save button pair.
/// -----------------------------------------------------------------------
class _GroupFormDialog extends StatefulWidget {
  const _GroupFormDialog({this.existing});
  final ChitGroup? existing;

  bool get isEdit => existing != null;

  @override
  State<_GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<_GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _membersCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _monthlyCtrl;
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _membersCtrl =
        TextEditingController(text: g != null ? '${g.totalMembers}' : '');
    _durationCtrl =
        TextEditingController(text: g != null ? '${g.durationMonths}' : '');
    _valueCtrl =
        TextEditingController(text: g != null ? '${g.groupValue.round()}' : '');
    _monthlyCtrl = TextEditingController(
        text: g != null ? '${g.monthlyContribution.round()}' : '');
    _startDate = g?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _membersCtrl.dispose();
    _durationCtrl.dispose();
    _valueCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.kGold,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  String? _requiredNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (num.tryParse(v) == null) return 'Enter a valid number';
    return null;
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final result = ChitGroup(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      code: widget.existing?.code ?? _randomCode(),
      name: _nameCtrl.text.trim(),
      status: widget.existing?.status ?? ChitGroupStatus.active,
      totalMembers: int.parse(_membersCtrl.text),
      durationMonths: int.parse(_durationCtrl.text),
      groupValue: double.parse(_valueCtrl.text),
      monthlyContribution: double.parse(_monthlyCtrl.text),
      startDate: _startDate,
      collectedAmount: widget.existing?.collectedAmount ?? 0,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final dd = _startDate.day.toString().padLeft(2, '0');
    final mm = _startDate.month.toString().padLeft(2, '0');
    final yyyy = _startDate.year.toString();

    return Padding(
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
                Expanded(
                  child: Text(
                    widget.isEdit ? 'Edit Group' : 'Create Group',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kTextDark),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;
                return Column(
                  children: [
                    _buildTextField(
                      'GROUP NAME *',
                      'e.g. Lakshmi Chit Fund',
                      controller: _nameCtrl,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _responsiveRow(
                      isNarrow,
                      _buildTextField(
                        'TOTAL MEMBERS *',
                        '',
                        controller: _membersCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: _requiredNumber,
                      ),
                      _buildTextField(
                        'DURATION (MONTHS) *',
                        '',
                        controller: _durationCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: _requiredNumber,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _responsiveRow(
                      isNarrow,
                      _buildTextField(
                        'GROUP VALUE *',
                        '',
                        controller: _valueCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: _requiredNumber,
                      ),
                      _buildTextField(
                        'MONTHLY CONTRIBUTION *',
                        '',
                        controller: _monthlyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: _requiredNumber,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('START DATE *',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.kTextMuted)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(isDense: true),
                            child: Text('$dd/$mm/$yyyy'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleSave,
                  icon: Icon(widget.isEdit
                      ? Icons.check_circle_outline
                      : Icons.add_circle_outline),
                  label: Text(widget.isEdit ? 'Save Changes' : 'Create Group'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _responsiveRow(bool isNarrow, Widget a, Widget b) {
    if (isNarrow) {
      return Column(
        children: [a, const SizedBox(height: 16), b],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
          ),
        ),
      ],
    );
  }
}
