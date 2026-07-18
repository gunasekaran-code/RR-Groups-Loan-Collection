import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/privilege_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../theme/edit_dialog.dart'; // Imported for future/shared styling context
import '../../widgets/app_shell.dart';
import '../../widgets/status_badge.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _DemoUser {
  final String name;
  final String id;
  final String mobile;
  final String role; // 'Owner' | 'Admin' | 'Collection Agent'
  final bool isYou;
  const _DemoUser({
    required this.name,
    required this.id,
    required this.mobile,
    required this.role,
    this.isYou = false,
  });
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // TODO(backend): replace with GET /api/users via ApiService.

  late Map<String, Map<String, bool>> _draftPermissions;
  bool _hasPendingChanges = false;

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
  }

  static const List<_DemoUser> _users = [
    _DemoUser(
        name: 'Rajesh Kumar',
        id: 'OWN-001',
        mobile: '+91 98765 43210',
        role: 'Owner',
        isYou: true),
    _DemoUser(
        name: 'Priya Sharma',
        id: 'ADM-001',
        mobile: '+91 98765 43211',
        role: 'Admin'),
    _DemoUser(
        name: 'Arjun Mehta',
        id: 'AGT-001',
        mobile: '+91 98765 43212',
        role: 'Collection Agent'),
    _DemoUser(
        name: 'Sneha Reddy',
        id: 'AGT-002',
        mobile: '+91 98765 43213',
        role: 'Collection Agent'),
  ];

  static const Map<String, String> _pageLabels = {
    AppRoutes.chitGroups: 'Chit Groups',
    AppRoutes.reports: 'Reports',
    AppRoutes.settings: 'Settings',
  };

  final TextEditingController _searchCtrl = TextEditingController();
  String _roleFilter = 'All Roles';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_DemoUser> get _filteredUsers {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _users.where((u) {
      final matchesQuery = q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.mobile.replaceAll(' ', '').contains(q.replaceAll(' ', ''));
      final matchesRole = _roleFilter == 'All Roles' || u.role == _roleFilter;
      return matchesQuery && matchesRole;
    }).toList();
  }

  int get _totalUsers => _users.length;
  int get _activeUsers => _users.length;
  int get _agentCount =>
      _users.where((u) => u.role == 'Collection Agent').length;
  int get _adminCount => _users.where((u) => u.role == 'Admin').length;

  BadgeTone _roleTone(String role) {
    switch (role) {
      case 'Owner':
        return BadgeTone.warning;
      case 'Admin':
        return BadgeTone.info;
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

  // UPDATED: Refactored to match AppEditDialog's transition styling and bottom layout
  void _showAddUserDialog() {
    showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Add User Dialog',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

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
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;

    return AppShell(
      currentRoute: AppRoutes.userManagement,
      title: 'User Management',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 6),
          const Text(
              'Manage roles, access, and permissions across your organization',
              style: TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 150,
              child: ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text('Add User'),
              ),
            ),
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
                  label: 'Total Users',
                  tint: AppColors.kInfo),
              _StatCard(
                  icon: Icons.verified_user_outlined,
                  value: '$_activeUsers',
                  label: 'Active',
                  tint: AppColors.kSuccess),
              _StatCard(
                  icon: Icons.shield_outlined,
                  value: '$_agentCount',
                  label: 'Agents',
                  tint: AppColors.kSuccess),
              _StatCard(
                  icon: Icons.workspace_premium_outlined,
                  value: '$_adminCount',
                  label: 'Admins',
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
                  decoration: const InputDecoration(
                      hintText: 'Search by name or mobile...',
                      prefixIcon: Icon(Icons.search, size: 20)),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _roleFilter,
                  decoration: const InputDecoration(),
                  items: const [
                    'All Roles',
                    'Owner',
                    'Admin',
                    'Collection Agent'
                  ]
                      .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _roleFilter = v ?? _roleFilter),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppColors.kSurface),
                columnSpacing: 24,
                columns: const [
                  DataColumn(
                      label: Text('USER',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMuted))),
                  DataColumn(
                      label: Text('MOBILE',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMuted))),
                  DataColumn(
                      label: Text('ROLE',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMuted))),
                ],
                rows: [
                  for (final u in _filteredUsers)
                    DataRow(cells: [
                      DataCell(_UserCell(user: u)),
                      DataCell(Text(u.mobile,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.kTextDark))),
                      DataCell(
                          StatusBadge(label: u.role, tone: _roleTone(u.role))),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Permissions Matrix',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextDark)),
          const SizedBox(height: 12),
          const Text(
            'Role-based module access. Click on the tick icons to toggle access for all profiles.',
            style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppColors.kSurface),
                columnSpacing: 28,
                columns: [
                  const DataColumn(
                      label: Text('ROLE',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMuted))),
                  const DataColumn(
                      label: Text('DASHBOARD',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMuted))),
                  for (final label in _pageLabels.values)
                    DataColumn(
                      label: Text(label.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMuted)),
                    ),
                ],
                rows: [
                  _permissionRow(
                    'Owner',
                    dashboard: true,
                    pages: _draftPermissions['Owner']!,
                    editable: true,
                  ),
                  _permissionRow(
                    'Admin',
                    dashboard: true,
                    pages: _draftPermissions['Admin']!,
                    editable: true,
                  ),
                  _permissionRow(
                    'Collection Agent',
                    dashboard: true,
                    pages: _draftPermissions['Collection Agent']!,
                    editable: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_hasPendingChanges)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _draftPermissions = {
                        'Owner': {for (final k in _pageLabels.keys) k: true},
                        'Admin': {
                          for (final k in _pageLabels.keys)
                            k: PrivilegeService.instance.isEnabledForAdmin(k),
                        },
                        'Collection Agent': {
                          for (final k in _pageLabels.keys) k: false
                        },
                      };
                      _hasPendingChanges = false;
                    });
                  },
                  child: const Text('Discard'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    for (final entry in _draftPermissions['Admin']!.entries) {
                      PrivilegeService.instance
                          .setEnabledForAdmin(entry.key, entry.value);
                    }
                    setState(() => _hasPendingChanges = false);
                    ToastService.show(
                      title: 'Permissions saved',
                      message: 'All dynamic role modules updated',
                      type: ToastType.success,
                    );
                  },
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Changes'),
                ),
              ],
            ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}


class _AddUserDialogContent extends StatefulWidget {
  const _AddUserDialogContent();

  @override
  State<_AddUserDialogContent> createState() => _AddUserDialogContentState();
}

class _AddUserDialogContentState extends State<_AddUserDialogContent> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _avatarCtrl;
  String _role = 'Collection Agent';
  String _status = 'Active';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _mobileCtrl = TextEditingController();
    _avatarCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic bottom padding matching AppEditDialog
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
              ? keyboardPadding + 16  // Spacing when keyboard is open
              : safeAreaPadding + 24, // Safe area spacing for iOS home indicator
        ),
        decoration: const BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black87,
          //     blurRadius: 20,
          //     offset: Offset(0, -4),
          //   ),
          // ],
        ),
        child: Column(
          // Changed to Column without wrapping the root inside a ScrollView, 
          // matching _EditDialogContent's structure. Only inner form segments are scrollable if needed.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add User',
                  style: TextStyle(
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

            // Notice banner styled inline with the dialog context
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
                  const Icon(Icons.shield_outlined, size: 18, color: AppColors.kGoldDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: this creates the user profile only. Sign-in access must be '
                      'provisioned on the backend (Laravel + Sanctum) before the account can log in.',
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

            // Scrollable forms fields segment to prevent viewport overflow when keyboard is open
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Full Name Input
                    const _FieldLabel('FULL NAME *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameCtrl,
                      autofocus: true,
                      style: const TextStyle(fontSize: 16, color: AppColors.kTextDark),
                      decoration: InputDecoration(
                        hintText: 'e.g. Priya Sharma',
                        hintStyle: const TextStyle(color: AppColors.kTextMuted),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.kGold, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mobile Input
                    const _FieldLabel('MOBILE'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _mobileCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 16, color: AppColors.kTextDark),
                      decoration: InputDecoration(
                        hintText: 'e.g. +91 98765 43210',
                        hintStyle: const TextStyle(color: AppColors.kTextMuted),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.kGold, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Responsive Dropdowns Block
                    LayoutBuilder(builder: (ctx, constraints) {
                      final narrow = constraints.maxWidth < 340;

                      final roleDropdown = DropdownButtonFormField<String>(
                        value: _role,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const ['Owner', 'Admin', 'Collection Agent']
                            .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r, style: const TextStyle(fontSize: 13, color: AppColors.kTextDark))))
                            .toList(),
                        onChanged: (v) => setState(() => _role = v ?? _role),
                      );

                      final statusDropdown = DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const ['Active', 'Inactive']
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, style: const TextStyle(fontSize: 13, color: AppColors.kTextDark))))
                            .toList(),
                        onChanged: (v) => setState(() => _status = v ?? _status),
                      );

                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('ROLE'),
                            const SizedBox(height: 6),
                            roleDropdown,
                            const SizedBox(height: 14),
                            const _FieldLabel('STATUS'),
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
                                const _FieldLabel('ROLE'),
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
                                const _FieldLabel('STATUS'),
                                const SizedBox(height: 6),
                                statusDropdown,
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 14),

                    // Avatar URL Input
                    const _FieldLabel('AVATAR URL'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _avatarCtrl,
                      style: const TextStyle(fontSize: 16, color: AppColors.kTextDark),
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        hintStyle: const TextStyle(color: AppColors.kTextMuted),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.kGold, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Optional profile image link',
                        style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons matching exact margins & styles from edit_dialog.dart
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'name': _nameCtrl.text.trim(),
                        'mobile': _mobileCtrl.text.trim(),
                        'role': _role,
                        'status': _status,
                        'avatar': _avatarCtrl.text.trim(),
                      });
                      ToastService.show(
                        title: 'Invite user',
                        message: 'Connect backend to enable',
                        type: ToastType.info,
                      );
                    },
                    child: const Text(
                      'Add User',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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

// Keeping the original helper widgets clean and intact below...

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  const _StatCard({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: tint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  color: tint,
                  size: 34,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
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
  final _DemoUser user;
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
            user.name.split(' ').map((p) => p[0]).take(2).join().toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.kTextDark)),
                if (user.isYou) ...[
                  const SizedBox(width: 6),
                  const Text('You',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                ],
              ],
            ),
            Text(user.id,
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
