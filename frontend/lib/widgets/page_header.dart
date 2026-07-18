import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Subtitle/actions block. The page TITLE now lives in AppShell's AppBar
/// (see app_shell.dart), so it's no longer rendered here. This still
/// stacks and goes full-width on mobile, sits inline on wider screens.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // Nothing to show if there's no subtitle and no actions.
    if ((subtitle == null || subtitle!.isEmpty) &&
        (actions == null || actions!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        final subtitleBlock = subtitle == null
            ? const SizedBox.shrink()
            : Text(
                subtitle!,
                style: const TextStyle(fontSize: 14, color: AppColors.kTextMuted),
              );

        if (isNarrow) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                subtitleBlock,
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  for (final a in actions!) ...[
                    SizedBox(width: double.infinity, child: a),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: subtitleBlock),
              if (actions != null)
                for (final a in actions!) ...[
                  a,
                  const SizedBox(width: 12),
                ],
            ],
          ),
        );
      },
    );
  }
}