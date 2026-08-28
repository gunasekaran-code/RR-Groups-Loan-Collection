import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/page_header.dart';
import '../../theme/glass_toast.dart';
import '../../theme/confirm_dialog.dart';
import '../../models/account_ledger_model.dart';
import '../../services/account_ledger_service.dart';
import '../../l10n/generated/app_localizations.dart';

String localizedTabLabel(String key, AppLocalizations l10n) {
  switch (key) {
    case 'All Entries':
      return l10n.accountTabAllEntries;
    case 'Cash In Hand':
      return l10n.accountTabCashInHand;
    case 'Outstanding Lent':
      return l10n.accountTabOutstandingLent;
    default:
      return key;
  }
}

class AccountBookScreen extends StatefulWidget {
  const AccountBookScreen({super.key});

  @override
  State<AccountBookScreen> createState() => _AccountBookScreenState();
}

class _AccountBookScreenState extends State<AccountBookScreen> {
  final AccountLedgerService _service = AccountLedgerService();

  String _searchQuery = '';
  String _selectedTab = 'All Entries';

  final List<String> _tabs = [
    'All Entries',
    'Cash In Hand',
    'Outstanding Lent',
  ];

  List<AccountLedgerEntry> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  AccountLedgerSummary? _summary;
  bool _isSummaryLoading = true;
  String? _summaryError;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  // ==========================================
  // DATA LOADING
  // ==========================================
  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final entriesRequest = _service.fetchEntries();
    _refreshSummary();

    try {
      final entries = await entriesRequest;
      entries.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      if (!mounted) return;
      setState(() {
        _transactions = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSummary() async {
    if (!mounted) return;
    setState(() {
      _isSummaryLoading = true;
      _summaryError = null;
    });

    try {
      final summary = await _service.fetchSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isSummaryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = e.toString();
        _isSummaryLoading = false;
      });
    }
  }

  // Filter logic
  List<AccountLedgerEntry> get _filteredTransactions {
    return _transactions.where((tx) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = tx.title.toLowerCase().contains(query) ||
          tx.category.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      if (_selectedTab == 'Cash In Hand') {
        return tx.section == 'Cash In Hand';
      } else if (_selectedTab == 'Outstanding Lent') {
        return tx.section == 'Outstanding Lent';
      }
      return true; // All Entries
    }).toList();
  }

  // Dynamic Button Label based on Active Tab
  String _addButtonLabel(AppLocalizations l10n) {
    if (_selectedTab == 'Cash In Hand') {
      return l10n.accountAddCashEntryButton;
    } else if (_selectedTab == 'Outstanding Lent') {
      return l10n.accountAddMoneyLentButton;
    }
    return l10n.accountAddEntryButton;
  }

  // ==========================================
  // CREATE / EDIT
  // ==========================================
  void _showAddEntryDialog({AccountLedgerEntry? existingEntry}) {
    final l10n = AppLocalizations.of(context);
    final defaultType = _selectedTab == 'Outstanding Lent'
        ? LedgerEntryType.moneyLent
        : LedgerEntryType.cashIn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => _buildGlobalSheetFrame(
        child: AddLedgerEntrySheet(
          service: _service,
          existingEntry: existingEntry,
          initialEntryType: defaultType,
          onSaved: (savedEntry) {
            setState(() {
              final idx =
                  _transactions.indexWhere((t) => t.id == savedEntry.id);
              if (idx != -1) {
                _transactions[idx] = savedEntry;
              } else {
                _transactions.insert(0, savedEntry);
              }
            });
            _refreshSummary();
            ToastService.show(
              title: existingEntry != null
                  ? l10n.accountEntryUpdatedTitle
                  : l10n.accountEntrySavedTitle,
              message: existingEntry != null
                  ? l10n.accountEntryUpdatedMessage
                  : l10n.accountEntrySavedMessage,
              type: ToastType.success,
            );
          },
        ),
      ),
    );
  }

// ==========================================
  // DELETE
  // ==========================================
  Future<void> _handleDelete(AccountLedgerEntry entry) async {
    // Replaced default showDialog with AppConfirmDialog
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.deleteEntry,
      message: l10n.accountDeleteConfirmMessage(entry.title),
      confirmLabel: l10n.delete,
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed != true) return;

    final previous = List<AccountLedgerEntry>.from(_transactions);
    setState(() {
      _transactions.removeWhere((t) => t.id == entry.id);
    });

    try {
      await _service.deleteEntry(entry.id);
      await _refreshSummary();
      if (!mounted) return;
      ToastService.show(
        title: l10n.accountEntryDeletedTitle,
        message: l10n.accountEntryDeletedMessage,
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _transactions = previous);
      ToastService.show(
        title: l10n.accountDeleteFailedTitle,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Widget _buildGlobalSheetFrame({required Widget child}) {
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final double maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppShell(
      currentRoute: AppRoutes.accountBook,
      title: l10n.accountBook,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          final horizontalPadding = isNarrow ? 12.0 : 24.0;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: l10n.accountBook,
                  subtitle: l10n.accountBookSubtitle,
                  // actions: [
                  //   Align(
                  //     alignment: Alignment.centerLeft,
                  //     child: ElevatedButton.icon(
                  //       onPressed: () {},
                  //       icon: const Icon(Icons.print,
                  //           color: Colors.white, size: 18),
                  //       // label: Text(l10n.printStatement),
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: const Color(0xFFB8860B),
                  //         padding: const EdgeInsets.symmetric(
                  //             horizontal: 16, vertical: 12),
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(8),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildNetBalanceSummary(l10n),
                      const SizedBox(height: 16),
                      _buildCashInHandCard(l10n),
                      const SizedBox(height: 16),
                      _buildOutstandingMoneyCard(l10n),
                      const SizedBox(height: 24),
                      _buildFilterAndControlCard(isNarrow, l10n),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildContentArea(isNarrow, l10n),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // NET BALANCE SUMMARY CARD
  // NOTE: these totals combine loan/chit/fund data from elsewhere in the app;
  // only the "refresh" action here also re-syncs the ledger list below.
  // ==========================================
  Widget _buildNetBalanceSummary(AppLocalizations l10n) {
    final summary = _summary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E2C),
            Color(0xFF3A2111),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.accountNetBalanceSummaryTitle}\n',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _loadEntries,
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildDarkSummaryBox(
            l10n.accountCashInHandLabel,
            _summaryAmount(summary?.cashInHand),
          ),
          const SizedBox(height: 12),
          _buildDarkSummaryBox(
            l10n.accountOutstandingLabel,
            _summaryAmount(summary?.outstandingMoneyLent),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB8860B), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.accountNetBalanceLabel,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(_summaryAmount(summary?.netBalance),
                        style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8860B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isSummaryLoading
                        ? l10n.accountUpdatingBadge
                        : l10n.accountLiveBadge,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          if (_summaryError != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.accountSummaryRefreshError(_summaryError!),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDarkSummaryBox(String label, String amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(amount,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ==========================================
  // CASH IN HAND CARD
  // ==========================================
  Widget _buildCashInHandCard(AppLocalizations l10n) {
    final summary = _summary;
    return _buildWhiteCard(
      title: localizedTabLabel('Cash In Hand', l10n),
      subtitle: l10n.accountCashInHandSubtitle,
      amount: _summaryAmount(summary?.cashInHand),
      accentColor: const Color(0xFF10B981),
      icon: Icons.account_balance_wallet_outlined,
      children: [
        _buildBreakdownItem(l10n.accountBreakdownLoanCollection,
            _summaryAmount(summary?.loanCollections), Colors.teal),
        _buildBreakdownItem(l10n.accountBreakdownFundDeposits,
            _summaryAmount(summary?.fundDeposits), Colors.purple),
        _buildBreakdownItem(l10n.accountBreakdownChitCollection,
            _summaryAmount(summary?.chitCollected), Colors.blue),
        _buildBreakdownItem(
          l10n.accountBreakdownCustomCashNet,
          _summaryAmount(summary?.customCashNet, signed: true),
          Colors.orange,
          isPositive: (summary?.customCashNet ?? 0) >= 0,
        ),
      ],
    );
  }

  // ==========================================
  // OUTSTANDING MONEY CARD
  // ==========================================
  Widget _buildOutstandingMoneyCard(AppLocalizations l10n) {
    final summary = _summary;
    return _buildWhiteCard(
      title: l10n.accountOutstandingMoneyTitle,
      subtitle: l10n.accountOutstandingMoneySubtitle,
      amount: _summaryAmount(summary?.outstandingMoneyLent),
      accentColor: const Color(0xFF2563EB),
      icon: Icons.account_balance_outlined,
      children: [
        _buildBreakdownItem(l10n.accountBreakdownLoanOutstanding,
            _summaryAmount(summary?.totalLoanOutstanding), Colors.blue),
        _buildBreakdownItem(l10n.accountBreakdownChitPending,
            _summaryAmount(summary?.chitPendingAmount), Colors.indigo),
        _buildBreakdownItem(l10n.accountBreakdownFundPending,
            _summaryAmount(summary?.fundPendingAmount), Colors.purple),
        _buildBreakdownItem(l10n.accountBreakdownCustomMoneyLent,
            _summaryAmount(summary?.customLentNet), Colors.orange),
      ],
    );
  }

  String _summaryAmount(double? amount, {bool signed = false}) {
    if (_isSummaryLoading || amount == null) return '—';
    final formatted = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount.abs());
    if (!signed || amount == 0) return formatted;
    return '${amount > 0 ? '+' : '-'}$formatted';
  }

  Widget _buildWhiteCard({
    required String title,
    required String subtitle,
    required String amount,
    required Color accentColor,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: accentColor, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(amount,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: accentColor)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String title, String amount, Color color,
      {bool isPositive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.trip_origin, size: 10, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ],
          ),
          Text(amount,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.black87)),
        ],
      ),
    );
  }

  // ==========================================
  // FILTER TABS & SEARCH BAR CONTAINER
  // ==========================================
  Widget _buildFilterAndControlCard(bool isNarrow, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Filter Tabs Box
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((tab) {
                  final isSelected = _selectedTab == tab;

                  IconData icon = Icons.menu_book_outlined;
                  if (tab.contains('Cash In Hand')) {
                    icon = Icons.account_balance_wallet_outlined;
                  } else if (tab.contains('Outstanding Lent')) {
                    icon = Icons.account_balance_outlined;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = tab),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon,
                                size: 16,
                                color: isSelected
                                    ? const Color(0xFF1E293B)
                                    : Colors.black54),
                            const SizedBox(width: 8),
                            Text(
                              localizedTabLabel(tab, l10n),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF1E293B)
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search & Dynamic Add Entry Button
          _buildSearchAndAddControls(isNarrow, l10n),
        ],
      ),
    );
  }

  Widget _buildSearchAndAddControls(bool isNarrow, AppLocalizations l10n) {
    final searchField = TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black45),
        hintText: l10n.accountSearchHint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      onChanged: (v) => setState(() => _searchQuery = v),
    );

    final addButton = ElevatedButton.icon(
      onPressed: () => _showAddEntryDialog(),
      icon: const Icon(Icons.add, size: 18, color: Colors.white),
      label: Text(
        _addButtonLabel(l10n),
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedTab == 'Outstanding Lent'
            ? const Color(0xFF0284C7)
            : const Color(0xFFB8860B),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 10),
          addButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 12),
        addButton,
      ],
    );
  }

  // ==========================================
  // TABLE / LOADING / ERROR / EMPTY STATE AREA
  // ==========================================
  Widget _buildContentArea(bool isNarrow, AppLocalizations l10n) {
    final horizontalPadding = isNarrow ? 12.0 : 24.0;

    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFB8860B)),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 36, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                l10n.accountLoadFailedTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadEntries,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final list = _filteredTransactions;

    if (list.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  size: 36,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.accountEmptyStateTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.accountEmptyStateBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return _buildTransactionsTable(isNarrow, list, l10n);
  }

  Widget _buildTransactionsTable(
      bool isNarrow, List<AccountLedgerEntry> items, AppLocalizations l10n) {
    final table = DataTable(
      columnSpacing: isNarrow ? 20 : 32,
      horizontalMargin: 24,
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
      dataRowMinHeight: 60,
      dataRowMaxHeight: 68,
      headingTextStyle: const TextStyle(
        color: Colors.black54,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      columns: [
        DataColumn(label: Text(l10n.accountColDate)),
        DataColumn(label: Text(l10n.accountColTitle)),
        DataColumn(label: Text(l10n.accountColCategory)),
        DataColumn(label: Text(l10n.accountColSection)),
        DataColumn(label: Text(l10n.accountColType)),
        DataColumn(label: Text(l10n.accountColAmount)),
        DataColumn(label: Text(l10n.accountColActions)),
      ],
      rows: items.map((tx) {
        return DataRow(
          cells: [
            DataCell(Text(tx.displayDate,
                style: const TextStyle(color: Colors.black54, fontSize: 13))),
            DataCell(SizedBox(
              width: 240,
              child: Text(
                tx.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )),
            DataCell(Text(tx.category,
                style: const TextStyle(color: Colors.black, fontSize: 13))),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tx.section == 'Cash In Hand'
                      ? Icons.account_balance_wallet_outlined
                      : Icons.account_balance_outlined,
                  size: 14,
                  color: tx.section == 'Cash In Hand'
                      ? const Color(0xFF10B981)
                      : const Color(0xFF2563EB),
                ),
                const SizedBox(width: 4),
                Text(
                  localizedTabLabel(tx.section, l10n),
                  style: TextStyle(
                    fontSize: 13,
                    color: tx.section == 'Cash In Hand'
                        ? const Color(0xFF10B981)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ],
            )),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tx.typeLabel,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D)),
              ),
            )),
            DataCell(Text(
              tx.displayAmount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: tx.isPositive ? const Color(0xFF16A34A) : Colors.red,
              ),
            )),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: Colors.black54,
                  onPressed: () => _showAddEntryDialog(existingEntry: tx),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: const Color(0xFFEF4444),
                  onPressed: () => _handleDelete(tx),
                ),
              ],
            )),
          ],
        );
      }).toList(),
    );

    final scrollController = ScrollController();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: isNarrow ? 12.0 : 24.0),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: isNarrow ? 760 : 980),
            child: table,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ADD / EDIT LEDGER ENTRY SHEET FORM
// ==========================================
class AddLedgerEntrySheet extends StatefulWidget {
  final AccountLedgerService service;
  final AccountLedgerEntry? existingEntry;
  final String initialEntryType;
  final ValueChanged<AccountLedgerEntry> onSaved;

  const AddLedgerEntrySheet({
    super.key,
    required this.service,
    required this.initialEntryType,
    required this.onSaved,
    this.existingEntry,
  });

  @override
  State<AddLedgerEntrySheet> createState() => _AddLedgerEntrySheetState();
}

class _AddLedgerEntrySheetState extends State<AddLedgerEntrySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;

  late String _selectedEntryType;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEntry;

    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(2),
    );
    _categoryController =
        TextEditingController(text: existing?.category ?? 'Capital');
    _dateController = TextEditingController(
      text: _formatForField(existing?.entryDate ?? DateTime.now()),
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _selectedEntryType = existing?.entryType ?? widget.initialEntryType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatForField(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);

  DateTime? _parseField(String value) {
    final parts = value.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // Open Down-to-Up Stylish Custom Dropdown Sheet
  void _openEntryTypePicker() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF4A4A4A), // Dark Grey backdrop as shown in image
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group 1: Cash In Hand
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Text(
                    localizedTabLabel('Cash In Hand', l10n),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildPickerOption(LedgerEntryType.cashIn),
                _buildPickerOption(LedgerEntryType.capitalInjection),
                _buildPickerOption(LedgerEntryType.officeExpense),
                _buildPickerOption(LedgerEntryType.cashOut),

                const SizedBox(height: 12),

                // Group 2: Outstanding Lent
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Text(
                    localizedTabLabel('Outstanding Lent', l10n),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildPickerOption(LedgerEntryType.moneyLent),
                _buildPickerOption(LedgerEntryType.activeDebtAdjustment),
                _buildPickerOption(LedgerEntryType.overdueDebtAdjustment),
                _buildPickerOption(LedgerEntryType.debtRecovered),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickerOption(String typeCode) {
    final isSelected = _selectedEntryType == typeCode;
    return InkWell(
      onTap: () {
        setState(() => _selectedEntryType = typeCode);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LedgerEntryType.labelFor(typeCode),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context);
    if (_titleController.text.trim().isEmpty) {
      ToastService.show(
        title: l10n.accountMissingTitleTitle,
        message: l10n.accountMissingTitleMessage,
        type: ToastType.error,
      );
      return;
    }

    final parsedDate = _parseField(_dateController.text);
    if (_dateController.text.trim().isNotEmpty && parsedDate == null) {
      ToastService.show(
        title: l10n.accountInvalidDateTitle,
        message: l10n.accountInvalidDateMessage,
        type: ToastType.error,
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final entry = AccountLedgerEntry(
      id: widget.existingEntry?.id ?? '',
      entryType: _selectedEntryType,
      title: _titleController.text.trim(),
      amount: amount,
      category: _categoryController.text.trim().isEmpty
          ? 'General'
          : _categoryController.text.trim(),
      entryDate: parsedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() => _isSaving = true);

    try {
      final saved = _isEditMode
          ? await widget.service.updateEntry(entry)
          : await widget.service.createEntry(entry);

      widget.onSaved(saved);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ToastService.show(
        title: _isEditMode
            ? l10n.accountUpdateFailedTitle
            : l10n.accountSaveFailedTitle,
        message: e.toString(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditMode
                    ? l10n.accountEditEntryTitle
                    : l10n.accountAddEntryTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.black45),
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          _buildLabel(l10n.accountEntryTitleLabel),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            enabled: !_isSaving,
            decoration: _inputDecoration(l10n.accountEntryTitleHint),
          ),
          const SizedBox(height: 16),

          // Responsive Row for Type & Amount
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              final typeField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(l10n.accountEntryTypeLabel),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _isSaving ? null : _openEntryTypePicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              LedgerEntryType.labelFor(_selectedEntryType),
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.unfold_more,
                              size: 18, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              final amountField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(l10n.accountAmountLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    enabled: !_isSaving,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(l10n.accountAmountHint),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    typeField,
                    const SizedBox(height: 16),
                    amountField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: typeField),
                  const SizedBox(width: 16),
                  Expanded(child: amountField),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Responsive Row for Category & Date
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              final catField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(l10n.accountCategoryLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _categoryController,
                    enabled: !_isSaving,
                    decoration: _inputDecoration(''),
                  ),
                ],
              );

              final dateField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(l10n.accountEntryDateLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _dateController,
                    enabled: !_isSaving,
                    decoration: _inputDecoration(l10n.accountEntryDateHint),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    catField,
                    const SizedBox(height: 16),
                    dateField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: catField),
                  const SizedBox(width: 16),
                  Expanded(child: dateField),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Notes
          _buildLabel(l10n.accountNotesLabel),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            enabled: !_isSaving,
            maxLines: 3,
            decoration: _inputDecoration(l10n.accountNotesHint),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline,
                        size: 18, color: Colors.white),
                label: Text(
                  _isEditMode
                      ? l10n.accountUpdateEntryButton
                      : l10n.accountSaveEntryButton,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2A675), // Gold/Tan tone
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}