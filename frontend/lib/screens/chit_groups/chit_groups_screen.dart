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
import '../../services/session_service.dart';
import 'package:intl/intl.dart';

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

  UserRole? get _role => SessionService.instance.role;
  bool get _isAdmin => _role == UserRole.admin || _role == UserRole.owner;
  bool get _isAgent => _role == UserRole.agent;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _openGroupDetails(ChitGroup group) async {
    final updated = await showChitGroupDetailsSheet(context, group);
    if (updated != null && mounted) {
      await _loadGroups();
    }
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
        title: 'Failed to load chit groups',
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
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Chit Group',
      message: 'Delete "${group.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true || !mounted) return;
    try {
      await ChitGroupApiService.delete(group.id);
      if (!mounted) return;
      await _loadGroups();
      ToastService.show(
        title: 'Group deleted',
        message: '${group.name} was removed',
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
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.chitGroups,
      title: 'Chit Groups',
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: RefreshIndicator(
          onRefresh: _loadGroups,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(
                title: 'Chit Groups',
                subtitle: 'View and manage chit group collections',
                actions: [
                  if (_isAdmin)
                    ElevatedButton.icon(
                      onPressed: _showCreateGroupModal,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Group'),
                    ),
                ],
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
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else if (_groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No chit groups found.')),
                )
              else
                ..._groups.map((group) => _buildGroupCard(group)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(ChitGroup group) {
    return GestureDetector(
      onTap: () => _openGroupDetails(group),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(group.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextDark)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: group.status == ChitGroupStatus.active
                        ? AppColors.kSuccess.withOpacity(0.15)
                        : AppColors.kTextMuted.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    group.status.name.toUpperCase(),
                    style: TextStyle(
                      color: group.status == ChitGroupStatus.active
                          ? AppColors.kSuccess
                          : AppColors.kTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Group No.: ${group.code}',
                style: const TextStyle(color: AppColors.kTextMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Members: ${group.totalMembers}')),
                Expanded(child: Text('Duration: ${group.durationMonths} mo')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: Text(
                        'Value: ${formatIndianCurrency(group.groupValue)}')),
                Expanded(
                    child: Text(
                        'Collected: ${formatIndianCurrency(group.collectedAmount)}')),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (group.collectedPercent / 100).clamp(0, 1).toDouble(),
              backgroundColor: const Color(0xFFEEEDE9),
              valueColor: const AlwaysStoppedAnimation(AppColors.kGold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_isAdmin || _isAgent)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _openGroupDetails(group),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.currency_rupee, size: 16),
                      label: const Text('Collect'),
                    ),
                  ),
                if (_isAdmin) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.kTextDark),
                    onPressed: () => _showEditGroupModal(group),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.kDanger),
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

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _nameCtrl = TextEditingController(text: group?.name ?? '');
    _codeCtrl = TextEditingController(text: group?.code ?? '');
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
    if (group != null) _status = group.status;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _membersCtrl.dispose();
    _durationCtrl.dispose();
    _valueCtrl.dispose();
    _contributionCtrl.dispose();
    _startDateCtrl.dispose();
    super.dispose();
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
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) return;

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
      if (!mounted) return;
      Navigator.of(context).pop(result);
      ToastService.show(
        title: widget.group == null ? 'Group created' : 'Group updated',
        message: group.name,
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ToastService.show(
        title: 'Save failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        isEditing ? 'Edit Group' : 'Create Group',
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
                  const Text('GROUP NAME *',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(isDense: true),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('GROUP NUMBER *',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(isDense: true),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MEMBERS *',
                                style: TextStyle(
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
                                  return 'Required';
                                if (int.tryParse(v.trim()) == null)
                                  return 'Enter a number';
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
                            const Text('DURATION (mo) *',
                                style: TextStyle(
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
                                  return 'Required';
                                if (int.tryParse(v.trim()) == null)
                                  return 'Enter a number';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('GROUP VALUE *',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null)
                        return 'Enter a number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('MONTHLY CONTRIBUTION *',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _contributionCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null)
                        return 'Enter a number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('START DATE *',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _startDateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(isDense: true),
                    onTap: _pickStartDate,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('STATUS *',
                      style: TextStyle(
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
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
                            : Text(isEditing ? 'Save Changes' : 'Create Group'),
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

  UserRole? get _role => SessionService.instance.role;

  bool get _canAddOrDeleteMembers =>
      _role == UserRole.admin || _role == UserRole.owner;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadMembers();
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
      title: 'Member added',
      message: added.memberName,
      type: ToastType.success,
    );
  }

  Future<void> _confirmDeleteMember(ChitMember member) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Remove Member',
      message: 'Remove "${member.memberName}" from this group?',
      confirmLabel: 'Remove',
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
        title: 'Member removed',
        message: member.memberName,
        type: ToastType.warning,
      );
    } catch (e) {
      ToastService.show(
        title: 'Remove failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _collect(ChitMember member) async {
    final amountCtrl = TextEditingController(
        text: member.contributionAmount.round().toString());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Collection'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Amount Collected'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final amount =
        double.tryParse(amountCtrl.text) ?? member.contributionAmount;

    try {
      final updatedMember = await ChitGroupApiService.collectFromMember(
        memberId: member.id,
        status: ChitPaymentStatus.paid,
      );

      final newCollected = _group.collectedAmount + amount;
      final newPending = (_group.groupValue - newCollected)
          .clamp(0, _group.groupValue)
          .toDouble();
      final newStatus = newPending <= 0 ? 'closed' : 'active';

      final updatedGroup = await ChitGroupApiService.recordCollection(
        groupId: _group.id,
        collectedAmount: newCollected,
        pendingAmount: newPending,
        status: newStatus,
      );

      if (!mounted) return;
      setState(() {
        final idx = _members.indexWhere((m) => m.id == member.id);
        if (idx != -1) _members[idx] = updatedMember;
        _group = updatedGroup;
        _changed = true;
      });
      ToastService.show(
        title: 'Collection recorded',
        message: '${member.memberName} · ${formatIndianCurrency(amount)}',
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Collection failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                    child: const Text('Retry')),
                              ],
                            )
                          : _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _DetailStat(label: 'Group No.', value: _group.code)),
            Expanded(
                child: _DetailStat(
                    label: 'Members', value: '${_group.totalMembers}')),
            Expanded(
                child: _DetailStat(
                    label: 'Value',
                    value: formatIndianCurrency(_group.groupValue))),
            Expanded(
                child: _DetailStat(
                    label: 'Duration', value: '${_group.durationMonths} mo')),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F8F4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Collection Progress',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${formatIndianCurrency(_group.collectedAmount)} / ${formatIndianCurrency(_group.groupValue)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (_group.collectedPercent / 100).clamp(0, 1).toDouble(),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1EFE8),
                  valueColor: const AlwaysStoppedAnimation(AppColors.kGold),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Dot(color: AppColors.kSuccess),
                  const SizedBox(width: 6),
                  Text(
                      'Collected ${formatIndianCurrency(_group.collectedAmount)}',
                      style: const TextStyle(
                          color: AppColors.kSuccess, fontSize: 13)),
                  const SizedBox(width: 16),
                  _Dot(color: AppColors.kDanger),
                  const SizedBox(width: 6),
                  Text('Pending ${formatIndianCurrency(_group.pendingAmount)}',
                      style: const TextStyle(
                          color: AppColors.kDanger, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Member Collection Tracking',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (_canAddOrDeleteMembers)
              TextButton.icon(
                onPressed: _openAddMember,
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Add Member'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_members.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No members yet.',
                  style: TextStyle(color: AppColors.kTextMuted)),
            ),
          )
        else
          ..._members.map((m) => _MemberRow(
                member: m,
                canDelete: _canAddOrDeleteMembers,
                onCollect: m.status == ChitPaymentStatus.paid
                    ? null
                    : () => _collect(m),
                onDelete: () => _confirmDeleteMember(m),
              )),
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
      ToastService.show(
        title: 'Select a customer',
        message: 'Choose a customer to add to this group.',
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
        title: 'Add member failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      const Text('Add Member',
                          style: TextStyle(
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
                  const Text('CUSTOMER *',
                      style: TextStyle(
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
                                    child: const Text('Retry')),
                              ],
                            )
                          : DropdownButtonFormField<ChitCustomerOption>(
                              value: _selectedCustomer,
                              isExpanded: true,
                              decoration: const InputDecoration(isDense: true),
                              hint: const Text('Select a customer...'),
                              items: _customers
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c.name,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCustomer = v),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                  const SizedBox(height: 16),
                  const Text('CONTRIBUTION AMOUNT',
                      style: TextStyle(
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
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (num.tryParse(v) == null)
                        return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Defaults to ${formatIndianCurrency(widget.group.monthlyContribution)}',
                    style: const TextStyle(
                        color: AppColors.kTextMuted, fontSize: 12),
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
                        onPressed: _saving ? null : _handleSave,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.person_add_alt_1),
                        label: const Text('Add Member'),
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
