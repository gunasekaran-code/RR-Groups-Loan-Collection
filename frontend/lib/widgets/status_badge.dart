import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeTone { success, warning, danger, info, neutral }
enum StatusTone { success, warning, danger, info, neutral }



class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;

  const StatusBadge({super.key, required this.label, this.tone = BadgeTone.neutral});

  Color _bg() {
    switch (tone) {
      case BadgeTone.success:
        return AppColors.kSuccess.withOpacity(0.12);
      case BadgeTone.warning:
        return AppColors.kWarning.withOpacity(0.12);
      case BadgeTone.danger:
        return AppColors.kDanger.withOpacity(0.12);
      case BadgeTone.info:
        return AppColors.kInfo.withOpacity(0.12);
      case BadgeTone.neutral:
        return AppColors.kBorder;
    }
  }

  Color _fg() {
    switch (tone) {
      case BadgeTone.success:
        return AppColors.kSuccess;
      case BadgeTone.warning:
        return AppColors.kWarning;
      case BadgeTone.danger:
        return AppColors.kDanger;
      case BadgeTone.info:
        return AppColors.kInfo;
      case BadgeTone.neutral:
        return AppColors.kTextMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: _bg(), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _fg())),
    );
  }
}
