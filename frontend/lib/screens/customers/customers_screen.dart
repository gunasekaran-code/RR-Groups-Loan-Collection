import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/glass_toast.dart';
import '../../theme/confirm_dialog.dart';
import '../../widgets/page_header.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();


}

class _CustomerViewSheet extends StatelessWidget {
  final Map<String, String> customer;

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
                customer['name'] ?? 'Customer Details',
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
          _buildViewField('CUSTOMER ID', customer['id']),
          _buildViewField('MOBILE', customer['phone']),
          _buildViewField('ADDRESS', customer['address']),
          _buildViewField('AADHAR', customer['aadhar']),
          _buildViewField('ASSIGNED AGENT', customer['agent']),
          _buildViewField('STATUS', customer['status']),
          
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(fontWeight: FontWeight.w600)),
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
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.kBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Text(
              value ?? '-', 
              style: const TextStyle(
                  color: AppColors.kTextDark, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';
  String _statusFilter = 'All Status';

  List<Map<String, String>> _customers = [
    {
      'name': 'Vikram Naidu',
      'id': 'CUST-FE6C19',
      'phone': '9988776655',
      'address': '12 MG Road, Bangal...',
      'aadhar': '[Aadhaar Redacted]',
      'agent': 'Arjun Mehta',
      'status': 'Active'
    },
    {
      'name': 'Lakshmi Iyer',
      'id': 'CUST-316E98',
      'phone': '9988776654',
      'address': '45 Anna Salai, Che...',
      'aadhar': '[Aadhaar Redacted]',
      'agent': 'Arjun Mehta',
      'status': 'Overdue'
    },
    {
      'name': 'Ramesh Gowda',
      'id': 'CUST-DE590D',
      'phone': '9988776653',
      'address': '88 Indiranagar, Ban...',
      'aadhar': '[Aadhaar Redacted]',
      'agent': 'Priya Singh',
      'status': 'Active'
    },
  ];

  void _viewCustomer(Map<String, String> customer) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
            child: _CustomerViewSheet(customer: customer),
          ),
        ),
      ),
    ),
  );
}

  // --- ACTIONS ---

  void _deleteCustomer(String id) async {
    final customer = _customers.firstWhere((c) => c['id'] == id);

    // Call the global helper seamlessly from any page
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Customer',
      message:
          'Are you sure you want to delete ${customer['name']}? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );

    // Act exclusively upon return execution confirm verification
    if (confirmed == true && mounted) {
      setState(() {
        _customers.removeWhere((c) => c['id'] == id);
      });

      ToastService.show(
        title: 'Customer deleted',
        message: '${customer['name']} was removed successfully',
        type: ToastType.success,
      );
    }
}



  void _showCustomerFormModal(
      {Map<String, String>? existingCustomer, int? index}) {
    final isEditing = existingCustomer != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Ensures shadow & curves show cleanly
      barrierColor: Colors.black.withOpacity(0.4), // Matches smooth dark tint
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context)
              .viewInsets
              .bottom, // Pushes smoothly above keyboard
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                  24), // Vertical top curves matching confirm style
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top:
                false, // Ensures bottom padding fits the iOS home indicator area when keyboard is down
            child: SingleChildScrollView(
              child: _CustomerForm(
                initialData: existingCustomer,
                onSave: (savedData) {
                  setState(() {
                    if (index != null) {
                      _customers[index] = savedData;
                    } else {
                      savedData['id'] =
                          'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                      _customers.add(savedData);
                    }
                  });

                  ToastService.show(
                    title: isEditing ? 'Customer updated' : 'Customer added',
                    message: isEditing
                        ? '${savedData['name']} was updated successfully'
                        : '${savedData['name']} was added successfully',
                    type: ToastType.success,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isNarrow) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search customers...',
        ),
        onChanged: (value) {
          // Search logic
        },
      ),
    );
  }

  void _showCreateCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Customer'),
          content: const Text('Customer form goes here'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 900;
    final filtered = _customers.where((c) {
      final matchesName =
          c['name']!.toLowerCase().contains(_query.toLowerCase());
      final matchesStatus =
          _statusFilter == 'All Status' || c['status'] == _statusFilter;
      return matchesName && matchesStatus;
    }).toList();

    return AppShell(
      currentRoute: AppRoutes.customers,
      title: 'Customers',
      body: Container(
        color: AppColors.kBackground,
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
                    // Example: hook export feedback into the toast too
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

            // Search & Filter Box
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
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.kTextMuted),
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
                        icon: const Icon(Icons.unfold_more,
                            size: 20, color: AppColors.kTextMuted),
                        items: ['All Status', 'Active', 'Overdue', 'Inactive']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s,
                                      style: const TextStyle(
                                          color: AppColors.kTextDark)),
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

            // Customer List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final c = filtered[index];
                final originalIndex = _customers
                    .indexWhere((element) => element['id'] == c['id']);

                return _CustomerCard(
                  customer: c,
                  onView: () => _viewCustomer(c),
                  onEdit: () => _showCustomerFormModal(
                      existingCustomer: c, index: originalIndex),
                  onDelete: () => _deleteCustomer(c['id']!),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOMER CARD WIDGET
// ---------------------------------------------------------

class _CustomerCard extends StatelessWidget {
  final Map<String, String> customer;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  String _getInitials(String name) {
    List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = customer['status'] == 'Active';
    final badgeColor = isActive
        ? AppColors.kSuccess.withOpacity(0.1)
        : AppColors.kDanger.withOpacity(0.1);
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
                  _getInitials(customer['name']!),
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
                    Text(
                      customer['name']!,
                      style: const TextStyle(
                          color: AppColors.kTextDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer['id']!,
                      style: const TextStyle(
                          color: AppColors.kTextMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  customer['status']!,
                  style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _DetailItem(
                      icon: Icons.phone_outlined, text: customer['phone']!)),
              Expanded(
                  child: _DetailItem(
                      icon: Icons.location_on_outlined,
                      text: customer['address']!)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _DetailItem(
                      icon: Icons.credit_card_outlined,
                      text: customer['aadhar']!)),
              Expanded(
                  child: _DetailItem(
                      icon: Icons.business_center_outlined,
                      text: customer['agent']!)),
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
                  label: 'View',
                  color: AppColors.kInfo,
                  onTap: onView),
              _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: AppColors.kGoldDark,
                  onTap: onEdit),
              _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
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
          child: Text(
            text,
            style: const TextStyle(color: AppColors.kTextDark, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
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
              Text(
                label,
                style: TextStyle(
                    color: activeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOMER FORM (ADD & EDIT)
// ---------------------------------------------------------

class _CustomerForm extends StatefulWidget {
  final Map<String, String>? initialData;
  final Function(Map<String, String>) onSave;

  const _CustomerForm({this.initialData, required this.onSave});

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _agentCtrl;
  String _status = 'Active';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialData?['name'] ?? '');
    _mobileCtrl =
        TextEditingController(text: widget.initialData?['phone'] ?? '');
    _addressCtrl =
        TextEditingController(text: widget.initialData?['address'] ?? '');
    _agentCtrl = TextEditingController(
        text: widget.initialData?['agent'] ?? 'Unassigned');
    _status = widget.initialData?['status'] ?? 'Active';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _agentCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    // Basic validation with error toast instead of failing silently
    if (_nameCtrl.text.trim().isEmpty || _mobileCtrl.text.trim().isEmpty) {
      ToastService.show(
        title: 'Something went wrong',
        message: 'Name and mobile number are required',
        type: ToastType.error,
      );
      return;
    }

    final updatedData = {
      'id': widget.initialData?['id'] ?? '',
      'name': _nameCtrl.text,
      'phone': _mobileCtrl.text,
      'address': _addressCtrl.text,
      'aadhar': widget.initialData?['aadhar'] ?? '[Aadhaar Redacted]',
      'agent': _agentCtrl.text,
      'status': _status,
    };

    widget.onSave(updatedData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialData != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Hugs content perfectly
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEditing ? 'Edit Customer' : 'Add Customer',
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

          // Form Fields List
          _buildInputField('Customer Name', 'NAME', _nameCtrl),
          _buildInputField('Mobile Number', 'MOBILE', _mobileCtrl),
          _buildInputField('Address', 'ADDRESS', _addressCtrl, maxLines: 3),
          _buildInputField('Assigned Agent', 'AGENT', _agentCtrl),

          // Status Dropdown
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STATUS',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextMuted)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _status,
                      icon: const Icon(Icons.unfold_more,
                          size: 20, color: AppColors.kTextMuted),
                      items: ['Active', 'Overdue', 'Inactive']
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s,
                                  style: const TextStyle(
                                      color: AppColors.kTextDark))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _handleSave,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    isEditing ? 'Save Changes' : 'Add Customer',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
      String hint, String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
