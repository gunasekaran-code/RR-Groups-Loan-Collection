import 'package:flutter/material.dart';
import '../theme/app_theme.dart';  

class AppEditDialog {
  AppEditDialog._();

  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? initialValue,
    String hintText = 'Enter value...',
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Save',
    Color confirmButtonColor = AppColors.kGold, // Defaults to your primary color
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Edit Dialog',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _EditDialogContent(
              title: title,
              initialValue: initialValue,
              hintText: hintText,
              cancelLabel: cancelLabel,
              confirmLabel: confirmLabel,
              confirmButtonColor: confirmButtonColor,
            ),
          ),
        );
      },
    );
  }
}

/// Private stateful widget to cleanly manage the text controller lifecycle
class _EditDialogContent extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String hintText;
  final String cancelLabel;
  final String confirmLabel;
  final Color confirmButtonColor;

  const _EditDialogContent({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmButtonColor,
  });

  @override
  State<_EditDialogContent> createState() => _EditDialogContentState();
}

class _EditDialogContentState extends State<_EditDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic bottom padding to push the dialog above the keyboard
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final double safeAreaPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: 32,
          left: 24,
          right: 24,
          bottom: keyboardPadding > 0 
              ? keyboardPadding + 16  // Spacing when keyboard is open
              : safeAreaPadding + 24, // Safe area spacing for iOS home indicator
        ),
        decoration: const BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black87, // Changed from black.withOpacity for clarity in 2026 standard styling
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextDark,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Input Field
            TextField(
              controller: _controller,
              autofocus: true, // Automatically opens keyboard smoothly
              style: const TextStyle(fontSize: 16, color: AppColors.kTextDark),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: AppColors.kTextMuted),
                filled: true,
                fillColor: Colors.grey.shade100, // Customize backplate color
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.confirmButtonColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                    onPressed: () => Navigator.pop(context, null),
                    child: Text(
                      widget.cancelLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.confirmButtonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, _controller.text.trim()),
                    child: Text(
                      widget.confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}