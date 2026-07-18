import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/confirm_dialog.dart';
import '../../widgets/page_header.dart';
import '../../theme/glass_toast.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  String _query = '';
  String _period = 'All';

  final List<String> _periods = const [
    'Today',
    'This Week',
    'This Month',
    'All'
  ];

  static final DateTime _today = DateTime(2026, 7, 10);

  final List<Map<String, String>> _collections = [
    {
      'customer': 'Lakshmi Iyer',
      'initials': 'LI',
      'receipt': 'RCT-95198699',
      'loan': 'LN-627299',
      'amount': '₹4,349',
      'date': '09 Jul 2026',
      'method': 'Cash',
      'agent': 'Arjun Mehta',
      'status': 'Collected',
    },
    {
      'customer': 'Vikram Naidu',
      'initials': 'VN',
      'receipt': 'RCP-86187095',
      'loan': 'LN-AB12C3',
      'amount': '₹5,000',
      'date': '08 Jul 2026',
      'method': 'Cash',
      'agent': 'Arjun Mehta',
      'status': 'Collected',
    },
    {
      'customer': 'Lakshmi Iyer',
      'initials': 'LI',
      'receipt': 'RCT-86187094',
      'loan': 'LN-627299',
      'amount': '₹4,349',
      'date': '22 Jun 2026',
      'method': 'Cash',
      'agent': 'Arjun Mehta',
      'status': 'Collected',
    },
    {
      'customer': 'Anjali Singh',
      'initials': 'AS',
      'receipt': 'RCT-77123456',
      'loan': 'LN-GH6718',
      'amount': '₹17,156',
      'date': '01 Jul 2026',
      'method': 'Bank Transfer',
      'agent': 'Arjun Mehta',
      'status': 'Collected',
    },
    {
      'customer': 'Ramesh Gowda',
      'initials': 'RG',
      'receipt': 'RCT-55098234',
      'loan': 'LN-MN2304',
      'amount': '₹18,239',
      'date': '05 Jul 2026',
      'method': 'Cash',
      'agent': 'Sneha Reddy',
      'status': 'Scheduled',
    },
  ];

  int _parseAmount(String amount) =>
      int.tryParse(amount.replaceAll(RegExp(r'[₹,]'), '')) ?? 0;

  static const Map<String, int> _months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  DateTime? _parseDate(String date) {
    final parts = date.split(' ');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = _months[parts[1]];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  bool _matchesPeriod(Map<String, String> c, String period) {
    final date = _parseDate(c['date'] ?? '');
    if (date == null || period == 'All') return true;
    switch (period) {
      case 'Today':
        return date.year == _today.year &&
            date.month == _today.month &&
            date.day == _today.day;
      case 'This Week':
        final diff = _today.difference(date).inDays;
        return diff >= 0 && diff < 7;
      case 'This Month':
        return date.year == _today.year && date.month == _today.month;
      default:
        return true;
    }
  }

  List<Map<String, String>> get _filtered => _collections.where((c) {
        final q = _query.toLowerCase();
        final matchesQuery = q.isEmpty ||
            c['customer']!.toLowerCase().contains(q) ||
            c['loan']!.toLowerCase().contains(q) ||
            c['receipt']!.toLowerCase().contains(q);
        return matchesQuery && _matchesPeriod(c, _period);
      }).toList();

  int get _todayTotal => _collections
      .where((c) => _matchesPeriod(c, 'Today'))
      .fold(0, (sum, c) => sum + _parseAmount(c['amount']!));

  int get _weekTotal => _collections
      .where((c) => _matchesPeriod(c, 'This Week'))
      .fold(0, (sum, c) => sum + _parseAmount(c['amount']!));

  int get _monthTotal => _collections
      .where((c) => _matchesPeriod(c, 'This Month'))
      .fold(0, (sum, c) => sum + _parseAmount(c['amount']!));

  String _fmt(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0) buf.write(',');
    }
    return '₹$buf';
  }

  /// Helper to enforce a consistent 75% max height wrapper frame
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

  void _showAddCollectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: AddCollectionDialog(
          customers: _collections.map((c) => c['customer']!).toSet().toList()
            ..sort(),
          onSaved: (record) => setState(() => _collections.insert(0, record)),
        ),
      ),
    );
  }

  void _showEditCollectionDialog(Map<String, String> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: AddCollectionDialog(
          customers: _collections.map((c) => c['customer']!).toSet().toList()
            ..sort(),
          existing: record,
          onSaved: (updated) => setState(() {
            final idx = _collections.indexWhere((c) => c['receipt'] == record['receipt']);
            if (idx != -1) _collections[idx] = updated;
          }),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, String> record) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Collection',
      message: 'Delete the collection record for ${record['customer']} (${record['receipt']})? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true && mounted) {
      setState(() {
        _collections.removeWhere((c) => c['receipt'] == record['receipt']);
      });

      ToastService.show(
        title: 'Collection deleted',
        message: record['receipt'],
        type: ToastType.success,
      );
    }
  }

  void _printReceipt(Map<String, String> record) {
    ToastService.show(
      title: 'Printing receipt',
      message: record['receipt'],
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.collections,
      title: 'Collections',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Collections',
                  subtitle: 'Record and track daily collections across all loans',
                  actions: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 160,
                        child: ElevatedButton.icon(
                          onPressed: _showAddCollectionDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Collection'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildStatCards(isNarrow),
                const SizedBox(height: 16),
                _buildSearchAndFilters(),
                const SizedBox(height: 8),
                _buildCollectionsTable(isNarrow),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCards(bool isNarrow) {
    final cards = [
      _StatCardData(
        label: "TODAY'S TOTAL",
        value: _fmt(_todayTotal),
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.kSuccess,
        iconBg: const Color(0xFFE7F7EE),
      ),
      _StatCardData(
        label: 'THIS WEEK',
        value: _fmt(_weekTotal),
        icon: Icons.currency_rupee,
        iconColor: AppColors.kInfo,
        iconBg: const Color(0xFFEAF1FF),
      ),
      _StatCardData(
        label: 'THIS MONTH',
        value: _fmt(_monthTotal),
        icon: Icons.description_outlined,
        iconColor: const Color(0xFF7C3AED),
        iconBg: const Color(0xFFF1EAFE),
      ),
      _StatCardData(
        label: 'TOTAL RECORDS',
        value: '${_collections.length}',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.kWarning,
        iconBg: const Color(0xFFFFF3DC),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 24, vertical: 8),
      child: GridView.count(
        crossAxisCount: isNarrow ? 2 : 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isNarrow ? 1.7 : 2.1,
        children: cards.map((c) => _StatCard(data: c)).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search customer, loan or receipt number...',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            _buildPeriodSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.kBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _periods.map((p) {
          final selected = _period == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.kSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1))
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.kInfo : AppColors.kTextMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCollectionsTable(bool isNarrow) {
    final items = _filtered;

    final table = DataTable(
      headingTextStyle: const TextStyle(
        color: AppColors.kTextMuted,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      dataTextStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.kTextDark,
      ),
      dividerThickness: 0,
      columns: const [
        DataColumn(label: Text('CUSTOMER')),
        DataColumn(label: Text('LOAN NUMBER')),
        DataColumn(label: Text('AMOUNT')),
        DataColumn(label: Text('METHOD')),
        DataColumn(label: Text('DATE')),
        DataColumn(label: Text('AGENT')),
        DataColumn(label: Text('ACTIONS')),
      ],
      rows: items.map((c) {
        return DataRow(cells: [
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.kInfo,
                child: Text(
                  c['initials']!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c['customer']!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(c['receipt']!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.kTextMuted)),
                ],
              ),
            ],
          )),
          DataCell(Text(c['loan']!)),
          DataCell(Text(c['amount']!,
              style: const TextStyle(fontWeight: FontWeight.w700))),
          DataCell(Text(c['method']!)),
          DataCell(Text(c['date']!)),
          DataCell(Text(c['agent']!)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.print_outlined, size: 20),
                color: AppColors.kTextMuted,
                onPressed: () => _printReceipt(c),
                tooltip: 'Print',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.kTextMuted,
                onPressed: () => _showEditCollectionDialog(c),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.kDanger,
                onPressed: () => _showDeleteConfirmDialog(c),
                tooltip: 'Delete',
              ),
            ],
          )),
        ]);
      }).toList(),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 24),
      child: items.isEmpty
          ? Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: AppColors.kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.kBorder),
              ),
              child: const Center(
                child: Text('No collections found',
                    style: TextStyle(color: AppColors.kTextMuted)),
              ),
            )
          : Card(
              margin: const EdgeInsets.only(top: 8),
              color: AppColors.kSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.kBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Scrollbar(
                  thumbVisibility: true,
                  trackVisibility: true,
                  notificationPredicate: (notification) =>
                      notification.depth == 0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 900),
                      child: SingleChildScrollView(
                        child: table,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: data.iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, color: data.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kTextDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ADD / EDIT COLLECTION SHEET (Removed Dialog Wrapping)
// ==========================================
class AddCollectionDialog extends StatefulWidget {
  final List<String> customers;
  final ValueChanged<Map<String, String>>? onSaved;
  final Map<String, String>? existing;

  const AddCollectionDialog(
      {super.key, this.customers = const [], this.onSaved, this.existing});

  @override
  State<AddCollectionDialog> createState() => _AddCollectionDialogState();
}

class _AddCollectionDialogState extends State<AddCollectionDialog> {
  static const List<String> _paymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Cheque'
  ];
  static const List<String> _agents = [
    'Arjun Mehta',
    'Sneha Reddy',
    'Unassigned'
  ];
  static const Map<String, List<String>> _loansByCustomer = {
    'Lakshmi Iyer': ['LN-232037', 'LN-627299', 'LN-DE34F5'],
    'Anjali Singh': ['LN-GH6718'],
    'Ramesh Gowda': ['LN-MN2304'],
    'Vikram Naidu': ['LN-AB12C3'],
  };

  bool get _isEdit => widget.existing != null;

  String? _customer;
  String? _loanNumber;
  final TextEditingController _amountController = TextEditingController();
  String _paymentMethod = 'Cash';
  final TextEditingController _dateController =
      TextEditingController(text: '10/07/2026');
  String? _agent;
  final TextEditingController _notesController = TextEditingController();
  String? _screenshotFileName;
  String? _signatureFileName;

  bool get _canSave =>
      _customer != null &&
      _amountController.text.trim().isNotEmpty &&
      (int.tryParse(_amountController.text.trim()) ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _customer = e['customer'];
      _loanNumber = (e['loan'] != null && e['loan'] != '-') ? e['loan'] : null;
      _amountController.text = _parseAmount(e['amount'] ?? '').toString();
      _paymentMethod = e['method'] ?? 'Cash';
      _dateController.text = e['date'] ?? _dateController.text;
      _agent = e['agent'];
    }
  }

  int _parseAmount(String amount) =>
      int.tryParse(amount.replaceAll(RegExp(r'[₹,]'), '')) ?? 0;

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  void _save() {
    if (!_canSave) return;
    final amountValue = int.tryParse(_amountController.text.trim()) ?? 0;
    final record = <String, String>{
      'customer': _customer!,
      'initials': _initials(_customer!),
      'receipt': _isEdit
          ? widget.existing!['receipt']!
          : 'RCT-${DateTime.now().millisecondsSinceEpoch % 100000000}',
      'loan': _loanNumber ?? '-',
      'amount':
          '₹${amountValue.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
      'date':
          _dateController.text.isEmpty ? '10 Jul 2026' : _dateController.text,
      'method': _paymentMethod,
      'agent': _agent ?? 'Unassigned',
      'status': _isEdit ? widget.existing!['status']! : 'Collected',
    };
    widget.onSaved?.call(record);
    Navigator.of(context).pop();
    ToastService.show(
      title: _isEdit ? 'Collection updated' : 'Collection recorded',
      message: record['customer'],
      type: ToastType.success,
    );
  }

  void _generateReceipt() {
    ToastService.show(
      title: 'Generating receipt...',
      type: ToastType.info,
    );
  }

  Future<void> _pickFile({required bool isSignature}) async {
    setState(() {
      if (isSignature) {
        _signatureFileName =
            'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      } else {
        _screenshotFileName =
            'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableLoans = _customer != null
        ? (_loansByCustomer[_customer] ?? const [])
        : const <String>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isEdit ? 'Edit Collection' : 'Add Collection',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kTextDark)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _label('CUSTOMER *'),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _customer,
            decoration: const InputDecoration(
                hintText: 'Select customer', isDense: true),
            items: widget.customers
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() {
              _customer = v;
              _loanNumber = null;
            }),
          ),
          const SizedBox(height: 16),
          _label('LOAN NUMBER'),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _loanNumber,
            decoration: InputDecoration(
              hintText: _customer == null
                  ? 'Select customer first'
                  : 'Select loan',
              isDense: true,
            ),
            items: availableLoans
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: _customer == null
                ? null
                : (v) => setState(() => _loanNumber = v),
          ),
          const SizedBox(height: 6),
          const Text('Linked to the selected customer',
              style: TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
          const SizedBox(height: 16),
          _label('AMOUNT RECEIVED *'),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                prefixText: '₹  ', hintText: '0', isDense: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _label('PAYMENT METHOD *'),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _paymentMethod,
            decoration: const InputDecoration(isDense: true),
            items: _paymentMethods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) =>
                setState(() => _paymentMethod = v ?? 'Cash'),
          ),
          const SizedBox(height: 16),
          _label('COLLECTION DATE *'),
          TextField(
            controller: _dateController,
            decoration: const InputDecoration(isDense: true),
          ),
          const SizedBox(height: 16),
          _label('AGENT'),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _agent,
            decoration: const InputDecoration(
                hintText: 'Select agent', isDense: true),
            items: _agents
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: (v) => setState(() => _agent = v),
          ),
          const SizedBox(height: 16),
          _label('NOTES'),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Any remarks about this collection...',
                isDense: true),
          ),
          const SizedBox(height: 16),
          _label('PAYMENT SCREENSHOT'),
          _UploadBox(
            fileName: _screenshotFileName,
            onTap: () => _pickFile(isSignature: false),
          ),
          const SizedBox(height: 16),
          _label('CUSTOMER SIGNATURE'),
          _UploadBox(
            fileName: _signatureFileName,
            accent: true,
            onTap: () => _pickFile(isSignature: true),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _canSave ? _generateReceipt : null,
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Receipt'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kSuccess,
                  ),
                  onPressed: _canSave ? _save : null,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(_isEdit ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextMuted)),
      );
}

class _UploadBox extends StatelessWidget {
  final String? fileName;
  final VoidCallback onTap;
  final bool accent;

  const _UploadBox(
      {required this.fileName, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: hasFile
              ? (accent ? const Color(0xFFF0FDF4) : const Color(0xFFF0F5FF))
              : AppColors.kBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: hasFile
                  ? (accent ? AppColors.kSuccess : AppColors.kInfo)
                  : AppColors.kBorder,
              style: hasFile ? BorderStyle.solid : BorderStyle.none),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
              color: hasFile
                  ? (accent ? AppColors.kSuccess : AppColors.kInfo)
                  : AppColors.kTextMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasFile ? fileName! : 'Upload document...',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: hasFile
                      ? (accent ? AppColors.kSuccess : AppColors.kInfo)
                      : AppColors.kTextMuted,
                  fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}