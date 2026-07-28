import 'package:flutter/material.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_badge.dart';
import '../../theme/confirm_dialog.dart';
import '../../theme/glass_toast.dart';
import '../../services/photo_service.dart';
import '../../services/agent_api_service.dart'; 
import '../../services/auth_api_service.dart' show ApiException; 

class AgentManagementScreen extends StatefulWidget {
  const AgentManagementScreen({super.key});

  @override
  State<AgentManagementScreen> createState() => _AgentManagementScreenState();
}

class _AgentManagementScreenState extends State<AgentManagementScreen> {
  String _query = '';
  String _selectedRole = 'Agent';

  final ScrollController _tableScrollController = ScrollController();

  final List<String> _roleFilters = ['Agent', 'Admin', 'Manager', 'All'];

  List<Map<String, dynamic>> _agents = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  // ---- backend mapping ---------------------------------------------------

  Map<String, dynamic> _fromApi(Map<String, dynamic> row) {
    String cap(String? s) {
      if (s == null || s.isEmpty) return '';
      return s[0].toUpperCase() + s.substring(1);
    }

    return {
      'id': row['id']?.toString() ?? '',
      'name': row['full_name'] ?? '',
      'email': row['email'] ?? '',
      'mobile': row['mobile'] ?? '',
      'role': cap(row['role']?.toString()),
      'status': cap(row['status']?.toString()),
      'created': row['created_at'] ?? row['created'] ?? '',
      'address': row['address'] ?? '',
      'aadhaar': row['aadhaar'] ?? '',
      'pan': row['pan'] ?? '',
      'occupation': row['occupation'] ?? '',
      'avatar_url': row['avatar_url'] ?? '',
      'customer_id': row['customer_id'],
      'password': '', 
    };
  }

  Map<String, dynamic> _toApi(Map<String, dynamic> agent) {
    return {
      'full_name': agent['name'],
      'email': agent['email'],
      'mobile': agent['mobile'],
      'password': agent['password'],
      'role': (agent['role'] as String).toLowerCase(),
      'status': (agent['status'] as String).toLowerCase(),
      'address': agent['address'],
      'aadhaar': agent['aadhaar'],
      'pan': agent['pan'],
      'occupation': agent['occupation'],
      'avatar_url': agent['avatar_url'],
      'customer_id': agent['customer_id'],
    };
  }

  Future<void> _loadAgents() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final rows = await AgentApiService.instance.getAgents();
      setState(() {
        _agents = rows.map(_fromApi).toList();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Failed to load agents.';
        _isLoading = false;
      });
    }
  }

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

  void _showAddAgentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: AgentFormDialog(
          onSaved: (newAgent) async {
            try {
              final created =
                  await AgentApiService.instance.createAgent(_toApi(newAgent));
              setState(() => _agents.add(_fromApi(created)));
              if (!mounted) return;
              ToastService.show(
                title: 'Agent created',
                message: '${newAgent['name']} has been added',
                type: ToastType.success,
              );
            } on ApiException catch (e) {
              if (!mounted) return;
              ToastService.show(
                title: 'Could not create agent',
                message: e.message,
                type: ToastType.error,
              );
            }
          },
        ),
      ),
    );
  }

  void _showEditAgentDialog(Map<String, dynamic> agent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: AgentFormDialog(
          agent: agent,
          onSaved: (updated) async {
            try {
              final saved = await AgentApiService.instance
                  .updateAgent(agent['id'] as String, _toApi(updated));
              setState(() {
                final index = _agents.indexWhere((a) => a['id'] == agent['id']);
                if (index != -1) _agents[index] = _fromApi(saved);
              });
              if (!mounted) return;
              ToastService.show(
                title: 'Agent updated',
                message: '${updated['name']} has been updated',
                type: ToastType.success,
              );
            } on ApiException catch (e) {
              if (!mounted) return;
              ToastService.show(
                title: 'Could not update agent',
                message: e.message,
                type: ToastType.error,
              );
            }
          },
        ),
      ),
    );
  }

  void _showDeleteAgentDialog(Map<String, dynamic> agent) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Agent',
      message:
          'Are you sure you want to delete ${agent['name']}? This action cannot be undone.',
      confirmLabel: 'Delete Agent',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true && mounted) {
      try {
        await AgentApiService.instance.deleteAgent(agent['id'] as String);
        setState(() {
          _agents.removeWhere((a) => a['id'] == agent['id']);
        });
        if (!mounted) return;
        ToastService.show(
          title: 'Agent deleted',
          message: '${agent['name']} has been removed',
          type: ToastType.success,
        );
      } on ApiException catch (e) {
        if (!mounted) return;
        ToastService.show(
          title: 'Could not delete agent',
          message: e.message,
          type: ToastType.error,
        );
      }
    }
  }

  BadgeTone _toneFor(String status) {
    switch (status) {
      case 'Active':
        return BadgeTone.success;
      case 'Inactive':
        return BadgeTone.neutral;
      default:
        return BadgeTone.warning;
    }
  }

  List<Map<String, dynamic>> get _filteredAgents => _agents.where((a) {
        final matchesQuery =
            a['name']!.toLowerCase().contains(_query.toLowerCase()) ||
                a['mobile']!.toLowerCase().contains(_query.toLowerCase());
        final matchesRole =
            _selectedRole == 'All' || a['role'] == _selectedRole;
        return matchesQuery && matchesRole;
      }).toList();

  int get _totalAgents => _agents.length;
  int get _activeAgents => _agents.where((a) => a['status'] == 'Active').length;
  int get _inactiveAgents =>
      _agents.where((a) => a['status'] != 'Active').length;
  int get _addedThisMonth => _agents.length; 

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/agents',
      title: 'Agent Management',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;

          if (_isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (_loadError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.kDanger, size: 40),
                    const SizedBox(height: 12),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAgents,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadAgents,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: 'Agent Management',
                    subtitle: 'Add, edit, and manage your collection agents',
                    actions: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 150,
                          child: ElevatedButton.icon(
                            onPressed: _showAddAgentDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Agent'),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildStatsRow(isNarrow),
                  const SizedBox(height: 8),
                  _buildSearchAndFilters(isNarrow),
                  const SizedBox(height: 8),
                  _buildAgentsTable(isNarrow),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    final cards = <Widget>[
      _statCard(
        icon: Icons.shield_outlined,
        iconColor: AppColors.kSuccess,
        iconBg: const Color(0xFFF0FDF4),
        value: '$_totalAgents',
        label: 'Total Agents',
      ),
      _statCard(
        icon: Icons.person_outline,
        iconColor: AppColors.kSuccess,
        iconBg: const Color(0xFFF0FDF4),
        value: '$_activeAgents',
        label: 'Active Agents',
      ),
      _statCard(
        icon: Icons.person_off_outlined,
        iconColor: AppColors.kInfo,
        iconBg: const Color(0xFFF0F5FF),
        value: '$_inactiveAgents',
        label: 'Inactive Agents',
      ),
      _statCard(
        icon: Icons.person_add_alt_outlined,
        iconColor: AppColors.kInfo,
        iconBg: const Color(0xFFF0F5FF),
        value: '$_addedThisMonth',
        label: 'Added This Month',
      ),
    ];

    final horizontalPadding = isNarrow ? 12.0 : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.count(
        crossAxisCount: isNarrow ? 2 : 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: isNarrow ? 12 : 16,
        childAspectRatio: isNarrow ? 1.3 : 1.7,
        children: cards,
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 30,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isNarrow) {
    final searchField = TextField(
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Search by name or mobile...',
        isDense: true,
      ),
      onChanged: (v) => setState(() => _query = v),
    );

    final roleDropdown = DropdownButtonFormField<String>(
      initialValue: _selectedRole,
      decoration: const InputDecoration(isDense: true),
      items: _roleFilters
          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _selectedRole = v);
      },
    );

    if (isNarrow) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 12),
            roleDropdown,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: searchField),
          const SizedBox(width: 16),
          SizedBox(width: 160, child: roleDropdown),
        ],
      ),
    );
  }

  Widget _buildAgentsTable(bool isNarrow) {
    final agents = _filteredAgents;

    if (agents.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12.0 : 24.0, vertical: 32.0),
        child: const Center(
          child: Text(
            'No agents found.',
            style: TextStyle(color: AppColors.kTextMuted),
          ),
        ),
      );
    }

    final table = DataTable(
      columnSpacing: isNarrow ? 20 : 32,
      horizontalMargin: isNarrow ? 12 : 24,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 64,
      headingTextStyle: const TextStyle(
        color: AppColors.kTextMuted,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      columns: const [
        DataColumn(label: Text('USER')),
        DataColumn(label: Text('MOBILE')),
        DataColumn(label: Text('ROLE')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('CREATED')),
        DataColumn(label: Text('ACTIONS')),
      ],
      rows: agents.map((agent) {
        final photoUrl = agent['photo_url'] as String?;
        final agentInitials =
            (agent['name'] as String?)?.trim().isNotEmpty == true
                ? agent['name']!.trim()[0].toUpperCase()
                : 'U';

        return DataRow(cells: [
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.kGold,
                backgroundImage: photoUrl != null
                    ? MemoryImage(base64Decode(photoUrl.split(',').last))
                    : null,
                child: photoUrl == null
                    ? Text(
                        agentInitials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(agent['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(agent['email'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.kTextMuted)),
                ],
              ),
            ],
          )),
          DataCell(Text(agent['mobile'] ?? '')),
          DataCell(StatusBadge(label: agent['role']!, tone: BadgeTone.success)),
          DataCell(StatusBadge(
              label: agent['status']!, tone: _toneFor(agent['status']!))),
          DataCell(Text(agent['created'] ?? '')),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.kTextMuted,
                onPressed: () => _showEditAgentDialog(agent),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.kDanger,
                onPressed: () => _showDeleteAgentDialog(agent),
                tooltip: 'Delete',
              ),
            ],
          )),
        ]);
      }).toList(),
    );

    final scrollController = ScrollController();

    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: isNarrow ? 12.0 : 24.0, vertical: 8.0),
      color: AppColors.kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        notificationPredicate: (notification) => notification.depth == 0,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 4),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: isNarrow ? 720 : 900),
            child: table,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ADD / EDIT AGENT SHEET
// ==========================================
class AgentFormDialog extends StatefulWidget {
  final Map<String, dynamic>? agent;
  final ValueChanged<Map<String, dynamic>>? onSaved;

  const AgentFormDialog({super.key, this.agent, this.onSaved});

  bool get isEdit => agent != null;

  @override
  State<AgentFormDialog> createState() => _AgentFormDialogState();
}

class _AgentFormDialogState extends State<AgentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _photoService = PhotoService();
  String? _photoDataUri;

  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _addressController;
  late final TextEditingController _aadhaarController;
  late final TextEditingController _panController;
  late final TextEditingController _occupationController;

  String _role = 'Agent';
  String _status = 'Active';

  final List<String> _roles = ['Agent', 'Admin', 'Manager'];
  final List<String> _statuses = ['Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    final agent = widget.agent;
    _nameController = TextEditingController(text: agent?['name'] ?? '');
    _mobileController = TextEditingController(text: agent?['mobile'] ?? '');
    _emailController = TextEditingController(text: agent?['email'] ?? '');
    _passwordController = TextEditingController(text: agent?['password'] ?? '');
    _addressController = TextEditingController(text: agent?['address'] ?? '');
    _aadhaarController = TextEditingController(text: agent?['aadhaar'] ?? '');
    _panController = TextEditingController(text: agent?['pan'] ?? '');
    _occupationController =
        TextEditingController(text: agent?['occupation'] ?? '');
    _role = agent?['role'] ?? 'Agent';
    _status = agent?['status'] ?? 'Active';
    _photoDataUri = agent?['avatar_url'] as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final dataUri = await _photoService.pickPhotoAsDataUri();
      if (dataUri != null) setState(() => _photoDataUri = dataUri);
    } catch (e) {
      ToastService.show(
        title: 'Photo upload failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        (!widget.isEdit && _passwordController.text.trim().isEmpty)) {
      ToastService.show(
        title: 'Missing information',
        message: 'Please fill all required fields',
        type: ToastType.error,
      );
      return;
    }

    final updated = <String, dynamic>{
      ...?widget.agent,
      'id': widget.agent?['id'] ?? '',
      'name': _nameController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'role': _role,
      'status': _status,
      'address': _addressController.text.trim(),
      'aadhaar': _aadhaarController.text.trim(),
      'pan': _panController.text.trim(),
      'occupation': _occupationController.text.trim(),
      'avatar_url': _photoDataUri,
      'customer_id': widget.agent?['customer_id'],
      'created': widget.agent?['created'] ?? '',
    };

    widget.onSaved?.call(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : 'U';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isEdit ? 'Edit User' : 'Add User',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextDark),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!widget.isEdit)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 18, color: AppColors.kWarning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Set an email and password so this user can sign in to the app.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.kTextDark),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          _buildTextField('FULL NAME *', 'e.g. Priya Sharma',
              controller: _nameController),
          const SizedBox(height: 16),
          _buildTextField('MOBILE', 'e.g. +91 98765 43210',
              controller: _mobileController),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return _responsiveRow(
                isNarrow,
                _buildTextField('EMAIL *', 'user@rrgroups.in',
                    controller: _emailController),
                _buildTextField('PASSWORD *', 'Min. 6 characters',
                    controller: _passwordController, obscure: true),
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return _responsiveRow(
                isNarrow,
                _buildDropdown('ROLE', _role, _roles,
                    (v) => setState(() => _role = v ?? _role)),
                _buildDropdown('STATUS', _status, _statuses,
                    (v) => setState(() => _status = v ?? _status)),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTextField('ADDRESS', 'Residential address',
              controller: _addressController, maxLines: 3),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return _responsiveRow(
                isNarrow,
                _buildTextField('AADHAAR', '[Aadhaar Redacted]',
                    controller: _aadhaarController),
                _buildTextField('PAN', 'ABCDE1234F',
                    controller: _panController),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTextField('OCCUPATION', 'e.g. Field Executive',
              controller: _occupationController),
          const SizedBox(height: 16),
          const Text('PROFILE PHOTO',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.kGold,
                child: Text(
                  initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Photo'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.isEdit ? 'Save Changes' : 'Create User'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint,
      {required TextEditingController controller,
      bool obscure = false,
      int maxLines = 1}) {
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
          obscureText: obscure,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _responsiveRow(bool isNarrow, Widget w1, Widget w2) {
    if (isNarrow) {
      return Column(
        children: [
          w1,
          const SizedBox(height: 16),
          w2,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: w1),
        const SizedBox(width: 16),
        Expanded(child: w2),
      ],
    );
  }
}