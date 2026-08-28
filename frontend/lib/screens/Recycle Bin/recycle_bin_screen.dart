import 'package:flutter/material.dart';
import '../../theme/glass_toast.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/confirm_dialog.dart';
import '../../models/recycle_bin.dart';
import '../../services/recycle_bin_api_service.dart';
import '../../l10n/generated/app_localizations.dart';

String formatShortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final dd = d.day.toString().padLeft(2, '0');
  return '$dd ${months[d.month - 1]} ${d.year}';
}

class _Breakpoints {
  static const double narrow = 360;
  static const double phone = 600;
}

bool _isNarrow(double width) => width < _Breakpoints.narrow;
bool _isTablet(double width) => width >= _Breakpoints.phone;

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  bool _isLoading = true;
  String? _loadError;
  List<RecycleBinItem> _items = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String? _inlineSuccessMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final items = await RecycleBinApiService.fetchItems();
      items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));

      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
      ToastService.show(
        title: 'Failed to load recycle bin',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  List<RecycleBinItem> get _filteredItems {
    return _items.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.displayTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.deletedByName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesFilter = _selectedFilter == 'All' || 
          item.formattedTableName == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  List<String> get _availableFilters {
    final Set<String> filters = {'All'};
    for (var item in _items) {
      filters.add(item.formattedTableName);
    }
    return filters.toList();
  }

  Future<void> _restoreItem(RecycleBinItem item) async {
    try {
      await RecycleBinApiService.restoreItem(item.id);
      await _loadData();
      setState(() {
        _inlineSuccessMessage = "${item.formattedTableName} '${item.displayTitle}' restored.";
      });
      
      // Auto-hide success message after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _inlineSuccessMessage = null;
          });
        }
      });
    } catch (e) {
      ToastService.show(
        title: 'Restore failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _deletePermanently(RecycleBinItem item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.recycleBinDeletePermanentlyTitle,
      message: 'Are you sure you want to permanently delete "${item.displayTitle}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: const Color(0xFFE11D48), // Match your red
    );

    if (confirmed == true) {
      try {
        await RecycleBinApiService.deletePermanently(item.id);
        await _loadData();
        ToastService.show(
          title: 'Deleted permanently',
          message: item.displayTitle,
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
  }

  Future<void> _emptyRecycleBin() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.recycleBinEmptyTitle,
      message: l10n.recycleBinEmptyMessage,
      confirmLabel: 'Empty Trash',
      confirmButtonColor: const Color(0xFFE11D48),
    );

    if (confirmed == true) {
      try {
        await RecycleBinApiService.emptyRecycleBin();
        await _loadData();
        setState(() {
          _inlineSuccessMessage = "Recycle bin emptied successfully.";
        });
      } catch (e) {
        ToastService.show(
          title: 'Failed to empty bin',
          message: e.toString(),
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppShell(
      currentRoute: AppRoutes.recycleBin, // Ensure defined in app_routes.dart
      title: l10n.recycleBinTitle,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final narrow = _isNarrow(width);
          final tablet = _isTablet(width);
          final hPad = narrow ? 12.0 : (tablet ? 24.0 : 16.0);
          final filteredData = _filteredItems;

          return RefreshIndicator(
            onRefresh: _loadData,
            child: _isLoading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null && _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_loadError!, style: const TextStyle(color: AppColors.kDanger)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
                        children: [
                          Text(
                            l10n.recycleBinTitle,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.kTextDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.recycleBinSubtitle,
                            style: const TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                          ),
                          const SizedBox(height: 16),

                          // Empty Recycle Bin Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: _items.where((i) => !i.isRestored).isEmpty ? null : _emptyRecycleBin,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(l10n.recycleBinEmptyButton),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE11D48), // Rose Red
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),

                          // Inline Success Message
                          if (_inlineSuccessMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _inlineSuccessMessage!,
                                style: const TextStyle(color: Color(0xFF166534), fontSize: 13),
                              ),
                            ),

                          // Filters & Search Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.kBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                    hintText: l10n.recycleBinSearchHint,
                                    prefixIcon: const Icon(Icons.search, color: AppColors.kTextMuted),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.kBorder),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                ),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _availableFilters.map((filter) {
                                      final isSelected = _selectedFilter == filter;
                                      final countText = filter == 'All' ? ' (${_items.length})' : '';
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text('$filter$countText'),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() => _selectedFilter = filter);
                                            }
                                          },
                                          selectedColor: const Color(0xFFB48629), // Gold tone from Promo popup
                                          labelStyle: TextStyle(
                                            color: isSelected ? Colors.white : AppColors.kTextDark,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${filteredData.length} items can still be restored • updates live every 30s',
                                  style: const TextStyle(color: AppColors.kTextMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // List of Items
                          if (filteredData.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(l10n.recycleBinNoItems, style: const TextStyle(color: AppColors.kTextMuted)),
                              ),
                            )
                          else
                            ...filteredData.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _RecycleBinCard(
                                    item: item,
                                    onRestore: () => _restoreItem(item),
                                    onDelete: () => _deletePermanently(item),
                                  ),
                                )),
                        ],
                      ),
          );
        },
      ),
    );
  }
}

class _RecycleBinCard extends StatelessWidget {
  final RecycleBinItem item;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _RecycleBinCard({
    required this.item,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.displayTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.kTextDark),
                ),
              ),
              if (item.isRestored)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    l10n.recycleBinRestoredBadge,
                    style: const TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Table Badge (Purple)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.formattedTableName,
              style: const TextStyle(color: Color(0xFF7E22CE), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

          // User Info
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.kTextMuted),
              const SizedBox(width: 6),
              Text(
                '${item.deletedByName ?? 'Unknown'} · ${item.deletedByRole ?? 'User'}',
                style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Date Info
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.kTextMuted),
              const SizedBox(width: 6),
              Text(
                formatShortDate(item.deletedAt),
                style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Linked Records (Child Count)
          if (item.childCount > 0)
            Row(
              children: [
                const Icon(Icons.layers_outlined, size: 14, color: Color(0xFFB48629)),
                const SizedBox(width: 6),
                Text(
                  '${item.childCount} linked record${item.childCount > 1 ? 's' : ''} saved with it',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFB48629)),
                ),
              ],
            ),
            
          if (!item.isRestored) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l10n.recycleBinRestoreLabel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextDark,
                      side: const BorderSide(color: AppColors.kBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48), // Rose Red
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}