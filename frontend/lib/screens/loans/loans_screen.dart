import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_badge.dart';
import '../../theme/confirm_dialog.dart';
import '../../theme/glass_toast.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  String _query = '';
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Active',
    'Overdue',
    'Closed',
    'Pending'
  ];

  final List<Map<String, dynamic>> _loans = [
    {
      'id': 'LN-232037',
      'customer': 'Lakshmi Iyer',
      'amount': '₹50,000',
      'emi': '₹9,383',
      'outstanding': '₹52,500',
      'agent': 'Sneha Reddy',
      'status': 'Active',
      'start': '01 Jul 2026',
      'interest': '42',
      'duration': '6'
    },
    {
      'id': 'LN-627299',
      'customer': 'Lakshmi Iyer',
      'amount': '₹50,000',
      'emi': '₹4,349',
      'outstanding': '₹50,098',
      'agent': 'Arjun Mehta',
      'status': 'Active',
      'start': '22 Jun 2026',
      'interest': '18',
      'duration': '12'
    },
    {
      'id': 'LN-GH6718',
      'customer': 'Anjali Singh',
      'amount': '₹1,00,000',
      'emi': '₹17,156',
      'outstanding': '₹0',
      'agent': 'Arjun Mehta',
      'status': 'Closed',
      'start': '01 Aug 2024',
      'interest': '24',
      'duration': '6'
    },
    {
      'id': 'LN-MN2304',
      'customer': 'Ramesh Gowda',
      'amount': '₹3,00,000',
      'emi': '₹18,239',
      'outstanding': '₹3,28,293',
      'agent': 'Unassigned',
      'status': 'Pending',
      'start': '22 Jun 2026',
      'interest': '20',
      'duration': '18'
    },
    {
      'id': 'LN-DE34F5',
      'customer': 'Lakshmi Iyer',
      'amount': '₹2,00,000',
      'emi': '₹17,936',
      'outstanding': '₹1,97,301',
      'agent': 'Arjun Mehta',
      'status': 'Overdue',
      'start': '01 Mar 2025',
      'interest': '15',
      'duration': '12'
    },
  ];

  /// Helper to wrap form or view content inside the identical 75% max height layout frame
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

  void _showViewLoanDialog(Map<String, dynamic> loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: LoanDetailDialog(
          loan: loan,
          onDelete: () {
            Navigator.of(context).pop();
            _showCloseLoanDialog(loan);
          },
        ),
      ),
    );
  }

  void _showCreateLoanDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: LoanFormDialog(
          onSaved: (newLoan) {
            setState(() {
              _loans.add(newLoan);
            });
          },
        ),
      ),
    );
  }

  void _showEditLoanDialog(Map<String, dynamic> loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: LoanFormDialog(
          loan: loan,
          onSaved: (updated) {
            setState(() {
              final index = _loans.indexWhere((l) => l['id'] == loan['id']);
              if (index != -1) _loans[index] = updated;
            });
          },
        ),
      ),
    );
  }

  void _showCloseLoanDialog(Map<String, dynamic> loan) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Close Loan',
      message: 'Are you sure you want to close loan ${loan['id']}? Outstanding balance will be set to zero.',
      confirmLabel: 'Close Loan',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true && mounted) {
      setState(() {
        loan['status'] = 'Closed';
        loan['outstanding'] = '₹0';
      });

      ToastService.show(
        title: 'Loan closed',
        message: '${loan['id']} outstanding balance set to zero',
        type: ToastType.success,
      );
    }
  }

  BadgeTone _toneFor(String status) {
    switch (status) {
      case 'Active':
        return BadgeTone.success;
      case 'Overdue':
        return BadgeTone.danger;
      case 'Closed':
        return BadgeTone.neutral;
      default:
        return BadgeTone.warning;
    }
  }

  List<Map<String, dynamic>> get _filteredLoans => _loans.where((l) {
        final matchesQuery =
            l['customer']!.toLowerCase().contains(_query.toLowerCase()) ||
                l['id']!.toLowerCase().contains(_query.toLowerCase());
        final matchesFilter =
            _selectedFilter == 'All' || l['status'] == _selectedFilter;
        return matchesQuery && matchesFilter;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/loans',
      title: 'Loans',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Loans',
                subtitle: 'Manage loan accounts, schedules, and repayments',
                actions: [
                  Align(
                    alignment: Alignment.centerLeft,
                             
                    child: SizedBox(
                      width: 150,
                      child: ElevatedButton.icon(
                        onPressed: _showCreateLoanDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Loan'),
                        style: ElevatedButton.styleFrom(
                           padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _buildSearchAndFilters(isNarrow),
              const SizedBox(height: 8),
              Expanded(child: _buildLoansTable(isNarrow)),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isNarrow) {
    final searchField = TextField(
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Search loan number or customer...',
        isDense: true,
      ),
      onChanged: (v) => setState(() => _query = v),
    );

    final filterRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              selectedColor: AppColors.kGold,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.kTextDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) =>
                  setState(() => _selectedFilter = filter),
            ),
          );
        }).toList(),
      ),
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
            filterRow,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: searchField),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: filterRow),
        ],
      ),
    );
  }

  Widget _buildLoansTable(bool isNarrow) {
    final loans = _filteredLoans;
    final table = DataTable(
      headingTextStyle: const TextStyle(
        color: AppColors.kTextMuted,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      columns: const [
        DataColumn(label: Text('LOAN NO')),
        DataColumn(label: Text('CUSTOMER')),
        DataColumn(label: Text('AMOUNT')),
        DataColumn(label: Text('EMI')),
        DataColumn(label: Text('OUTSTANDING')),
        DataColumn(label: Text('AGENT')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('START')),
        DataColumn(label: Text('ACTIONS')),
      ],
      rows: loans.map((loan) {
        return DataRow(cells: [
          DataCell(Text(loan['id']!,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(loan['customer']!)),
          DataCell(Text(loan['amount']!)),
          DataCell(Text(loan['emi']!)),
          DataCell(Text(loan['outstanding']!,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(loan['agent']!)),
          DataCell(StatusBadge(
              label: loan['status']!, tone: _toneFor(loan['status']!))),
          DataCell(Text(loan['start']!)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                color: AppColors.kTextMuted,
                onPressed: () => _showViewLoanDialog(loan),
                tooltip: 'View',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.kTextMuted,
                onPressed: () => _showEditLoanDialog(loan),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.block_outlined, size: 20),
                color: AppColors.kDanger,
                onPressed: () => _showCloseLoanDialog(loan),
                tooltip: 'Block/Delete',
              ),
            ],
          )),
        ]);
      }).toList(),
    );

    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: isNarrow ? 12.0 : 24.0, vertical: 8.0),
      color: AppColors.kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 980),
              child: SingleChildScrollView(
                child: table,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// VIEW LOAN DETAIL SHEET (Cleaned from custom Dialog)
// ==========================================
class LoanDetailDialog extends StatelessWidget {
  final Map<String, dynamic> loan;
  final VoidCallback? onDelete;

  const LoanDetailDialog({super.key, required this.loan, this.onDelete});

  BadgeTone _toneFor(String status) {
    switch (status) {
      case 'Active':
        return BadgeTone.success;
      case 'Overdue':
        return BadgeTone.danger;
      case 'Closed':
        return BadgeTone.neutral;
      default:
        return BadgeTone.warning;
    }
  }

  Widget _field(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.kBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kTextDark)),
          ],
        ),
      ),
    );
  }

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
              Expanded(
                child: Text(
                  'Loan ${loan['id']}',
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
          const SizedBox(height: 20),
          Row(children: [
            _field('Customer', loan['customer']!),
            _field('Loan Amount', loan['amount']!)
          ]),
          Row(children: [
            _field('EMI', loan['emi']!),
            _field('Outstanding', loan['outstanding']!)
          ]),
          Row(children: [
            _field('Interest', '${loan['interest'] ?? '-'}%'),
            _field('Duration', '${loan['duration'] ?? '-'} mo'),
          ]),
          Row(children: [
            _field('Start Date', loan['start']!),
            _field('Agent', loan['agent']!)
          ]),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              StatusBadge(
                  label: loan['status']!, tone: _toneFor(loan['status']!)),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ToastService.show(
                        title: 'Viewing schedule',
                        message: loan['id'],
                        type: ToastType.info,
                      );
                    },
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Schedule'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading ${loan['id']}')),
                      );
                    },
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kDanger,
                      side: const BorderSide(color: AppColors.kDanger),
                    ),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CREATE / EDIT LOAN SHEET (Cleaned from custom Dialog)
// ==========================================
class LoanFormDialog extends StatefulWidget {
  final Map<String, dynamic>? loan;
  final ValueChanged<Map<String, dynamic>>? onSaved;

  const LoanFormDialog({super.key, this.loan, this.onSaved});

  bool get isEdit => loan != null;

  @override
  State<LoanFormDialog> createState() => _LoanFormDialogState();
}

class _LoanFormDialogState extends State<LoanFormDialog> {
  late final TextEditingController _loanNumberController;
  late final TextEditingController _customerController;
  late final TextEditingController _amountController;
  late final TextEditingController _interestController;
  late final TextEditingController _durationController;
  late final TextEditingController _startDateController;
  late final TextEditingController _agentController;
  late final TextEditingController _feeController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    _loanNumberController =
        TextEditingController(text: loan?['id'] ?? 'LN-319960');
    _customerController = TextEditingController(text: loan?['customer'] ?? '');
    _amountController = TextEditingController(
        text: loan != null
            ? loan['amount']!.replaceAll(RegExp(r'[₹,]'), '')
            : '');
    _interestController = TextEditingController(text: loan?['interest'] ?? '');
    _durationController = TextEditingController(text: loan?['duration'] ?? '');
    _startDateController =
        TextEditingController(text: loan?['start'] ?? '10/07/2026');
    _agentController =
        TextEditingController(text: loan?['agent'] ?? 'Unassigned');
    _feeController = TextEditingController(text: '');
    _notesController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _loanNumberController.dispose();
    _customerController.dispose();
    _amountController.dispose();
    _interestController.dispose();
    _durationController.dispose();
    _startDateController.dispose();
    _agentController.dispose();
    _feeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave({bool approve = false}) {
    final updated = <String, dynamic>{
      ...?widget.loan,
      'id': _loanNumberController.text,
      'customer': _customerController.text,
      'amount': '₹${_amountController.text}',
      'interest': _interestController.text,
      'duration': _durationController.text,
      'start': _startDateController.text,
      'agent': _agentController.text,
      'emi': widget.loan?['emi'] ?? '₹0',
      'outstanding': widget.loan?['outstanding'] ?? '₹0',
      'status': approve ? 'Active' : (widget.loan?['status'] ?? 'Pending'),
    };
    widget.onSaved?.call(updated);
    Navigator.of(context).pop();
    ToastService.show(
      title: widget.isEdit ? 'Loan updated' : 'Loan created',
      message: updated['id'],
      type: ToastType.success,
    );
  }

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
              Expanded(
                child: Text(
                  widget.isEdit ? 'Edit Loan' : 'Create Loan',
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
              )
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Column(
                children: [
                  _responsiveRow(
                    isNarrow,
                    _buildTextField('LOAN NUMBER', 'LN-319960',
                        enabled: false, controller: _loanNumberController),
                    _buildTextField('CUSTOMER *', 'Select customer...',
                        controller: _customerController),
                  ),
                  const SizedBox(height: 16),
                  _responsiveRow(
                    isNarrow,
                    _buildTextField('LOAN AMOUNT *', '',
                        controller: _amountController),
                    _buildTextField('INTEREST (% P.A.) *', '',
                        controller: _interestController),
                  ),
                  const SizedBox(height: 16),
                  _responsiveRow(
                    isNarrow,
                    _buildTextField('DURATION (MONTHS) *', '',
                        controller: _durationController),
                    _buildTextField('START DATE *', '10/07/2026',
                        controller: _startDateController),
                  ),
                  const SizedBox(height: 16),
                  _responsiveRow(
                    isNarrow,
                    _buildTextField('ASSIGNED AGENT', 'Unassigned',
                        controller: _agentController),
                    _buildTextField('PROCESSING FEE', '',
                        controller: _feeController),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTextField('NOTES', 'Optional notes...',
              maxLines: 3, controller: _notesController),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              final cards = [
                _buildSummaryCard('Monthly EMI', widget.loan?['emi'] ?? '₹0',
                    const Color(0xFFF0F5FF), AppColors.kInfo),
                _buildSummaryCard('Total Interest', '₹0',
                    const Color(0xFFFFFBEB), AppColors.kWarning),
                _buildSummaryCard('Total Repayment', '₹0',
                    const Color(0xFFF0FDF4), AppColors.kSuccess),
              ];
              if (isNarrow) {
                return Column(
                  children: [
                    for (final c in cards) ...[
                      SizedBox(width: double.infinity, child: c),
                      const SizedBox(height: 12),
                    ]
                  ],
                );
              }
              return Row(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1) const SizedBox(width: 16),
                  ]
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
              OutlinedButton(
                onPressed: () => _handleSave(),
                child: const Text('Save'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kSuccess),
                onPressed: () => _handleSave(approve: true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Approve'),
              ),
            ],
          )
        ],
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
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );
  }

  Widget _buildTextField(String label, String hint,
      {bool enabled = true,
      TextEditingController? controller,
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
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: textColor)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}