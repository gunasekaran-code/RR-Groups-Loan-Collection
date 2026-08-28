import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/privilege_service.dart';
import '../../services/user_api_service.dart';
import '../../models/user_account.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../theme/edit_dialog.dart'; // Imported for future/shared styling context
import '../../widgets/app_shell.dart';
import '../../widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Map<String, Map<String, bool>> _draftPermissions;
  bool _hasPendingChanges = false;

  List<UserAccount> _users = [];
  bool _loading = true;
  String? _loadError;

  static const Map<String, String> _pageLabels = {
    AppRoutes.chitGroups: 'Chit Groups',
    AppRoutes.reports: 'Reports',
    AppRoutes.settings: 'Settings',
  };

  final TextEditingController _searchCtrl = TextEditingController();
  // Canonical role code; 'all' means no filter. Kept locale-independent so
  // switching languages doesn't break an already-selected filter.
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _draftPermissions = {
      'Owner': {for (final k in _pageLabels.keys) k: true},
      'Admin': {
        for (final k in _pageLabels.keys)
          k: PrivilegeService.instance.isEnabledForAdmin(k),
      },
      'Collection Agent': {for (final k in _pageLabels.keys) k: false},
    };
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final users = await UserApiService.instance.fetchUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e is UserApiException
            ? e.message
            : AppLocalizations.of(context).failedToLoadUsers;
        _loading = false;
      });
    }
  }

  Future<void> _createUser(UserAccount draft, String password) async {
    final l10n = AppLocalizations.of(context);
    try {
      final created =
          await UserApiService.instance.createUser(draft, password: password);
      if (!mounted) return;
      setState(() => _users = [..._users, created]);
      ToastService.show(
        title: l10n.userCreatedToastTitle,
        message: l10n.userCreatedToastMessage(created.fullName),
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: l10n.couldNotCreateUserToastTitle,
        message: e is UserApiException ? e.message : l10n.somethingWentWrong,
        type: ToastType.error,
      );
    }
  }

  Future<void> _updateUser(UserAccount user, {String? password}) async {
    final l10n = AppLocalizations.of(context);
    try {
      final updated =
          await UserApiService.instance.updateUser(user, password: password);
      if (!mounted) return;
      setState(() {
        _users = _users.map((u) => u.id == updated.id ? updated : u).toList();
      });
      ToastService.show(
        title: l10n.userUpdatedToastTitle,
        message: l10n.userUpdatedToastMessage(updated.fullName),
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: l10n.couldNotUpdateUserToastTitle,
        message: e is UserApiException ? e.message : l10n.somethingWentWrong,
        type: ToastType.error,
      );
    }
  }

  Future<void> _deleteUser(UserAccount user) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeUserDialogTitle),
        content: Text(l10n.removeUserDialogMessage(user.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.remove,
                style: const TextStyle(color: AppColors.kDanger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await UserApiService.instance.deleteUser(user.id);
      if (!mounted) return;
      setState(() => _users = _users.where((u) => u.id != user.id).toList());
      ToastService.show(
        title: l10n.userRemovedToastTitle,
        message: l10n.userRemovedToastMessage(user.fullName),
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: l10n.couldNotDeleteUserToastTitle,
        message: e is UserApiException ? e.message : l10n.somethingWentWrong,
        type: ToastType.error,
      );
    }
  }

  List<UserAccount> get _filteredUsers {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _users.where((u) {
      final matchesQuery = q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          (u.mobile ?? '').replaceAll(' ', '').contains(q.replaceAll(' ', ''));
      final matchesRole = _roleFilter == 'all' || u.role == _roleFilter;
      return matchesQuery && matchesRole;
    }).toList();
  }

  int get _totalUsers => _users.length;
  int get _activeUsers => _users.where((u) => u.status == 'active').length;
  int get _agentCount => _users.where((u) => u.role == 'agent').length;
  int get _adminCount => _users.where((u) => u.role == 'admin').length;

  String _roleLabel(String role) {
    final l10n = AppLocalizations.of(context);
    switch (role) {
      case 'admin':
        return l10n.roleAdmin;
      case 'customer':
        return l10n.roleCustomer;
      default:
        return l10n.roleCollectionAgent;
    }
  }

  BadgeTone _roleTone(String role) {
    switch (role) {
      case 'admin':
        return BadgeTone.info;
      case 'customer':
        return BadgeTone.warning;
      default:
        return BadgeTone.success;
    }
  }

  Widget _permissionIcon(bool enabled) {
    return Icon(
      enabled ? Icons.check_circle : Icons.cancel_outlined,
      size: 20,
      color:
          enabled ? AppColors.kSuccess : AppColors.kTextMuted.withOpacity(0.35),
    );
  }

  DataRow _permissionRow(
    String role, {
    required bool dashboard,
    required Map<String, bool> pages,
    required bool editable,
  }) {
    return DataRow(cells: [
      DataCell(Text(role,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.kTextDark))),
      DataCell(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: _permissionIcon(dashboard),
      )),
      for (final key in _pageLabels.keys)
        DataCell(
          editable
              ? InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    setState(() {
                      _draftPermissions[role]![key] =
                          !(_draftPermissions[role]![key] ?? false);
                      _hasPendingChanges = true;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: _permissionIcon(pages[key] ?? false),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _permissionIcon(pages[key] ?? false),
                ),
        ),
    ]);
  }

  // ---------------- Dialogs ----------------

  void _showAddUserDialog() {
    showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context).dismissAddUserDialogLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: const Align(
            alignment: Alignment.bottomCenter,
            child: _AddUserDialogContent(),
          ),
        );
      },
    ).then((result) {
      if (result == null) return;
      final draft = UserAccount(
        id: '',
        fullName: result['name'] as String,
        email: result['email'] as String,
        mobile: (result['mobile'] as String).isEmpty
            ? null
            : result['mobile'] as String,
        role: result['role'] as String,
        status: (result['status'] as String).toLowerCase(),
        avatarUrl: (result['avatar'] as String).isEmpty
            ? null
            : result['avatar'] as String,
      );
      _createUser(draft, result['password'] as String);
    });
  }

  void _showEditUserDialog(UserAccount user) {
    showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context).dismissEditUserDialogLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _AddUserDialogContent(existing: user),
          ),
        );
      },
    ).then((result) {
      if (result == null) return;
      final updated = user.copyWith(
        fullName: result['name'] as String,
        email: result['email'] as String,
        mobile: (result['mobile'] as String).isEmpty
            ? null
            : result['mobile'] as String,
        role: result['role'] as String,
        status: (result['status'] as String).toLowerCase(),
        avatarUrl: (result['avatar'] as String).isEmpty
            ? null
            : result['avatar'] as String,
      );
      final password = result['password'] as String;
      _updateUser(updated, password: password.isEmpty ? null : password);
    });
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;

    return AppShell(
      currentRoute: AppRoutes.userManagement,
      title: l10n.userManagementScreenTitle,
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 6),
            Text(l10n.userManagementSubtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddUserDialog(),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: Text(l10n.addUser),
                  ),
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: l10n.refreshTooltip,
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadUsers,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: width < 420 ? 2 : (isWide ? 4 : 2),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(
                    icon: Icons.manage_accounts_outlined,
                    value: '$_totalUsers',
                    label: l10n.statTotalUsers,
                    tint: AppColors.kInfo),
                _StatCard(
                    icon: Icons.verified_user_outlined,
                    value: '$_activeUsers',
                    label: l10n.statActive,
                    tint: AppColors.kSuccess),
                _StatCard(
                    icon: Icons.shield_outlined,
                    value: '$_agentCount',
                    label: l10n.statAgents,
                    tint: AppColors.kSuccess),
                _StatCard(
                    icon: Icons.workspace_premium_outlined,
                    value: '$_adminCount',
                    label: l10n.statAdmins,
                    tint: AppColors.kInfo),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.kBorder)),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                        hintText: l10n.searchByNameOrMobileHint,
                        prefixIcon: const Icon(Icons.search, size: 20)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _roleFilter,
                    decoration: const InputDecoration(),
                    items: {
                      'all': l10n.roleAll,
                      'admin': l10n.roleAdmin,
                      'agent': l10n.roleCollectionAgent,
                      'customer': l10n.roleCustomer,
                    }
                        .entries
                        .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value,
                                style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _roleFilter = v ?? _roleFilter),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              _ErrorState(message: _loadError!, onRetry: _loadUsers)
            else if (_filteredUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(l10n.noUsersFound,
                      style: const TextStyle(color: AppColors.kTextMuted)),
                ),
              )
            else
              _SectionCard(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(AppColors.kSurface),
                    columnSpacing: 24,
                    columns: [
                      DataColumn(
                          label: Text(l10n.tableColumnUser,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kTextMuted))),
                      DataColumn(
                          label: Text(l10n.tableColumnMobile,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kTextMuted))),
                      DataColumn(
                          label: Text(l10n.tableColumnRole,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kTextMuted))),
                      DataColumn(
                          label: Text(l10n.tableColumnStatus,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kTextMuted))),
                      const DataColumn(label: SizedBox.shrink()),
                    ],
                    rows: [
                      for (final u in _filteredUsers)
                        DataRow(cells: [
                          DataCell(_UserCell(user: u)),
                          DataCell(Text(u.mobile ?? '—',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.kTextDark))),
                          DataCell(StatusBadge(
                              label: _roleLabel(u.role),
                              tone: _roleTone(u.role))),
                          DataCell(StatusBadge(
                              label: u.status == 'active'
                                  ? l10n.statusActive
                                  : l10n.statusInactive,
                              tone: u.status == 'active'
                                  ? BadgeTone.success
                                  : BadgeTone.warning)),
                          DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: u.role == 'admin' ? l10n.adminCannotBeEditedTooltip : l10n.edit,
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: u.role == 'admin' ? AppColors.kTextMuted.withOpacity(0.35) : AppColors.kTextDark,
                              ),
                              onPressed: u.role == 'admin' ? null : () => _showEditUserDialog(u),
                            ),
                            IconButton(
                              tooltip: u.role == 'admin' ? l10n.adminCannotBeDeletedTooltip : l10n.delete,
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: u.role == 'admin' ? AppColors.kDanger.withOpacity(0.35) : AppColors.kDanger,
                              ),
                              onPressed: u.role == 'admin' ? null : () => _deleteUser(u),
                            ),
                          ],
                        )),
                        ]),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.kDanger, size: 28),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.kTextMuted)),
          const SizedBox(height: 12),
          OutlinedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry)),
        ],
      ),
    );
  }
}

class _AddUserDialogContent extends StatefulWidget {
  final UserAccount? existing;
  const _AddUserDialogContent({this.existing});

  @override
  State<_AddUserDialogContent> createState() => _AddUserDialogContentState();
}

class _AddUserDialogContentState extends State<_AddUserDialogContent> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _avatarCtrl;
  late final TextEditingController _passwordCtrl;
  // Canonical codes ('admin'/'agent'/'customer', 'active'/'inactive'), kept
  // locale-independent; only the dropdown display text is localized.
  String _role = 'agent';
  String _status = 'active';
  bool _submitting = false;
  String? _formError;

  bool get _isEdit => widget.existing != null;

  Map<String, String> _roleOptions(AppLocalizations l10n) => {
        'admin': l10n.roleAdmin,
        'agent': l10n.roleCollectionAgent,
        'customer': l10n.roleCustomer,
      };

  Map<String, String> _statusOptions(AppLocalizations l10n) => {
        'active': l10n.statusActive,
        'inactive': l10n.statusInactive,
      };

  @override
  void initState() {
    super.initState();
    final u = widget.existing;
    _nameCtrl = TextEditingController(text: u?.fullName ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _mobileCtrl = TextEditingController(text: u?.mobile ?? '');
    _avatarCtrl = TextEditingController(text: u?.avatarUrl ?? '');
    _passwordCtrl = TextEditingController();
    if (u != null) {
      _role = (u.role == 'admin' || u.role == 'customer') ? u.role : 'agent';
      _status = u.status == 'active' ? 'active' : 'inactive';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _avatarCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty) {
      setState(() => _formError = l10n.fullNameRequiredError);
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _formError = l10n.validEmailRequiredError);
      return;
    }
    if (!_isEdit && password.length < 6) {
      setState(() => _formError = l10n.passwordMinLengthError);
      return;
    }
    if (_isEdit && password.isNotEmpty && password.length < 6) {
      setState(() => _formError = l10n.passwordMinLengthError);
      return;
    }

    Navigator.pop(context, {
      'name': name,
      'email': email,
      'mobile': _mobileCtrl.text.trim(),
      'role': _role,
      'status': _status,
      'avatar': _avatarCtrl.text.trim(),
      'password': password,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final double safeAreaPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: 32,
          left: 24,
          right: 24,
          bottom: keyboardPadding > 0
              ? keyboardPadding + 16
              : safeAreaPadding + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEdit ? l10n.editUserDialogTitle : l10n.addUser,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextDark,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.kGoldLight.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.kGoldDark.withOpacity(0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 18, color: AppColors.kGoldDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEdit
                          ? l10n.editPasswordHintNote
                          : l10n.addUserBackendNote,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.kTextDark.withOpacity(0.85),
                          height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_formError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.kDanger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_formError!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.kDanger)),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _FieldLabel(l10n.fullNameFieldLabel),
                    const SizedBox(height: 6),
                    _buildField(_nameCtrl, l10n.fullNameFieldHint),
                    const SizedBox(height: 14),

                    _FieldLabel(l10n.emailFieldLabel),
                    const SizedBox(height: 6),
                    _buildField(_emailCtrl, l10n.emailFieldHint,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),

                    _FieldLabel(_isEdit
                        ? l10n.newPasswordOptionalLabel
                        : l10n.passwordFieldLabel),
                    const SizedBox(height: 6),
                    _buildField(
                        _passwordCtrl,
                        _isEdit
                            ? l10n.passwordLeaveBlankHint
                            : l10n.passwordMinCharsHint,
                        obscure: true),
                    const SizedBox(height: 14),

                    _FieldLabel(l10n.mobileFieldLabel),
                    const SizedBox(height: 6),
                    _buildField(_mobileCtrl, l10n.mobileFieldHint,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),

                    LayoutBuilder(builder: (ctx, constraints) {
                      final narrow = constraints.maxWidth < 340;

                      final roleDropdown = DropdownButtonFormField<String>(
                        initialValue: _role,
                        decoration: _dropdownDecoration(),
                        items: _roleOptions(l10n)
                            .entries
                            .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.kTextDark))))
                            .toList(),
                        onChanged: (v) => setState(() => _role = v ?? _role),
                      );

                      final statusDropdown = DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: _dropdownDecoration(),
                        items: _statusOptions(l10n)
                            .entries
                            .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.kTextDark))))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _status = v ?? _status),
                      );

                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(l10n.roleFieldLabel),
                            const SizedBox(height: 6),
                            roleDropdown,
                            const SizedBox(height: 14),
                            _FieldLabel(l10n.statusFieldLabel),
                            const SizedBox(height: 6),
                            statusDropdown,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FieldLabel(l10n.roleFieldLabel),
                                const SizedBox(height: 6),
                                roleDropdown,
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FieldLabel(l10n.statusFieldLabel),
                                const SizedBox(height: 6),
                                statusDropdown,
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 14),

                    _FieldLabel(l10n.avatarUrlFieldLabel),
                    const SizedBox(height: 6),
                    _buildField(_avatarCtrl, l10n.avatarUrlFieldHint),
                    const SizedBox(height: 4),
                    Text(l10n.avatarUrlHelperText,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context, null),
                    child: Text(l10n.cancel,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _submit,
                    child: Text(_isEdit ? l10n.saveChanges : l10n.addUser,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType, bool obscure = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontSize: 16, color: AppColors.kTextDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.kTextMuted),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kGold, width: 1.5),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: tint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, color: tint, size: 34),
              ),
            ],
          ),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: child,
    );
  }
}

class _UserCell extends StatelessWidget {
  final UserAccount user;
  const _UserCell({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.kGold,
          child: Text(
            user.fullName
                .trim()
                .split(RegExp(r'\s+'))
                .where((p) => p.isNotEmpty)
                .map((p) => p[0])
                .take(2)
                .join()
                .toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.fullName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.kTextDark)),
            Text(user.email,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.kTextMuted,
          letterSpacing: 0.3),
    );
  }
}