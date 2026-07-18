import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({super.key, required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.kGoldLight.withOpacity(0.4), shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: AppColors.kGoldDark),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.kTextDark)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
          ],
        ),
      ),
    );
  }
}
