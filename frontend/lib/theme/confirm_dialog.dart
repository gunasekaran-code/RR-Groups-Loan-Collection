import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Adjust path based on your directory layout

class AppConfirmDialog {
  AppConfirmDialog._();

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Delete',
    Color confirmButtonColor = AppColors.kDanger,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Confirmation',
      barrierColor: Colors.black.withOpacity(0.4), // Darkens the background smoothly
      transitionDuration: const Duration(milliseconds: 350), // Smooth iOS duration
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
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                // Removed side margins so it stretches full screen left-to-right.
                // Added system bottom padding to protect the iOS home indicator area.
                padding: EdgeInsets.only(
                  top: 35,
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
                decoration: BoxDecoration(
                  color: AppColors.kSurface,
                  // Replaced circular border radius with vertical top curves only
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
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
                          title,
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
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.kTextMuted,
                        height: 1.4,
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
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              cancelLabel,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: confirmButtonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              confirmLabel,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
