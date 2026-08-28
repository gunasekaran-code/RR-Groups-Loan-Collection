import 'dart:convert';
import 'dart:typed_data';
import '../../models/customer.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../theme/glass_toast.dart';
import '../../widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/page_header.dart';
import '../../theme/confirm_dialog.dart';
import '../../services/photo_service.dart';
import '../../services/location_service.dart';
import '../../services/customer_api_service.dart';
import '../../l10n/generated/app_localizations.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _api = CustomerApiService();

  String _query = '';
  // Internal filter keys stay in English; only the displayed label is localized.
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
      final l10n = AppLocalizations.of(context);
      ToastService.show(
        title: l10n.customersLoadFailedTitle,
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
      // debugPrint('Failed to load agents: $e');
    }
  }

  // Maps the SQL enum ('none'|'active'|'overdue'|'closed') to internal filter labels.
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

  // Maps an internal filter key (English constant) to its localized display text.
  String _filterDisplayLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'All Status':
        return l10n.customersFilterAll;
      case 'Active':
        return l10n.customersFilterActive;
      case 'Overdue':
        return l10n.customersFilterOverdue;
      case 'Inactive':
        return l10n.customersFilterInactive;
      default:
        return key;
    }
  }

  void _viewCustomer(Customer c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))
            ],
          ),
          child: SafeArea(
            top: false,
            child:
                SingleChildScrollView(child: _CustomerViewSheet(customer: c)),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCustomer(Customer c) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.customersDeleteTitle,
      message: l10n.customersDeleteMessage(c.fullName),
      confirmLabel: l10n.delete,
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
        title: l10n.customersDeletedTitle,
        message: l10n.customersDeletedMessage(c.fullName),
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: l10n.customersDeleteFailedTitle,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  void _showCustomerFormModal({Customer? existingCustomer}) {
    final isEditing = existingCustomer != null;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))
            ],
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
                      await _api.create(updated,
                          email: email, password: password);
                    }
                    if (!mounted) return;
                    await _loadCustomers();
                    if (!mounted) return;
                    Navigator.pop(context);
                    ToastService.show(
                      title: isEditing
                          ? l10n.customersUpdatedTitle
                          : l10n.customersAddedTitle,
                      message: isEditing
                          ? l10n.customersUpdatedMessage(updated.fullName)
                          : l10n.customersAddedMessage(updated.fullName),
                      type: ToastType.success,
                    );
                  } catch (e) {
                    ToastService.show(
                      title: l10n.customersSaveFailedTitle,
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final filtered = _customers.where((c) {
      final matchesName =
          c.fullName.toLowerCase().contains(_query.toLowerCase());
      final matchesStatus = _statusFilter == 'All Status' ||
          _statusLabel(c.loanStatus) == _statusFilter;
      return matchesName && matchesStatus;
    }).toList();

    return AppShell(
      currentRoute: AppRoutes.customers,
      title: l10n.customersTitle,
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: RefreshIndicator(
          onRefresh: _loadCustomers,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(
                title: l10n.customersTitle,
                subtitle: l10n.customersSubtitle,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showCustomerFormModal(),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: Text(l10n.customersAddButton),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: scheme.outline.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: l10n.customersSearchHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.2)),
                        color: scheme.surface,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _statusFilter,
                          icon: const Icon(Icons.unfold_more,
                              size: 20, color: AppColors.kTextMuted),
                          items: ['All Status', 'Active', 'Overdue', 'Inactive']
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(_filterDisplayLabel(s, l10n),
                                        style: const TextStyle(
                                            color: AppColors.kTextDark)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _statusFilter = val);
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
                        Text(_error!,
                            style: const TextStyle(color: AppColors.kDanger)),
                        const SizedBox(height: 12),
                        OutlinedButton(
                            onPressed: _loadCustomers,
                            child: Text(l10n.retry)),
                      ],
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text(l10n.customersNoResults)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
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
    final l10n = AppLocalizations.of(context);
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextDark),
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
          _buildViewField(l10n.customerFieldId, customer.customerId),
          _buildViewField(l10n.customerFieldMobile, customer.mobile),
          _buildViewField(l10n.customerFieldAddress, customer.address),
          _buildViewField(l10n.customerFieldAadhaar, customer.aadhaar),
          _buildViewField(l10n.customerFieldPan, customer.pan),
          _buildViewField(l10n.customerFieldOccupation, customer.occupation),
          _buildViewField(l10n.customerFieldAgent,
              customer.assignedAgentName ?? customer.assignedAgent),
          _buildViewField(l10n.customerFieldLoanStatus, customer.loanStatus),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.customerViewClose,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextMuted)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.kBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Text(value ?? '-',
                style:
                    const TextStyle(color: AppColors.kTextDark, fontSize: 14)),
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
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isActive = statusLabel == 'Active';
    final badgeColor = isActive
        ? AppColors.kSuccess.withOpacity(0.1)
        : AppColors.kDanger.withOpacity(0.1);
    final badgeTextColor = isActive ? AppColors.kSuccess : AppColors.kDanger;

    // Display-only localization of the status badge; internal comparisons
    // above still use the English constant returned by _statusLabel.
    final displayStatusLabel = statusLabel == 'Active'
        ? l10n.customersFilterActive
        : statusLabel == 'Overdue'
            ? l10n.customersFilterOverdue
            : statusLabel == 'Inactive'
                ? l10n.customersFilterInactive
                : statusLabel;

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
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.fullName,
                        style: const TextStyle(
                            color: AppColors.kTextDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(customer.customerId,
                        style: const TextStyle(
                            color: AppColors.kTextMuted, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeColor, borderRadius: BorderRadius.circular(12)),
                child: Text(displayStatusLabel,
                    style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _DetailItem(
                      icon: Icons.phone_outlined,
                      text: customer.mobile ?? '-')),
              Expanded(
                  child: _DetailItem(
                      icon: Icons.location_on_outlined,
                      text: customer.address ?? '-')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _DetailItem(
                      icon: Icons.credit_card_outlined,
                      text: customer.aadhaar ?? '-')),
              Expanded(
                  child: _DetailItem(
                      icon: Icons.business_center_outlined,
                      text: customer.assignedAgentName ??
                          customer.assignedAgent ??
                          l10n.customerUnassigned)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                  icon: Icons.visibility_outlined,
                  label: l10n.customerActionView,
                  color: AppColors.kInfo,
                  onTap: onView),
              _ActionButton(
                  icon: Icons.edit_outlined,
                  label: l10n.customerActionEdit,
                  color: AppColors.kGoldDark,
                  onTap: onEdit),
              _ActionButton(
                  icon: Icons.delete_outline,
                  label: l10n.customerActionDelete,
                  color: AppColors.kDanger,
                  onTap: onDelete),
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
  const _ActionButton(
      {required this.icon,
      required this.label,
      this.color,
      required this.onTap});

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
              Text(label,
                  style: TextStyle(
                      color: activeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOMER FORM (ADD & EDIT) — validated, stylish, responsive
// Portal login now uses the customer's MOBILE NUMBER + PASSWORD.
// No email/Gmail field is required anywhere in this form.
// ---------------------------------------------------------

class _CustomerForm extends StatefulWidget {
  final Customer? initialData;
  final List<AgentOption> agents;
  final void Function(Customer updated, String? email, String password) onSave;

  const _CustomerForm({
    this.initialData,
    required this.agents,
    required this.onSave,
  });

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _formKey = GlobalKey<FormState>();
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
  bool _obscurePassword = true;

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
    _emailCtrl = TextEditingController(text: d?.email ?? '');
    _passwordCtrl = TextEditingController();
    _latCtrl = TextEditingController(text: d?.latitude?.toString() ?? '');
    _lngCtrl = TextEditingController(text: d?.longitude?.toString() ?? '');
    _assignedAgentId = d?.assignedAgent;
    _photoDataUri = d?.photoUrl;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
    _occupationCtrl.dispose();
    _passwordCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _pinFromAddress() async {
    final l10n = AppLocalizations.of(context);
    if (_addressCtrl.text.trim().isEmpty) {
      ToastService.show(
        title: l10n.customerAddressRequiredTitle,
        message: l10n.customerAddressRequiredMessage,
        type: ToastType.error,
      );
      return;
    }
    setState(() => _locationBusy = true);
    try {
      final result = await _locationService.geocodeAddress(_addressCtrl.text);
      setState(() {
        _latCtrl.text = result.latitude.toStringAsFixed(7);
        _lngCtrl.text = result.longitude.toStringAsFixed(7);
      });
    } catch (e) {
      ToastService.show(
          title: l10n.customerAddressNotFoundTitle,
          message: e.toString(),
          type: ToastType.error);
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  Future<void> _useMyGps() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _locationBusy = true);
    try {
      final result = await _locationService.getCurrentPosition();
      setState(() {
        _latCtrl.text = result.latitude.toStringAsFixed(7);
        _lngCtrl.text = result.longitude.toStringAsFixed(7);
      });
    } catch (e) {
      ToastService.show(
          title: l10n.customerLocationFailedTitle,
          message: e.toString(),
          type: ToastType.error);
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    try {
      final dataUri = await _photoService.pickPhotoAsDataUri();
      if (dataUri != null) setState(() => _photoDataUri = dataUri);
    } catch (e) {
      ToastService.show(
          title: l10n.customerPhotoFailedTitle,
          message: e.toString(),
          type: ToastType.error);
    }
  }

  // ---- Validators ----
  // Each takes an AppLocalizations instance so messages stay localized.

  String? _validateName(String? v, AppLocalizations l10n) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return l10n.customerValidatorNameRequired;
    if (value.length < 3) return l10n.customerValidatorNameMin;
    if (!RegExp(r'^[a-zA-Z .]+$').hasMatch(value)) {
      return l10n.customerValidatorNameChars;
    }
    return null;
  }

  String? _validateMobile(String? v, AppLocalizations l10n) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return l10n.customerValidatorMobileRequired;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return l10n.customerValidatorMobileInvalid;
    }
    return null;
  }

  String? _validateAddress(String? v, AppLocalizations l10n) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return l10n.customerValidatorAddressRequired;
    if (value.length < 5) return l10n.customerValidatorAddressMin;
    return null;
  }

  String? _validateAadhaar(String? v, AppLocalizations l10n) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null; // optional
    if (!RegExp(r'^\d{12}$').hasMatch(value)) {
      return l10n.customerValidatorAadhaarInvalid;
    }
    return null;
  }

  String? _validatePan(String? v, AppLocalizations l10n) {
    final value = v?.trim().toUpperCase() ?? '';
    if (value.isEmpty) return null; // optional
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
      return l10n.customerValidatorPanInvalid;
    }
    return null;
  }

  String? _validateOccupation(String? v, AppLocalizations l10n) {
    final value = v?.trim() ?? '';
    if (value.isNotEmpty && value.length < 2) {
      return l10n.customerValidatorOccupationInvalid;
    }
    return null;
  }

  String? _validateLatitude(String? v, AppLocalizations l10n) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null; // optional
    final parsed = double.tryParse(value);
    if (parsed == null) return l10n.customerValidatorNumberInvalid;
    if (parsed < -90 || parsed > 90) return l10n.customerValidatorLatRange;
    return null;
  }

  String? _validateLongitude(String? v, AppLocalizations l10n) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null; // optional
    final parsed = double.tryParse(value);
    if (parsed == null) return l10n.customerValidatorNumberInvalid;
    if (parsed < -180 || parsed > 180) return l10n.customerValidatorLngRange;
    return null;
  }

  String? _validateEmail(String? v, AppLocalizations l10n) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null; // optional
    final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(value);
    if (!ok) return l10n.customerValidatorEmailInvalid;
    return null;
  }

  String? _validatePassword(String? v, AppLocalizations l10n) {
    final value = v ?? '';
    if (value.isEmpty) return null; // optional unless portal login is configured
    if (value.length < 6) return l10n.customerValidatorPasswordMin;
    return null;
  }

  void _handleSave(AppLocalizations l10n) {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ToastService.show(
        title: l10n.customerFormValidationTitle,
        message: l10n.customerFormValidationMessage,
        type: ToastType.error,
      );
      return;
    }
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final updated = Customer(
      id: widget.initialData?.id ?? '',
      customerId: widget.initialData?.customerId ?? '',
      fullName: _nameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      aadhaar: _aadhaarCtrl.text.trim(),
      pan: _panCtrl.text.trim().toUpperCase(),
      occupation: _occupationCtrl.text.trim(),
      photoUrl: _photoDataUri,
      assignedAgent: _assignedAgentId,
      latitude: double.tryParse(_latCtrl.text.trim()),
      longitude: double.tryParse(_lngCtrl.text.trim()),
      loanStatus: widget.initialData?.loanStatus ?? 'none',
    );

    widget.onSave(updated, email.isEmpty ? null : email, password);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.initialData != null;
    final initials = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()[0].toUpperCase()
        : 'C';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;

        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 16 : 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header ----
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.kGold, AppColors.kGoldDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.kGoldDark.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isEditing
                                ? Icons.person_outline
                                : Icons.person_add_alt_1_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? l10n.customerFormEditTitle
                                  : l10n.customerFormAddTitle,
                              style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.kTextDark),
                            ),
                            Text(
                              isEditing
                                  ? l10n.customerFormEditSubtitle
                                  : l10n.customerFormAddSubtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.kTextMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon:
                          const Icon(Icons.close, color: AppColors.kTextMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _sectionLabel(Icons.badge_outlined, l10n.customerSectionPersonal),
                const SizedBox(height: 12),

                _buildInputField(
                  l10n.customerLabelFullName,
                  l10n.customerHintFullName,
                  _nameCtrl,
                  validator: (v) => _validateName(v, l10n),
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                ),
                _buildInputField(
                  l10n.customerLabelMobile,
                  l10n.customerHintMobile,
                  _mobileCtrl,
                  validator: (v) => _validateMobile(v, l10n),
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                _buildInputField(
                  l10n.customerLabelAddress,
                  l10n.customerHintAddress,
                  _addressCtrl,
                  validator: (v) => _validateAddress(v, l10n),
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 3,
                ),

                isNarrow
                    ? Column(
                        children: [
                          _buildInputField(
                            l10n.customerLabelAadhaar,
                            l10n.customerHintAadhaar,
                            _aadhaarCtrl,
                            validator: (v) => _validateAadhaar(v, l10n),
                            prefixIcon: Icons.credit_card_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(12),
                            ],
                          ),
                          _buildInputField(
                            l10n.customerLabelPan,
                            l10n.customerHintPan,
                            _panCtrl,
                            validator: (v) => _validatePan(v, l10n),
                            prefixIcon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10)
                            ],
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInputField(
                              l10n.customerLabelAadhaar,
                              l10n.customerHintAadhaar,
                              _aadhaarCtrl,
                              validator: (v) => _validateAadhaar(v, l10n),
                              prefixIcon: Icons.credit_card_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              l10n.customerLabelPan,
                              l10n.customerHintPan,
                              _panCtrl,
                              validator: (v) => _validatePan(v, l10n),
                              prefixIcon: Icons.badge_outlined,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(10)
                              ],
                            ),
                          ),
                        ],
                      ),

                _buildInputField(
                  l10n.customerLabelOccupation,
                  l10n.customerHintOccupation,
                  _occupationCtrl,
                  validator: (v) => _validateOccupation(v, l10n),
                  prefixIcon: Icons.work_outline,
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 4),
                _sectionLabel(Icons.groups_outlined, l10n.customerSectionAssignment),
                const SizedBox(height: 12),

                // ASSIGNED AGENT
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.customerLabelAssignedAgent,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMuted)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.kBorder),
                          color: AppColors.kBackground,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _assignedAgentId,
                            hint: Text(l10n.customerUnassigned,
                                style: const TextStyle(color: AppColors.kTextMuted)),
                            icon: const Icon(Icons.unfold_more,
                                size: 20, color: AppColors.kTextMuted),
                            items: [
                              DropdownMenuItem<String?>(
                                  value: null, child: Text(l10n.customerUnassigned)),
                              ...widget.agents
                                  .map((a) => DropdownMenuItem<String?>(
                                        value: a.id,
                                        child: Text(a.fullName,
                                            style: const TextStyle(
                                                color: AppColors.kTextDark)),
                                      )),
                            ],
                            onChanged: (val) =>
                                setState(() => _assignedAgentId = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // MAP LOCATION
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.kBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.map_outlined,
                              size: 18, color: AppColors.kGoldDark),
                          const SizedBox(width: 8),
                          Text(l10n.customerMapLocationTitle,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.kTextDark)),
                        ],
                      ),
                      Text(l10n.customerMapLocationSubtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.kTextMuted)),
                      const SizedBox(height: 12),
                      isNarrow
                          ? Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _locationBusy ? null : _pinFromAddress,
                                    icon: const Icon(Icons.location_searching,
                                        size: 16),
                                    label: Text(l10n.customerPinFromAddress),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _locationBusy ? null : _useMyGps,
                                    icon: const Icon(Icons.gps_fixed, size: 16),
                                    label: Text(l10n.customerUseMyGps),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _locationBusy ? null : _pinFromAddress,
                                    icon: const Icon(Icons.location_searching,
                                        size: 16),
                                    label: Text(l10n.customerPinFromAddress),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _locationBusy ? null : _useMyGps,
                                    icon: const Icon(Icons.gps_fixed, size: 16),
                                    label: Text(l10n.customerUseMyGps),
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
                      isNarrow
                          ? Column(
                              children: [
                                _buildInputField(
                                    l10n.customerLatLngHint,
                                    l10n.customerLatitudeLabel,
                                    _latCtrl,
                                    validator: (v) => _validateLatitude(v, l10n),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true, signed: true)),
                                _buildInputField(
                                    l10n.customerLatLngHint,
                                    l10n.customerLongitudeLabel,
                                    _lngCtrl,
                                    validator: (v) => _validateLongitude(v, l10n),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true, signed: true)),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: _buildInputField(
                                        l10n.customerLatLngHint,
                                        l10n.customerLatitudeLabel,
                                        _latCtrl,
                                        validator: (v) =>
                                            _validateLatitude(v, l10n),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                            decimal: true, signed: true))),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _buildInputField(
                                        l10n.customerLatLngHint,
                                        l10n.customerLongitudeLabel,
                                        _lngCtrl,
                                        validator: (v) =>
                                            _validateLongitude(v, l10n),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                            decimal: true, signed: true))),
                              ],
                            ),
                      Text(
                        l10n.customerMapHelpText,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.kTextMuted,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),

                _sectionLabel(
                    Icons.lock_outline, l10n.customerSectionPortalLogin),
                const SizedBox(height: 12),

                // PORTAL LOGIN — mobile number + password (no email required)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.kBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.kGoldDark.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.phonelink_lock_outlined,
                                size: 16, color: AppColors.kGoldDark),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.customerPortalLoginHelp,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.kTextMuted,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        l10n.customerLabelEmail,
                        l10n.customerHintEmail,
                        _emailCtrl,
                        validator: (v) => _validateEmail(v, l10n),
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildInputField(
                        l10n.customerLabelPassword,
                        l10n.customerHintPassword,
                        _passwordCtrl,
                        validator: (v) => _validatePassword(v, l10n),
                        prefixIcon: Icons.key_outlined,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.kTextMuted,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 14, color: AppColors.kTextMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l10n.customerLoginNote,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.kTextMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _sectionLabel(Icons.image_outlined, l10n.customerSectionPhoto),
                const SizedBox(height: 12),

                // CUSTOMER PHOTO
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.kGold,
                            backgroundImage: _photoDataUri != null
                                ? MemoryImage(_decodeDataUri(_photoDataUri!))
                                : null,
                            child: _photoDataUri == null
                                ? Text(initials,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20))
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.kGoldDark,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_outlined,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.upload_outlined, size: 16),
                          label: Text(l10n.customerUploadPhoto),
                        ),
                      ),
                    ],
                  ),
                ),

                isNarrow
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.kGoldDark,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _handleSave(l10n),
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: Text(
                                  isEditing
                                      ? l10n.customerSaveChanges
                                      : l10n.customersAddButton,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.cancel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.cancel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.kGoldDark,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _handleSave(l10n),
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: Text(
                                  isEditing
                                      ? l10n.customerSaveChanges
                                      : l10n.customersAddButton,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.kGoldDark),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.kGoldDark,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: AppColors.kBorder, height: 1)),
      ],
    );
  }

  Uint8List _decodeDataUri(String dataUri) {
    final base64Part = dataUri.split(',').last;
    return base64Decode(base64Part);
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    bool obscureText = false,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextMuted)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: obscureText ? 1 : maxLines,
            obscureText: obscureText,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: const TextStyle(color: AppColors.kTextDark, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 18, color: AppColors.kTextMuted)
                  : null,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: AppColors.kSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.kGoldDark, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.kDanger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.kDanger, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}