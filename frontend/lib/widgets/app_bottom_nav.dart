import 'dart:ui'; // Required for ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../routes/app_routes.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

const List<_NavItem> _navItems = [
  _NavItem(
      label: 'Dashboard',
      icon: CupertinoIcons.square_grid_2x2,
      route: AppRoutes.dashboard),
  _NavItem(
      label: 'Customers',
      icon: CupertinoIcons.person_2,
      route: AppRoutes.customers),
  _NavItem(
      label: 'Loans',
      icon: CupertinoIcons.building_2_fill,
      route: AppRoutes.loans),
  _NavItem(
      label: 'Repayment',
      icon: CupertinoIcons.calendar,
      route: AppRoutes.repayment),
  _NavItem(
      label: 'Collections',
      icon: CupertinoIcons.creditcard,
      route: AppRoutes.collections),
];

class AppBottomNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onTabSelected;

  const AppBottomNav({
    super.key,
    required this.currentRoute,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final int index = _navItems.indexWhere((i) => i.route == currentRoute);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            // 💡 This creates the physical "glass" refraction blur
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.18),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < _navItems.length; i++)
                    Expanded(
                      child: _buildTab(context, _navItems[i], i == index),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, _NavItem item, bool selected) {
    final scheme = Theme.of(context).colorScheme;
    final Color color = selected ? scheme.primary : scheme.outline;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // borderRadius: BorderRadius.circular(24),
        onTap: () {
          if (!selected) onTabSelected(item.route);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                scale: selected ? 1.08 : 1,
                child: Container(
  width: 34,
  height: 30,
  alignment: Alignment.center,
  decoration: BoxDecoration(
    color: Colors.transparent,
    shape: BoxShape.circle,
    border: selected
        ? Border.all(
            color: scheme.onSurface.withValues(alpha: 0.25),
            width: 1,
          )
        : null,
    boxShadow: selected
        ? [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.14),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
        : null,
  ),
  child: Icon(
    item.icon, 
    size: selected ? 21 : 19, 
    color: color,
  ),
),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
