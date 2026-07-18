import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ListItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailingValue;
  final Widget? badge;
  final IconData leadingIcon;
  final VoidCallback? onTap;

  const ListItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailingValue,
    required this.leadingIcon,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.kGoldLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leadingIcon, color: AppColors.kGoldDark, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.kTextDark),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
                  ],
                ),
              ),
              if (trailingValue.isNotEmpty || badge != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (trailingValue.isNotEmpty)
                      Text(trailingValue,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.kTextDark)),
                    if (badge != null) ...[const SizedBox(height: 6), badge!],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
