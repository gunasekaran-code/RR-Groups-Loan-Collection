import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../routes/app_routes.dart';
import '../services/privilege_service.dart';
import '../services/session_service.dart';
import '../services/branding_service.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';
import 'dart:convert';

class _DrawerItem {
  final String label;
  final IconData icon;
  final String route;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class _DrawerSection {
  final String title;
  final List<_DrawerItem> items;
  const _DrawerSection({required this.title, required this.items});
}

// ---------------- OWNER / ADMIN ----------------
// Admin sees everything except items disabled via PrivilegeService toggles.
// Owner always sees all of these (privilege filtering is skipped for owner
// in _buildSection below).
const List<_DrawerSection> _ownerAdminSections = [
  _DrawerSection(title: 'OVERVIEW', items: [
    _DrawerItem(
        label: 'Dashboard',
        icon: Icons.grid_view_rounded,
        route: AppRoutes.dashboard),
  ]),
  _DrawerSection(title: 'MANAGE', items: [
    _DrawerItem(
        label: 'Customers',
        icon: Icons.people_outline,
        route: AppRoutes.customers),
    _DrawerItem(
        label: 'Loans',
        icon: Icons.account_balance_outlined,
        route: AppRoutes.loans),
    _DrawerItem(
        label: 'Repayment Schedule',
        icon: Icons.event_note_outlined,
        route: AppRoutes.repayment),
    _DrawerItem(
        label: 'Collections',
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.collections),
    _DrawerItem(
        label: 'Handover',
        icon: Icons.handshake_outlined,
        route: AppRoutes.handover),
    _DrawerItem(
        label: 'Funds',
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.funds),
    _DrawerItem(
        label: 'Account Book',
        icon: Icons.menu_book_outlined,
        route: AppRoutes.accountBook),
    _DrawerItem(
        label: 'Overdue', icon: Icons.error_outline, route: AppRoutes.overdue),
    _DrawerItem(
        label: 'Chit Groups',
        icon: Icons.groups_2_outlined,
        route: AppRoutes.chitGroups),
  ]),
  _DrawerSection(title: 'AGENT', items: [
    _DrawerItem(
        label: 'Agent',
        icon: Icons.support_agent_outlined,
        route: AppRoutes.agent),
    _DrawerItem(
        label: 'Agent Map',
        icon: Icons.map_outlined,
        route: AppRoutes.routeMap),
  ]),
  _DrawerSection(title: 'INSIGHTS', items: [
    _DrawerItem(
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
        route: AppRoutes.reports),
    _DrawerItem(
        label: 'Notifications',
        icon: Icons.notifications_none_rounded,
        route: AppRoutes.notifications),
  ]),
  _DrawerSection(title: 'SYSTEM', items: [
    _DrawerItem(
        label: 'User Management',
        icon: Icons.manage_accounts_outlined,
        route: AppRoutes.userManagement),
    _DrawerItem(
        label: 'Promotional Popup',
        icon: Icons
            .campaign_outlined, // standard Material icon for promotions/announcements
        route: AppRoutes.promotionalPopup),
    _DrawerItem(
      label: 'Recycle Bin',
      icon: Icons.delete_outline,
      route: AppRoutes.recycleBin,
    ),
    _DrawerItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        route: AppRoutes.settings),
  ]),
];

// ---------------- AGENT ----------------
const List<_DrawerSection> _agentSections = [
  _DrawerSection(title: 'OVERVIEW', items: [
    _DrawerItem(
        label: 'Dashboard',
        icon: Icons.grid_view_rounded,
        route: AppRoutes.dashboard),
  ]),
  _DrawerSection(title: 'MANAGE', items: [
    _DrawerItem(
        label: 'Customers',
        icon: Icons.people_outline,
        route: AppRoutes.customers),
    _DrawerItem(
        label: 'Loans',
        icon: Icons.account_balance_outlined,
        route: AppRoutes.loans),
    _DrawerItem(
        label: 'Repayment Schedule',
        icon: Icons.event_note_outlined,
        route: AppRoutes.repayment),
    _DrawerItem(
        label: 'Collections',
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.collections),
    _DrawerItem(
        label: 'Overdue', icon: Icons.error_outline, route: AppRoutes.overdue),
    _DrawerItem(
        label: 'Chit Groups',
        icon: Icons.groups_2_outlined,
        route: AppRoutes.chitGroups),
    _DrawerItem(
        label: 'Funds',
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.funds),
    _DrawerItem(
        label: 'Cash Handover',
        icon: Icons.handshake_outlined,
        route: AppRoutes.handover),
  ]),
  _DrawerSection(title: 'AGENT', items: [
    _DrawerItem(
        label: 'My Route',
        icon: Icons.map_outlined,
        route: AppRoutes.routeMap),
  ]),
  _DrawerSection(title: 'INSIGHTS', items: [
    _DrawerItem(
        label: 'Notifications',
        icon: Icons.notifications_none_rounded,
        route: AppRoutes.notifications),
  ]),
];

// ---------------- CUSTOMER ----------------
// NOTE: adjust route names below (myLoans, paymentHistory, myFunds, myChits)
// to whatever actually exists in AppRoutes — I used the closest matching
// names since I don't have your AppRoutes file in front of me. If customer
// pages reuse the same underlying screens as loans/repayment/funds/chitGroups
// just point these at AppRoutes.loans, AppRoutes.repayment, etc. instead.
// ---------------- CUSTOMER ----------------
const List<_DrawerSection> _customerSections = [
  _DrawerSection(title: 'OVERVIEW', items: [
    _DrawerItem(
        label: 'Dashboard',
        icon: Icons.grid_view_rounded,
        route: AppRoutes.dashboard),
  ]),
  _DrawerSection(title: 'MY ACCOUNT', items: [
    _DrawerItem(
        label: 'My Loans',
        icon: Icons.account_balance_outlined,
        route: AppRoutes.loans),
    _DrawerItem(
        label: 'Repayment Schedule',
        icon: Icons.event_note_outlined,
        route: AppRoutes.repayment),
    _DrawerItem(
        label: 'Payment History',
        icon: Icons.history_rounded,
        route: AppRoutes.paymentHistory),
    _DrawerItem(
        label: 'My Funds',
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.funds),
    _DrawerItem(
        label: 'My Chits',
        icon: Icons.groups_2_outlined,
        route: AppRoutes.chitGroups),
  ]),
  _DrawerSection(title: 'INSIGHTS', items: [
    _DrawerItem(
        label: 'Notifications',
        icon: Icons.notifications_none_rounded,
        route: AppRoutes.notifications),
  ]),
];

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  List<_DrawerSection> _sectionsForRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
      case UserRole.admin:
        return _ownerAdminSections;
      case UserRole.agent:
        return _agentSections;
      case UserRole.customer:
        return _customerSections;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUser user = SessionService.instance.currentUser!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sections = _sectionsForRole(user.role);

    return Drawer(
      backgroundColor: scheme.surface.withValues(alpha: 0.98),
      child: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder<AppBranding>(
              valueListenable: BrandingService.instance.branding,
              builder: (context, branding, _) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    _DrawerBrandLogo(
                        logoUrl: branding.logoUrl, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(branding.companyName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: scheme.onSurface)),
                          Text('Loan & Collection',
                              style: TextStyle(
                                  fontSize: 12, color: scheme.outline)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: scheme.outline.withValues(alpha: 0.2)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final section in sections)
                    _buildSection(context, section, user.role),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outline.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  UserAvatar(
                    user: user,
                    radius: 18,
                    backgroundColor: scheme.primary,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: scheme.onSurface),
                            overflow: TextOverflow.ellipsis),
                        Text(user.role.label,
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.logout,
                        color: scheme.onSurfaceVariant, size: 20),
                    onPressed: () {
                      SessionService.instance.logout();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login, (route) => false);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, _DrawerSection section, UserRole role) {
    // Only admin goes through the privilege toggle filter — owner and
    // everyone else's role-specific list is already scoped correctly above.
    final visibleItems = role == UserRole.admin
        ? section.items
            .where((i) => PrivilegeService.instance.isEnabledForAdmin(i.route))
            .toList()
        : section.items;

    if (visibleItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            section.title,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextMuted,
                letterSpacing: 0.5),
          ),
        ),
        for (final item in visibleItems) _buildItem(context, item),
      ],
    );
  }

  Widget _buildItem(BuildContext context, _DrawerItem item) {
    final scheme = Theme.of(context).colorScheme;
    final bool selected = currentRoute == item.route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.of(context).pop();
            if (!selected) {
              Navigator.of(context).pushReplacementNamed(item.route);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 20,
                    color: selected ? Colors.white : scheme.onSurface),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? Colors.white : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerBrandLogo extends StatelessWidget {
  final String? logoUrl;
  final Color color;

  const _DrawerBrandLogo({required this.logoUrl, required this.color});

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;
    Widget image =
        const Icon(Icons.account_balance, color: Colors.white, size: 22);

    if (url != null && url.startsWith('data:')) {
      try {
        image = Image.memory(
          base64Decode(url.substring(url.indexOf(',') + 1)),
          fit: BoxFit.cover, // Changed from contain to cover
        );
      } catch (_) {}
    } else if (url != null && url.isNotEmpty) {
      image = Image.network(
        url,
        fit: BoxFit.cover, // Changed from contain to cover
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.account_balance, color: Colors.white, size: 22),
      );
    }

    return Container(
      width: 40,
      height: 40,
      // Removed the 5px padding so it can fill edge-to-edge
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      // Wrapped in ClipRRect to keep the image corners perfectly rounded
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: image,
      ),
    );
  }
}
