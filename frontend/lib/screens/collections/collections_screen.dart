import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/confirm_dialog.dart';
import '../../widgets/page_header.dart';
import '../../theme/glass_toast.dart';
import '../../services/collection_api_service.dart';
import '../../services/loan_service.dart';
import '../../models/customer.dart';
import '../../models/loan_record.dart';
import '../../models/repayment_installment.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../widgets/app_upload.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  String _query = '';
  String _period = 'All';
  bool _isLoading = true; // NEW
  String? _loadError; // NEW

  final List<String> _periods = const [
    'Today',    'This Week',    'This Month',    'All'
  ];

  static final DateTime _today = DateTime.now(); 
  List<Map<String, String>> _collections = [];
  final Map<String, String> _receiptToId = {}; // receipt_number -> id
  List<Customer> _customers = [];
  List<LoanRecord> _allLoans = [];
  List<String> _agentNames = [];
  Map<String, List<RepaymentInstallment>> _schedulesByLoan = {};

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  // ---------- API <-> UI mapping ----------

  static const Map<int, String> _monthNames = {
    1: 'Jan',    2: 'Feb',    3: 'Mar',    4: 'Apr',    5: 'May',    6: 'Jun',    7: 'Jul',
    8: 'Aug',    9: 'Sep',    10: 'Oct',    11: 'Nov',    12: 'Dec',
  };

  String _formatApiDate(dynamic raw) {
    if (raw == null) return '-';
    final s = raw.toString();
    // Expecting 'YYYY-MM-DD' or a full datetime string from MySQL
    try {
      final dt = DateTime.parse(s);
      final month = _monthNames[dt.month] ?? '';
      final day = dt.day.toString().padLeft(2, '0');
      return '$day $month ${dt.year}';
    } catch (_) {
      return s;
    }
  }

  String _formatAmount(dynamic raw) {
    final value = double.tryParse(raw?.toString() ?? '0') ?? 0;
    final intValue = value.round();
    final s = intValue.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0) buf.write(',');
    }
    return '₹$buf';
  }

  String _formatMethod(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'cash':
        return 'Cash';
      case 'upi':
        return 'UPI';
      case 'bank':
        return 'Bank Transfer';
      case 'cheque':
        return 'Cheque';
      case 'card':
        return 'Card';
      default:
        return (raw ?? '-').toString();
    }
  }

  String _apiMethodValue(String uiMethod) {
    switch (uiMethod) {
      case 'Cash':
        return 'cash';
      case 'UPI':
        return 'upi';
      case 'Bank Transfer':
        return 'bank';
      case 'Cheque':
        return 'cheque';
      case 'Card':
        return 'card';
      default:
        return 'cash';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Map<String, String> _mapRow(Map<String, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    final receipt = (row['receipt_number'] ?? '').toString();
    final customerName = (row['customer_name'] ?? '').toString();
    final loanType =
        (row['loan_type'] ?? row['collection_type'] ?? '').toString().trim();
    final loanNumber = (row['loan_number'] ?? '-').toString();

    if (id.isNotEmpty && receipt.isNotEmpty) {
      _receiptToId[receipt] = id;
    }

    return {
      'id': id, 
      'customer_id': (row['customer_id'] ?? '').toString(),
      'customer': customerName.isEmpty ? '-' : customerName,
      'initials': _initials(customerName.isEmpty ? '-' : customerName),
      'receipt': receipt.isEmpty ? '-' : receipt,
      'loan': loanNumber,
      'loan_id': (row['loan_id'] ?? '').toString(),
      'loan_type': loanType.isEmpty ? '-' : loanType,
      'amount': _formatAmount(row['collection_amount']),
      'date': _formatApiDate(row['collection_date']),
      'method': _formatMethod(row['payment_method']),
      'agent': (row['agent_name'] ?? 'Unassigned').toString(),
      'agent_id': (row['agent_id'] ?? '').toString(),
      'notes': (row['notes'] ?? '').toString(),
      'status': 'Collected',
    };
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final customers = await LoanService.instance.fetchCustomers();
      final agents = await LoanService.instance.fetchAgents();
      final loans = await LoanService.instance.fetchLoans(
        customers: customers,
        agents: agents,
      );
      final schedules = <String, List<RepaymentInstallment>>{};
      for (final loan in loans) {
        schedules[loan.id] =
            await LoanService.instance.fetchRepaymentSchedule(loan.id);
      }
      final rows = await CollectionApiService.fetchCollections();
      final mapped = rows.map(_mapRow).toList();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _allLoans = loans;
        _agentNames = agents.map((agent) => agent.name).toList()..sort();
        _schedulesByLoan = schedules;
        _collections = mapped;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
      ToastService.show(
        title: 'Failed to load collections',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  int _parseAmount(String amount) =>
      int.tryParse(amount.replaceAll(RegExp(r'[₹,]'), '')) ?? 0;

  static const Map<String, int> _months = {
    'Jan': 1,    'Feb': 2,    'Mar': 3,    'Apr': 4,    'May': 5,    'Jun': 6,    'Jul': 7,    'Aug': 8,    'Sep': 9,    'Oct': 10,    'Nov': 11,    'Dec': 12,
  };

  DateTime? _parseDate(String date) {
    final isoDate = DateTime.tryParse(date);
    if (isoDate != null) {
      return DateTime(isoDate.year, isoDate.month, isoDate.day);
    }
    final slashParts = date.split('/');
    if (slashParts.length == 3) {
      final day = int.tryParse(slashParts[0]);
      final month = int.tryParse(slashParts[1]);
      final year = int.tryParse(slashParts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
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
            c['loan_type']!.toLowerCase().contains(q) ||
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

  Map<String, List<LoanRecord>> get _loansByCustomerId {
    final byCustomerId = <String, List<LoanRecord>>{};
    for (final customer in _customers) {
      byCustomerId.putIfAbsent(customer.id, () => <LoanRecord>[]);
    }
    for (final loan in _allLoans) {
      final customer = _customers.where((item) =>
          item.id == loan.customerId || item.customerId == loan.customerId ||
          item.fullName == loan.customerName).firstOrNull;
      if (customer != null) {
        byCustomerId.putIfAbsent(customer.id, () => <LoanRecord>[]);
        byCustomerId[customer.id]!.add(loan);
        continue;
      }
      final customerId = loan.customerId;
      if (customerId != null && customerId.isNotEmpty) {
        byCustomerId.putIfAbsent(customerId, () => <LoanRecord>[]);
        byCustomerId[customerId]!.add(loan);
      }
    }
    for (final entry in byCustomerId.entries) {
      entry.value.sort((a, b) => a.loanNumber.compareTo(b.loanNumber));
    }
    return byCustomerId;
  }

  void _showAddCollectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: AddCollectionDialog(
          customers: _customers,
          loansByCustomer: _loansByCustomerId,
          agents: _agentNames,
          schedulesByLoan: _schedulesByLoan,
          onSaved: (record) => _createCollectionOnBackend(record),
        ),
      ),
    );
  }

  void _showEditCollectionDialog(Map<String, String> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => _buildGlobalSheetFrame(
        child: AddCollectionDialog(
          customers: _customers,
          loansByCustomer: _loansByCustomerId,
          agents: _agentNames,
          schedulesByLoan: _schedulesByLoan,
          existing: record,
          onSaved: (updated) =>
              _updateCollectionOnBackend(record, updated),
        ),
      ),
    );
  }

  // NEW: build the JSON payload the CollectionController expects and POST it
  Future<void> _createCollectionOnBackend(Map<String, String> record) async {
    try {
      final payload = {
        'receipt_number': record['receipt'],
        'customer_id': record['customer_id'],
        'customer_name': record['customer'],
        'loan_id': record['loan_id'],
        'loan_number': record['loan'] == '-' ? null : record['loan'],
        'loan_type': record['loan_type'] == '-' ? null : record['loan_type'],
        'collection_amount': _parseAmount(record['amount'] ?? '0'),
        'payment_method': _apiMethodValue(record['method'] ?? 'Cash'),
        'collection_date': _toIsoDate(record['date']),
        'agent_id': record['agent_id'],
        'agent_name': record['agent'],
        'notes': record['notes'],
        if (record['payment_screenshot'] != null)
          'payment_screenshot': record['payment_screenshot'],
        if (record['customer_signature'] != null)
          'customer_signature': record['customer_signature'],
      };
      await CollectionApiService.createCollection(payload);
      await _loadCollections(); // refresh from source of truth
      ToastService.show(
        title: 'Collection recorded',
        message: record['customer'] ?? '',
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Failed to save collection',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  // NEW: PATCH by real id (looked up via receipt number)
 Future<void> _updateCollectionOnBackend(
      Map<String, String> original, Map<String, String> updated) async {
    final id = original['id'];
    if (id == null || id.isEmpty) {
      ToastService.show(
        title: 'Update failed',
        message: 'Could not find record id',
        type: ToastType.error,
      );
      return;
    }
    try {
      final payload = {
        'receipt_number': updated['receipt'],
        'customer_id': updated['customer_id'],
        'customer_name': updated['customer'],
        'loan_id': updated['loan_id'],
        'loan_number': updated['loan'] == '-' ? null : updated['loan'],
        'loan_type': updated['loan_type'] == '-' ? null : updated['loan_type'],
        'collection_amount': _parseAmount(updated['amount'] ?? '0'),
        'payment_method': _apiMethodValue(updated['method'] ?? 'Cash'),
        'collection_date': _toIsoDate(updated['date']),
        'agent_id': updated['agent_id'],
        'agent_name': updated['agent'],
        'notes': updated['notes'],
        if (updated['payment_screenshot'] != null)
          'payment_screenshot': updated['payment_screenshot'],
        if (updated['customer_signature'] != null)
          'customer_signature': updated['customer_signature'],
      };
      await CollectionApiService.updateCollection(id, payload);
      await _loadCollections();
      ToastService.show(
        title: 'Collection updated',
        message: updated['customer'] ?? '',
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Failed to update collection',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  String? _toIsoDate(String? uiDate) {
    final dt = _parseDate(uiDate ?? '');
    if (dt == null) return null;
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmDialog(Map<String, String> record) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Collection',
      message:
          'Delete the collection record for ${record['customer']} (${record['receipt']})? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );

        if (confirmed == true && mounted) {
      final id = record['id'];
      if (id == null || id.isEmpty) {
        ToastService.show(
          title: 'Delete failed',
          message: 'Could not find record id',
          type: ToastType.error,
        );
        return;
      }
      try {
        await CollectionApiService.deleteCollection(id);
        await _loadCollections();
        ToastService.show(
          title: 'Collection deleted',
          message: record['receipt'],
          type: ToastType.success,
        );
      } catch (e) {
        ToastService.show(
          title: 'Failed to delete collection',
          message: e.toString(),
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppShell(
      currentRoute: AppRoutes.collections,
      title: 'Collections',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load collections',
                          style: TextStyle(color: scheme.error)),
                      const SizedBox(height: 8),
                      Text(_loadError!,
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCollections,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 700;
                    return RefreshIndicator(
                      onRefresh: _loadCollections,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PageHeader(
                              title: 'Collections',
                              subtitle:
                                  'Record and track daily collections across all loans',
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
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
      padding:
          EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 24, vertical: 8),
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
                              color: Colors.black.withValues(alpha: 0.06),
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
      dataRowMinHeight: 60, 
      dataRowMaxHeight: 70, 
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
        DataColumn(label: Text('LOAN NUMBER')), // Header changed
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
                backgroundColor: const Color(0xFFB38222), // Golden-brown matching image
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c['customer']!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(c['receipt']!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.kTextMuted)),
                  // Removed the 3rd line containing loan and loan_type
                ],
              ),
            ],
          )),
          DataCell(Text(c['loan']!)), // Removed the newline and loan_type
          DataCell(Text(c['amount']!,
              style: const TextStyle(fontWeight: FontWeight.w700))),
          DataCell(
            // Styled as a pill/chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE4F0FF), 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                c['method']!,
                style: const TextStyle(
                  color: Color(0xFF4A90E2), 
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          DataCell(Text(c['date']!)),
          DataCell(Text(c['agent']!)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reordered to: Edit, Print, Delete
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.kTextMuted,
                onPressed: () => _showEditCollectionDialog(c),
                tooltip: 'Edit',
              ),
              // IconButton(
              //   icon: const Icon(Icons.print_outlined, size: 20),
              //   color: AppColors.kTextMuted,
              //   onPressed: () => _printReceipt(c),
              //   tooltip: 'Print',
              // ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Number (Starting) and Icon (End)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Value / Number -> Starting, Top
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: const TextStyle(
                      color: AppColors.kTextDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Icon -> End, Top
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 18),
              ),
            ],
          ),

          const Spacer(), // Pushes text label to the bottom

          // Bottom Section: Text Label -> Starting, Down
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.kTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
  final List<Customer> customers;
  final Map<String, List<LoanRecord>> loansByCustomer;
  final List<String> agents;
  final Map<String, List<RepaymentInstallment>> schedulesByLoan;
  final ValueChanged<Map<String, String>>? onSaved;
  final Map<String, String>? existing;

  const AddCollectionDialog({
    super.key,
    this.customers = const [],
    this.loansByCustomer = const {},
    this.agents = const [],
    this.schedulesByLoan = const {},
    this.onSaved,
    this.existing,
  });

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
  bool get _isEdit => widget.existing != null;

  String? _customerId;
  String? _loanNumber;
  final TextEditingController _amountController = TextEditingController();
  String _paymentMethod = 'Cash';
  final TextEditingController _dateController = TextEditingController();
  String? _agent;
  String? _paymentPurpose;
  final TextEditingController _notesController = TextEditingController();
  String? _screenshotFileName;
  String? _signatureFileName;
  XFile? _screenshotFile;
  XFile? _signatureFile;

  Customer? get _selectedCustomer {
    for (final customer in widget.customers) {
      if (customer.id == _customerId) return customer;
    }
    return null;
  }

  List<LoanRecord> get _availableLoans => _customerId == null
      ? const []
      : (widget.loansByCustomer[_customerId] ?? const []);

  LoanRecord? get _selectedLoan {
    for (final loan in _availableLoans) {
      if (loan.loanNumber == _loanNumber) return loan;
    }
    return null;
  }

  List<RepaymentInstallment> _scheduleFor(LoanRecord loan) =>
      widget.schedulesByLoan[loan.id] ?? const [];

  List<RepaymentInstallment> _unpaidScheduleFor(LoanRecord loan) =>
      _scheduleFor(loan)
          .where((item) => item.balance > 0 || item.status != 'paid')
          .toList();

  double _nextInstallmentAmount(LoanRecord loan) {
    final unpaid = _unpaidScheduleFor(loan);
    return unpaid.isNotEmpty ? unpaid.first.balance : loan.emiAmount;
  }

  double _overdueDueAmount(LoanRecord loan) {
    final now = DateTime.now();
    final overdue = _unpaidScheduleFor(loan).where((item) {
      final dueDate = item.dueDate;
      return item.status.toLowerCase() == 'overdue' ||
          (dueDate != null && dueDate.isBefore(now));
    });
    return overdue.fold<double>(
        0, (total, item) => total + item.balance + item.penaltyAmount);
  }

  double _fullBalance(LoanRecord loan) {
    final schedule = _scheduleFor(loan);
    if (schedule.isEmpty) return loan.outstandingBalance + loan.penaltyAmount;
    return schedule.fold<double>(
        0, (total, item) => total + item.balance + item.penaltyAmount);
  }

  String get _customerName => _selectedCustomer?.fullName ?? '';

  bool get _canSave =>
      _customerId != null &&
      _amountController.text.trim().isNotEmpty &&
      (int.tryParse(_amountController.text.trim()) ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final e = widget.existing;
    if (e != null) {
      final existingCustomerId = e['customer_id'];
      if (existingCustomerId != null && existingCustomerId.isNotEmpty) {
        final match = widget.customers
            .where((c) => c.id == existingCustomerId)
            .firstOrNull;
        if (match != null) _customerId = match.id;
      }
      if (_customerId == null) {
        for (final customer in widget.customers) {
          if (customer.fullName == e['customer']) {
            _customerId = customer.id;
            break;
          }
        }
      }
      _loanNumber = (e['loan'] != null && e['loan'] != '-') ? e['loan'] : null;
      _amountController.text = _parseAmount(e['amount'] ?? '').toString();
      _paymentMethod = e['method'] ?? 'Cash';
      _dateController.text = e['date'] ?? _dateController.text;
      _agent = e['agent'];
      _notesController.text = e['notes'] ?? '';
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

  Future<void> _save() async {
    if (!_canSave) return;
    final customer = _selectedCustomer;
    if (customer == null) {
      ToastService.show(
        title: 'Select a customer',
        message: 'Please choose a customer before saving.',
        type: ToastType.error,
      );
      return;
    }
    final amountValue = int.tryParse(_amountController.text.trim()) ?? 0;
    final selectedDate = _dateController.text.isEmpty
        ? _formatCurrentDate()
        : _dateController.text;

    final screenshotBase64 = _screenshotFile != null
        ? base64Encode(await _screenshotFile!.readAsBytes())
        : null;
    final signatureBase64 = _signatureFile != null
        ? base64Encode(await _signatureFile!.readAsBytes())
        : null;

    final record = <String, String>{
      'customer_id': customer.id,
      'customer': _customerName,
      'initials': _initials(_customerName),
      'receipt': _isEdit
          ? widget.existing!['receipt']!
          : 'RCP-${(DateTime.now().millisecondsSinceEpoch % 100000000).toString().padLeft(8, '0')}',
      if (_isEdit && widget.existing!['id'] != null) 'id': widget.existing!['id']!,
      'loan': _loanNumber ?? '-',
      if (_selectedLoan != null) ...{
        'loan_id': _selectedLoan!.id,
        'loan_type': _selectedLoan!.collectionType.toLowerCase(),
      },
      'amount':
          '₹${amountValue.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
      'date': selectedDate,
      'method': _paymentMethod,
      'agent': _agent ?? 'Unassigned',
      if (_selectedLoan?.agentId != null) 'agent_id': _selectedLoan!.agentId!,
      'status': _isEdit ? widget.existing!['status']! : 'Collected',
      'notes': [
        if (_paymentPurpose != null) _paymentPurpose!,
        if (_notesController.text.trim().isNotEmpty) _notesController.text.trim(),
      ].join(' | '),
      if (screenshotBase64 != null) 'payment_screenshot': screenshotBase64,
      if (signatureBase64 != null) 'customer_signature': signatureBase64,
    };
    if (!mounted) return;
    widget.onSaved?.call(record);
    Navigator.of(context).pop();
    ToastService.show(
      title: _isEdit ? 'Collection updated' : 'Collection recorded',
      message: record['customer'],
      type: ToastType.success,
    );
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  void _generateReceipt() {
    ToastService.show(
      title: 'Generating receipt...',
      type: ToastType.info,
    );
  }

  Future<void> _pickFile({required bool isSignature}) async {
    final XFile? picked = await AppUpload.showImagePickerModal(
      context,
      title: isSignature ? 'Add Customer Signature' : 'Upload Payment Screenshot',
    );
    if (picked == null) return;
    setState(() {
      if (isSignature) {
        _signatureFile = picked;
        _signatureFileName = picked.name;
      } else {
        _screenshotFile = picked;
        _screenshotFileName = picked.name;
      }
    });
  }

  Future<void> _selectCollectionDate() async {
    final current = _parseCollectionDate(_dateController.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _dateController.text =
          '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}';
    });
  }

  DateTime? _parseCollectionDate(String value) {
    final iso = DateTime.tryParse(value);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final slash = value.split('/');
    if (slash.length == 3) {
      final day = int.tryParse(slash[0]);
      final month = int.tryParse(slash[1]);
      final year = int.tryParse(slash[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = value.split(' ');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = months[parts[1]];
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  String _loanTypeLabel(LoanRecord loan) {
    if (loan.collectionType == 'Monthly' &&
        (loan.notes ?? '').contains('[[subtype:monthly_interest]]')) {
      return 'Monthly Interest';
    }
    return loan.collectionType == 'Monthly' ? 'Monthly EMI' : loan.collectionType;
  }

  void _setAmountWithPurpose(double amount, String? purpose) {
    _amountController.text = amount.round().toString();
    _paymentPurpose = purpose;
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
    setState(() {});
  }

  Widget _buildLoanSummary(LoanRecord loan) {
    final totalDue = _fullBalance(loan);
    final overdueDue = _overdueDueAmount(loan);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.kBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_loanTypeLabel(loan)} • ${loan.status}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Agent: ${loan.agentName}'),
          Text('Principal: ${loan.formattedAmount}'),
          Text('Installment: ${LoanRecord.formatRupees(_nextInstallmentAmount(loan))}'),
          Text('Outstanding: ${loan.formattedOutstanding}'),
          Text('Overdue due: ${LoanRecord.formatRupees(overdueDue)}'),
          Text('Penalty: ${loan.formattedPenalty}'),
          Text('Total due: ${LoanRecord.formatRupees(totalDue)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildAmountPresets(LoanRecord loan) {
    final installment = _nextInstallmentAmount(loan);
    final principalPartPayment = loan.outstandingBalance;
    final fullBalance = _fullBalance(loan);
    final overdueDue = _overdueDueAmount(loan);
    final isInterestOnly = _loanTypeLabel(loan) == 'Monthly Interest';

    Widget preset(String label, double amount, IconData icon,
        [String? purpose]) {
      return OutlinedButton.icon(
        onPressed: () => _setAmountWithPurpose(amount, purpose),
        icon: Icon(icon, size: 16),
        label: Text('$label (${LoanRecord.formatRupees(amount)})'),
      );
    }

    final entered = _parseAmount(_amountController.text).toDouble();
    final remaining = (fullBalance - entered).clamp(0, double.infinity).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            preset(isInterestOnly ? 'Fill Interest' : '1 EMI', installment,
              Icons.bolt,
              isInterestOnly ? 'Monthly Interest Payment' : null),
            if (overdueDue > 0)
              preset('Pay Due Amount', overdueDue, Icons.warning_amber_outlined),
            preset('Principal Part-Payment', principalPartPayment,
              Icons.payments_outlined, 'Principal Part-Payment'),
            preset('Full Balance', fullBalance, Icons.bolt),
          ],
        ),
        if (entered > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Payment: ${LoanRecord.formatRupees(entered)} • Remaining balance: ${LoanRecord.formatRupees(remaining)}',
            style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerOptions = [...widget.customers]
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final availableLoans = _availableLoans;
    final selectedLoan = _selectedLoan;

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
            initialValue: _customerId,
            decoration: const InputDecoration(
                hintText: 'Select customer', isDense: true),
            items: customerOptions
                .map((customer) => DropdownMenuItem(
                    value: customer.id,
                    child: Text('${customer.fullName} (${customer.customerId})')))
                .toList(),
            onChanged: (v) => setState(() {
              _customerId = v;
              _loanNumber = null;
              _agent = null;
              _amountController.clear();
            }),
          ),
          const SizedBox(height: 16),
          _label('LOAN NUMBER'),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _loanNumber,
            decoration: InputDecoration(
              hintText:
                  _customerId == null ? 'Select customer first' : 'Select loan',
              isDense: true,
            ),
            items: availableLoans
                .map((loan) => DropdownMenuItem(
                    value: loan.loanNumber,
                    child: Text(
                      '${loan.loanNumber} • ${LoanRecord.formatRupees(loan.principalAmount)} • '
                      '${_loanTypeLabel(loan)}: ${LoanRecord.formatRupees(loan.emiAmount)} • '
                      'Out: ${loan.formattedOutstandingWithPenalty} (${loan.status})',
                    ),
                  ))
                .toList(),
            onChanged: _customerId == null
                ? null
                : (v) => setState(() {
                    _loanNumber = v;
                    _agent = _selectedLoan?.agentName;
                  }),
          ),
          const SizedBox(height: 6),
          Text(
              selectedLoan == null
                  ? 'Select a loan to view its live details'
                  : '${availableLoans.length} loan${availableLoans.length == 1 ? '' : 's'} linked to the selected customer',
              style: TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
          if (selectedLoan != null) ...[
            const SizedBox(height: 12),
            _buildLoanSummary(selectedLoan),
            const SizedBox(height: 12),
            _buildAmountPresets(selectedLoan),
          ],
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
            initialValue: _paymentMethod,
            decoration: const InputDecoration(isDense: true),
            items: _paymentMethods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _paymentMethod = v ?? 'Cash'),
          ),
          const SizedBox(height: 16),
          _label('COLLECTION DATE *'),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _selectCollectionDate,
            decoration: const InputDecoration(
              isDense: true,
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          _label('AGENT'),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _agent,
            decoration:
                const InputDecoration(hintText: 'Select agent', isDense: true),
            items: {
              ...widget.agents,
              'Unassigned',
              if (selectedLoan?.agentName.isNotEmpty == true)
                selectedLoan!.agentName,
            }
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
              hasFile
                  ? Icons.check_circle_outline
                  : Icons.cloud_upload_outlined,
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
