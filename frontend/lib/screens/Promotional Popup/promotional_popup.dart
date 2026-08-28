import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/glass_toast.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/confirm_dialog.dart';
import '../../models/promo_popup.dart';
import '../../models/user_role.dart';
import '../../services/promo_popup_api_service.dart';
import '../../services/session_service.dart';
import 'package:image_picker/image_picker.dart';

String formatDate(DateTime d) {
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

Future<void> showActivePromoPopup(BuildContext context) async {
  if (!SessionService.instance.claimPromoPopupAttempt()) return;

  PromoPopup? activePopup;
  try {
    final popups = await PromoPopupApiService.fetchPopups();
    for (final popup in popups) {
      if (popup.isActive && _isRenderableImage(popup.imageUrl)) {
        activePopup = popup;
        break;
      }
    }
  } catch (_) {
    return;
  }

  if (!context.mounted || activePopup == null) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.82),
    builder: (dialogContext) {
      final screenSize = MediaQuery.of(dialogContext).size;
      final double maxDialogWidth =
          screenSize.width < 500 ? screenSize.width * 0.92 : 420.0;
      final double maxDialogHeight = screenSize.height * 0.82;

      const goldLight = Color(0xFFF5D687);
      const goldMid = Color(0xFFB48629);
      const goldDark = Color(0xFF7A5613);

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxDialogWidth,
                maxHeight: maxDialogHeight,
              ),
              child: Container(
                // Outer gold gradient frame
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [goldLight, goldMid, goldDark, goldMid, goldLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: goldMid.withOpacity(0.55),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  // Thin dark inlay so the gold reads as a "frame" edge, not just a border
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF1E1128),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Container(
                          color: Colors.white,
                          child: _BannerImage(
                            imageUrl: activePopup!.imageUrl,
                            width: maxDialogWidth,
                            height: maxDialogHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // Advertisement ribbon
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [goldLight, goldMid],
                              ),
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Text(
                              'ADVERTISEMENT',
                              style: TextStyle(
                                color: Color(0xFF3A2405),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Close button, gold-ringed to match frame
            Positioned(
              top: -18,
              right: -6,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [goldLight, goldMid],
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                padding: const EdgeInsets.all(2.5),
                child: Material(
                  color: const Color(0xFF1E1128),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Close advertisement',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, color: goldLight, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}


bool _isRenderableImage(String imageUrl) =>
    imageUrl.startsWith('http') || imageUrl.startsWith('data:image');

class PromoPopupScreen extends StatefulWidget {
  const PromoPopupScreen({super.key});

  @override
  State<PromoPopupScreen> createState() => _PromoPopupScreenState();
}

class _PromoPopupScreenState extends State<PromoPopupScreen> {
  bool _isLoading = true;
  String? _loadError;
  List<PromoPopup> _popups = [];

  bool get _isAdmin => SessionService.instance.role == UserRole.admin;

  PromoPopup? get _activeBanner {
    try {
      return _popups.firstWhere((p) => p.isActive);
    } catch (_) {
      return null;
    }
  }

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
      final popups = await PromoPopupApiService.fetchPopups();
      // Sort by creation date descending
      popups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (!mounted) return;
      setState(() {
        _popups = popups;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
      ToastService.show(
        title: 'Failed to load popups',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _openManageDialog({PromoPopup? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildSheetFrame(
        child: _PromoPopupFormDialog(existing: existing),
      ),
    );
    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _togglePublishState(PromoPopup popup, bool makeActive) async {
    try {
      await PromoPopupApiService.toggleActive(popup.id, makeActive);
      await _loadData();
      ToastService.show(
        title: makeActive ? 'Banner Published' : 'Banner Deactivated',
        message: popup.title,
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Update failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _deleteBanner(PromoPopup popup) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Poster Banner?',
      message: 'Are you sure you want to delete "${popup.title}" from history? It will be moved to the Recycle Bin and can be restored later.',
      confirmLabel: 'Delete Poster',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true) {
      try {
        await PromoPopupApiService.deletePopup(popup.id);
        await _loadData();
        ToastService.show(
          title: 'Banner deleted',
          message: popup.title,
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

  Widget _buildSheetFrame({required Widget child}) {
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final double maxSheetHeight = MediaQuery.of(context).size.height * 0.9;

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
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.promotionalPopup, // Define this in app_routes.dart
      title: _isAdmin ? 'Promotional Popup Management' : 'Latest Offers',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final narrow = _isNarrow(width);
          final tablet = _isTablet(width);
          final hPad = narrow ? 12.0 : (tablet ? 24.0 : 16.0);

          return RefreshIndicator(
            onRefresh: _loadData,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
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
                            _isAdmin
                                ? 'Manage website promotional banners, upload new posters, and track banner history in real time.'
                                : 'View the latest promotional offers from RR Groups.',
                            style: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                          ),
                          if (_isAdmin) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: narrow ? double.infinity : 220,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openManageDialog(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Upload New Banner'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB48629),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _ActiveBannerHero(
                            activeBanner: _activeBanner,
                            isAdmin: _isAdmin,
                            onUpload: _isAdmin ? () => _openManageDialog() : null,
                            onDisable: _isAdmin ? () => _togglePublishState(_activeBanner!, false) : null,
                            narrow: narrow,
                          ),
                          const SizedBox(height: 24),
                          if (_isAdmin) Container(
                            padding: EdgeInsets.all(narrow ? 14 : 20),
                            decoration: BoxDecoration(
                              color: AppColors.kSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.kBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.kTextDark),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Promotional Banner History (${_popups.length})',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.kTextDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "All past uploaded posters and promotional campaign banners. Click 'Publish Live' to switch active poster.",
                                  style: TextStyle(color: AppColors.kTextMuted, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: AppColors.kBorder),
                                const SizedBox(height: 16),
                                if (_popups.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 30),
                                    child: Center(
                                      child: Text(
                                        'No banner history available.',
                                        style: TextStyle(color: AppColors.kTextMuted),
                                      ),
                                    ),
                                  )
                                else
                                  ..._popups.map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _HistoryCard(
                                      popup: p,
                                      narrow: narrow,
                                      onEdit: () => _openManageDialog(existing: p),
                                      onDelete: () => _deleteBanner(p),
                                      onToggleActive: () => _togglePublishState(p, !p.isActive),
                                    ),
                                  )),
                              ],
                            ),
                          ),
                        ],
                      ),
          );
        },
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// HERO SECTION (image_5ab698.jpg / image_5aba01.jpg)
/// -----------------------------------------------------------------------
class _ActiveBannerHero extends StatelessWidget {
  final PromoPopup? activeBanner;
  final bool isAdmin;
  final VoidCallback? onUpload;
  final VoidCallback? onDisable;
  final bool narrow;

  const _ActiveBannerHero({
    this.activeBanner,
    required this.isAdmin,
    required this.onUpload,
    required this.onDisable,
    required this.narrow,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasActive = activeBanner != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(narrow ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF261049), // Dark Purple
            Color(0xFF1E1128), // Darkened core
            Color(0xFF332014), // Dark orange/brown tint
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.white70),
                    SizedBox(width: 6),
                    Text(
                      'LIVE ACTIVE BANNER',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              if (hasActive) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Active Live',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                )
              ]
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hasActive ? activeBanner!.title : 'No Banner Currently Active',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasActive
                ? isAdmin
                  ? 'This banner poster is currently popping up live on the website for visitors.'
                  : 'This promotional offer is currently live for you.'
                : isAdmin
                  ? 'Turn ON an existing banner from history or upload a new poster banner to enable live website popup.'
                  : 'There is no active promotional offer right now.',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          if (hasActive && isAdmin)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showImagePreview(context, activeBanner!.imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _BannerImage(
                      imageUrl: activeBanner!.imageUrl,
                      width: narrow ? 120 : 160,
                      height: narrow ? 80 : 100,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onDisable,
                          icon: const Icon(Icons.power_settings_new),
                          label: const Text('Disable Live Popup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF991B1B), // Dark Red
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onUpload,
                          icon: const Icon(Icons.add),
                          label: const Text('Upload Poster'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            )
          else if (isAdmin)
            ElevatedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.add, color: Colors.black87),
              label: const Text('Upload Poster', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// HISTORY LIST CARD
/// -----------------------------------------------------------------------
class _HistoryCard extends StatelessWidget {
  final PromoPopup popup;
  final bool narrow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _HistoryCard({
    required this.popup,
    required this.narrow,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = popup.isActive ? const Color(0xFF10B981) : AppColors.kBorder; // Green border if active
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: popup.isActive ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Image preview
          GestureDetector(
            onTap: () => _showImagePreview(context, popup.imageUrl),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _BannerImage(
                      imageUrl: popup.imageUrl,
                      width: double.infinity,
                      height: 160,
                    ),
                  ),
                  if (popup.isActive)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('LIVE ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        popup.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.kTextDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: popup.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        popup.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: popup.isActive ? const Color(0xFF16A34A) : AppColors.kTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '📅 ${formatDate(popup.createdAt)}  •  By ${popup.createdBy ?? 'Admin'}',
                  style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: popup.isActive
                          ? OutlinedButton.icon(
                              onPressed: onToggleActive,
                              icon: const Icon(Icons.power_settings_new),
                              label: const Text('Deactivate'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.kDanger,
                                side: const BorderSide(color: AppColors.kDanger),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: onToggleActive,
                              icon: const Icon(Icons.power_settings_new),
                              label: const Text('Publish Live'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB48629),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.kTextMuted),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.kDanger),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// UPLOAD / EDIT FORM DIALOG (image_5ab94a.jpg / image_5ab99e.png)
/// -----------------------------------------------------------------------
class _PromoPopupFormDialog extends StatefulWidget {
  final PromoPopup? existing;
  const _PromoPopupFormDialog({this.existing});

  @override
  State<_PromoPopupFormDialog> createState() => _PromoPopupFormDialogState();
}

class _PromoPopupFormDialogState extends State<_PromoPopupFormDialog> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  
  bool _publishLive = false;
  bool _isSaving = false;
  String? _selectedImageBase64; // In a real app, use XFile from image_picker

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _urlController.text = widget.existing!.targetUrl ?? '';
      _publishLive = widget.existing!.isActive;
      _selectedImageBase64 = widget.existing!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final extension = image.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    setState(() {
      _selectedImageBase64 = 'data:image/$extension;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ToastService.show(title: 'Validation Error', message: 'Campaign title is required', type: ToastType.error);
      return;
    }
    if (_selectedImageBase64 == null || _selectedImageBase64!.isEmpty) {
      ToastService.show(title: 'Validation Error', message: 'Poster image is required', type: ToastType.error);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'title': _titleController.text.trim(),
        'image_url': _selectedImageBase64,
        'target_url': _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
        'is_active': _publishLive,
      };

      if (widget.existing != null) {
        await PromoPopupApiService.updatePopup(widget.existing!.id, payload);
        ToastService.show(title: 'Success', message: 'Poster updated', type: ToastType.success);
      } else {
        await PromoPopupApiService.createPopup(payload);
        ToastService.show(title: 'Success', message: 'New poster uploaded', type: ToastType.success);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ToastService.show(title: 'Error saving', message: e.toString(), type: ToastType.error);
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEdit ? 'Edit Promotional Poster' : 'Upload New Promotional Poster',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.kTextDark),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          
          const Text('POSTER CAMPAIGN TITLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kTextMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'e.g. Festival Special Offer / Vehicle Scheme',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),

          const Text('POSTER BANNER IMAGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kTextMuted)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: AppColors.kBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (_selectedImageBase64 != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _BannerImage(imageUrl: _selectedImageBase64!, width: double.infinity, height: 140),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Replace Image'),
                  ),
                ] else ...[
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, color: Colors.white54, size: 32),
                          SizedBox(height: 8),
                          Text('No Image', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Select Image File'),
                  ),
                ],
                const SizedBox(height: 8),
                const Text('Supports PNG/JPG images (e.g. 1000px wide).', style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('TARGET LINK URL (OPTIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kTextMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              hintText: 'e.g. https://rrgroups.com/offers or /chits',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Optional: URL opened when a visitor clicks on the poster banner modal.', style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Publish Live Immediately', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B))),
                    SizedBox(height: 2),
                    Text('Sets this poster active as the live website popup modal.', style: TextStyle(fontSize: 11, color: Color(0xFF6B21A8))),
                  ],
                ),
                Switch(
                  value: _publishLive,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) => setState(() => _publishLive = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.kTextDark)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline),
                label: Text(isEdit ? 'Save Changes' : 'Upload & Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB48629),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// UTILS
/// -----------------------------------------------------------------------

/// Safely renders network vs base64 images
class _BannerImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const _BannerImage({
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http')) {
      return Image.network(imageUrl, width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    } else if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.split(',').last;
        return Image.memory(base64Decode(base64Str), width: width, height: height, fit: fit);
      } catch (e) {
        return _errorPlaceholder();
      }
    }
    return _errorPlaceholder();
  }

  Widget _errorPlaceholder() => Container(
    width: width, height: height, color: Colors.grey[200],
    child: const Icon(Icons.broken_image, color: Colors.grey),
  );
}

/// Modal for clicking an image to see it full screen (image_5abd9f.jpg)
void _showImagePreview(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _BannerImage(imageUrl: imageUrl, width: double.infinity, height: 400), 
          ),
          Positioned(
            top: -16,
            right: -16,
            child: FloatingActionButton.small(
              onPressed: () => Navigator.pop(context),
              backgroundColor: Colors.white,
              child: const Icon(Icons.close, color: Colors.black),
            ),
          ),
        ],
      ),
    ),
  );
}