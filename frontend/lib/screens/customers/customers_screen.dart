import 'dart:convert';
import 'dart:typed_data';
import '../../theme/app_theme.dart';
import '../../models/customer.dart';
import '../../routes/app_routes.dart';
import '../../theme/glass_toast.dart';
import '../../widgets/app_shell.dart';
import 'package:flutter/material.dart';
import '../../widgets/page_header.dart';
import '../../theme/confirm_dialog.dart';
import '../../services/photo_service.dart';
import '../../services/location_service.dart';
import '../../services/customer_api_service.dart';


class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _api = CustomerApiService();

  String _query = '';
  String _statusFilter = 'All Status';

  bool _loading = true;
  String? _error;
  List<Customer> _customers = [];
  List<AgentOption> _agents = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadAgents();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final customers = await _api.fetchAll();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      ToastService.show(
        title: 'Failed to load customers',
        message: _error!,
        type: ToastType.error,
      );
    }
  }

  Future<void> _loadAgents() async {
    try {
      final agents = await _api.fetchAgents();
      if (!mounted) return;
      setState(() => _agents = agents);
    } catch (e) {
      // Non-fatal: form still works, just without an agent list.
      debugPrint('Failed to load agents: $e');
    }
  }

  // Maps the SQL enum ('none'|'active'|'overdue'|'closed') to your filter labels.
  String _statusLabel(String loanStatus) {
    switch (loanStatus) {
      case 'active':
        return 'Active';
      case 'overdue':
        return 'Overdue';
      case 'closed':
        return 'Inactive';
      default:
        return 'Active';
    }
  }

  void _viewCustomer(Customer c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(child: _CustomerViewSheet(customer: c)),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCustomer(Customer c) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Customer',
      message: 'Are you sure you want to delete ${c.fullName}? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true || !mounted) return;

    try {
      await _api.delete(c.id);
      if (!mounted) return;
      // Re-fetch from the database instead of trusting a local removeWhere.
      await _loadCustomers();
      if (!mounted) return;
      ToastService.show(
        title: 'Customer deleted',
        message: '${c.fullName} was removed successfully',
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Delete failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  void _showCustomerFormModal({Customer? existingCustomer}) {
    final isEditing = existingCustomer != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: _CustomerForm(
                initialData: existingCustomer,
                agents: _agents,
                onSave: (updated, email, password) async {
                  try {
                    if (isEditing) {
                      await _api.update(
                        existingCustomer.id,
                        updated,
                        email: email,
                        password: password,
                      );
                    } else {
                      await _api.create(updated, email: email, password: password);
                    }
                    if (!mounted) return;
                    // Re-fetch the full list from the database instead of
                    // splicing the returned object into local state.
                    await _loadCustomers();
                    if (!mounted) return;
                    Navigator.pop(context);
                    ToastService.show(
                      title: isEditing ? 'Customer updated' : 'Customer added',
                      message: isEditing
                          ? '${updated.fullName} was updated successfully'
                          : '${updated.fullName} was added successfully',
                      type: ToastType.success,
                    );
                  } catch (e) {
                    ToastService.show(
                      title: 'Something went wrong',
                      message: e.toString(),
                      type: ToastType.error,
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _customers.where((c) {
      final matchesName = c.fullName.toLowerCase().contains(_query.toLowerCase());
      final matchesStatus =
          _statusFilter == 'All Status' || _statusLabel(c.loanStatus) == _statusFilter;
      return matchesName && matchesStatus;
    }).toList();

    return AppShell(
      currentRoute: AppRoutes.customers,
      title: 'Customers',
      body: Container(
        color: AppColors.kBackground,
        child: RefreshIndicator(
          onRefresh: _loadCustomers,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(
                title: 'Customers',
                subtitle: 'Manage customer information and details',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ToastService.show(
                        title: 'Export started',
                        message: 'Preparing your customer list',
                        type: ToastType.info,
                      );
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showCustomerFormModal(),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text('Add Customer'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        hintText: 'Search by name...',
                        prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.kBorder),
                        color: AppColors.kSurface,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _statusFilter,
                          icon: const Icon(Icons.unfold_more, size: 20, color: AppColors.kTextMuted),
                          items: ['All Status', 'Active', 'Overdue', 'Inactive']
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s, style: const TextStyle(color: AppColors.kTextDark)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _statusFilter = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Text(_error!, style: const TextStyle(color: AppColors.kDanger)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _loadCustomers, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text('No customers found')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return _CustomerCard(
                      customer: c,
                      statusLabel: _statusLabel(c.loanStatus),
                      onView: () => _viewCustomer(c),
                      onEdit: () => _showCustomerFormModal(existingCustomer: c),
                      onDelete: () => _deleteCustomer(c),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOMER VIEW SHEET
// ---------------------------------------------------------

class _CustomerViewSheet extends StatelessWidget {
  final Customer customer;
  const _CustomerViewSheet({required this.customer});

  @override
  Widget build(BuildContext context) {
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
                customer.fullName,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.kTextDark),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildViewField('CUSTOMER ID', customer.customerId),
          _buildViewField('MOBILE', customer.mobile),
          _buildViewField('ADDRESS', customer.address),
          _buildViewField('AADHAAR', customer.aadhaar),
          _buildViewField('PAN', customer.pan),
          _buildViewField('OCCUPATION', customer.occupation),
          _buildViewField('ASSIGNED AGENT', customer.assignedAgentName ?? customer.assignedAgent),
          _buildViewField('LOAN STATUS', customer.loanStatus),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kTextMuted)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.kBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Text(value ?? '-', style: const TextStyle(color: AppColors.kTextDark, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOMER CARD
// ---------------------------------------------------------

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final String statusLabel;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.statusLabel,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = statusLabel == 'Active';
    final badgeColor = isActive ? AppColors.kSuccess.withOpacity(0.1) : AppColors.kDanger.withOpacity(0.1);
    final badgeTextColor = isActive ? AppColors.kSuccess : AppColors.kDanger;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.kGold,
                child: Text(
                  _getInitials(customer.fullName),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.fullName,
                        style: const TextStyle(
                            color: AppColors.kTextDark, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(customer.customerId,
                        style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                child: Text(statusLabel,
                    style: TextStyle(color: badgeTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _DetailItem(icon: Icons.phone_outlined, text: customer.mobile ?? '-')),
              Expanded(child: _DetailItem(icon: Icons.location_on_outlined, text: customer.address ?? '-')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _DetailItem(icon: Icons.credit_card_outlined, text: customer.aadhaar ?? '-')),
              Expanded(
                  child: _DetailItem(
                      icon: Icons.business_center_outlined,
                      text: customer.assignedAgentName ?? customer.assignedAgent ?? 'Unassigned')),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(icon: Icons.visibility_outlined, label: 'View', color: AppColors.kInfo, onTap: onView),
              _ActionButton(icon: Icons.edit_outlined, label: 'Edit', color: AppColors.kGoldDark, onTap: onEdit),
              _ActionButton(icon: Icons.delete_outline, label: 'Delete', color: AppColors.kDanger, onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.kTextMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: AppColors.kTextDark, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.kTextDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: activeColor),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: activeColor, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOMER FORM (ADD & EDIT) — single definition
// ---------------------------------------------------------

class _CustomerForm extends StatefulWidget {
  final Customer? initialData;
  final List<AgentOption> agents;
  final void Function(Customer updated, String? email, String? password) onSave;

  const _CustomerForm({
    this.initialData,
    required this.agents,
    required this.onSave,
  });

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _locationService = LocationService();
  final _photoService = PhotoService();

  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _aadhaarCtrl;
  late TextEditingController _panCtrl;
  late TextEditingController _occupationCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;

  String? _assignedAgentId;
  String? _photoDataUri;
  bool _locationBusy = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nameCtrl = TextEditingController(text: d?.fullName ?? '');
    _mobileCtrl = TextEditingController(text: d?.mobile ?? '');
    _addressCtrl = TextEditingController(text: d?.address ?? '');
    _aadhaarCtrl = TextEditingController(text: d?.aadhaar ?? '');
    _panCtrl = TextEditingController(text: d?.pan ?? '');
    _occupationCtrl = TextEditingController(text: d?.occupation ?? '');
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _latCtrl = TextEditingController(text: d?.latitude?.toString() ?? '');
    _lngCtrl = TextEditingController(text: d?.longitude?.toString() ?? '');
    _assignedAgentId = d?.assignedAgent;
    _photoDataUri = d?.photoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
    _occupationCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _pinFromAddress() async {
    setState(() => _locationBusy = true);
    try {
      final result = await _locationService.geocodeAddress(_addressCtrl.text);
      setState(() {
        _latCtrl.text = result.latitude.toStringAsFixed(7);
        _lngCtrl.text = result.longitude.toStringAsFixed(7);
      });
    } catch (e) {
      ToastService.show(title: "Couldn't find that address", message: e.toString(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  Future<void> _useMyGps() async {
    setState(() => _locationBusy = true);
    try {
      final result = await _locationService.getCurrentPosition();
      setState(() {
        _latCtrl.text = result.latitude.toStringAsFixed(7);
        _lngCtrl.text = result.longitude.toStringAsFixed(7);
      });
    } catch (e) {
      ToastService.show(title: "Couldn't get your location", message: e.toString(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final dataUri = await _photoService.pickPhotoAsDataUri();
      if (dataUri != null) setState(() => _photoDataUri = dataUri);
    } catch (e) {
      ToastService.show(title: 'Photo upload failed', message: e.toString(), type: ToastType.error);
    }
  }

  void _handleSave() {
    if (_nameCtrl.text.trim().isEmpty) {
      ToastService.show(title: 'Something went wrong', message: 'Full name is required', type: ToastType.error);
      return;
    }
    if (_mobileCtrl.text.trim().isEmpty) {
      ToastService.show(title: 'Something went wrong', message: 'Mobile number is required', type: ToastType.error);
      return;
    }
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if ((email.isNotEmpty) != (password.isNotEmpty)) {
      ToastService.show(
        title: 'Something went wrong',
        message: 'Portal login needs both an email and a password',
        type: ToastType.error,
      );
      return;
    }
    if (password.isNotEmpty && password.length < 6) {
      ToastService.show(
          title: 'Something went wrong',
          message: 'Password must be at least 6 characters',
          type: ToastType.error);
      return;
    }

    final updated = Customer(
      id: widget.initialData?.id ?? '',
      customerId: widget.initialData?.customerId ?? '',
      fullName: _nameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      aadhaar: _aadhaarCtrl.text.trim(),
      pan: _panCtrl.text.trim(),
      occupation: _occupationCtrl.text.trim(),
      photoUrl: _photoDataUri,
      assignedAgent: _assignedAgentId,
      latitude: double.tryParse(_latCtrl.text.trim()),
      longitude: double.tryParse(_lngCtrl.text.trim()),
      loanStatus: widget.initialData?.loanStatus ?? 'none',
    );

    widget.onSave(updated, email.isEmpty ? null : email, password.isEmpty ? null : password);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialData != null;
    final initials = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim()[0].toUpperCase() : 'C';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEditing ? 'Edit Customer' : 'Add Customer',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildInputField('Customer Name', 'FULL NAME *', _nameCtrl),
          _buildInputField('Mobile Number', 'MOBILE', _mobileCtrl),
          _buildInputField('Address', 'ADDRESS', _addressCtrl, maxLines: 3),
          _buildInputField('Aadhaar Number', 'AADHAAR', _aadhaarCtrl),
          _buildInputField('PAN Number', 'PAN', _panCtrl),
          _buildInputField('Occupation', 'OCCUPATION', _occupationCtrl),

          // ASSIGNED AGENT
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ASSIGNED AGENT',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kTextMuted)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _assignedAgentId,
                      hint: const Text('Unassigned', style: TextStyle(color: AppColors.kTextMuted)),
                      icon: const Icon(Icons.unfold_more, size: 20, color: AppColors.kTextMuted),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
                        ...widget.agents.map((a) => DropdownMenuItem<String?>(
                              value: a.id,
                              child: Text(a.fullName, style: const TextStyle(color: AppColors.kTextDark)),
                            )),
                      ],
                      onChanged: (val) => setState(() => _assignedAgentId = val),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MAP LOCATION
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.kBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map_outlined, size: 18, color: AppColors.kGoldDark),
                    SizedBox(width: 8),
                    Text('Map Location',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
                    SizedBox(width: 6),
                    Text('(for agent route)', style: TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _locationBusy ? null : _pinFromAddress,
                        icon: const Icon(Icons.location_searching, size: 16),
                        label: const Text('Pin from address'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _locationBusy ? null : _useMyGps,
                        icon: const Icon(Icons.gps_fixed, size: 16),
                        label: const Text('Use my GPS'),
                      ),
                    ),
                  ],
                ),
                if (_locationBusy)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildInputField('0.0000000', 'LATITUDE', _latCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInputField('0.0000000', 'LONGITUDE', _lngCtrl)),
                  ],
                ),
                const Text(
                  "Shows this customer on the agent's live Route Map. \"Pin from address\" looks up "
                  "the address above; \"Use my GPS\" captures where you're standing.",
                  style: TextStyle(fontSize: 12, color: AppColors.kTextMuted, height: 1.4),
                ),
              ],
            ),
          ),

          // PORTAL LOGIN
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.kBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: AppColors.kGoldDark),
                    SizedBox(width: 8),
                    Text('Portal Login (optional)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set an email & password to let this customer sign in and view their own loans & payments.',
                  style: TextStyle(fontSize: 12, color: AppColors.kTextMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                _buildInputField('customer@example.com', 'LOGIN EMAIL', _emailCtrl),
                _buildInputField('At least 6 characters', 'PASSWORD', _passwordCtrl, obscure: true),
              ],
            ),
          ),

          // CUSTOMER PHOTO
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.kGold,
                  backgroundImage: _photoDataUri != null ? MemoryImage(_decodeDataUri(_photoDataUri!)) : null,
                  child: _photoDataUri == null
                      ? Text(initials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))
                      : null,
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.upload_outlined, size: 16),
                  label: const Text('Upload Photo'),
                ),
              ],
            ),
          ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kGoldDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _handleSave,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(isEditing ? 'Save Changes' : 'Add Customer',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Uint8List _decodeDataUri(String dataUri) {
    final base64Part = dataUri.split(',').last;
    return base64Decode(base64Part);
  }

  Widget _buildInputField(String hint, String label, TextEditingController controller,
      {int maxLines = 1, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kTextMuted)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            obscureText: obscure,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}