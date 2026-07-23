import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../routes/app_routes.dart';
import '../services/privilege_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class _DrawerItem {
  final String label;
  final IconData icon;
  final String route;
  final List<UserRole> allowedRoles;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.allowedRoles,
  });
}

class _DrawerSection {
  final String title;
  final List<_DrawerItem> items;
  const _DrawerSection({required this.title, required this.items});
}

// Sidebar structure. Owner sees everything. Admin sees everything except
// User Management, plus whatever Owner has left enabled via Privilege
// toggles. Agent sees only field-relevant pages (per the FinCollect design).
const List<_DrawerSection> _sections = [
  _DrawerSection(title: 'OVERVIEW', items: [
    _DrawerItem(
        label: 'Dashboard',
        icon: Icons.grid_view_rounded,
        route: AppRoutes.dashboard,
        allowedRoles: UserRole.values),
  ]),
  _DrawerSection(title: 'MANAGE', items: [
    _DrawerItem(
        label: 'Customers',
        icon: Icons.people_outline,
        route: AppRoutes.customers,
        allowedRoles: UserRole.values),
    _DrawerItem(
        label: 'Loans',
        icon: Icons.account_balance_outlined,
        route: AppRoutes.loans,
        allowedRoles: UserRole.values),
    _DrawerItem(
        label: 'Repayment Schedule',
        icon: Icons.event_note_outlined,
        route: AppRoutes.repayment,
        allowedRoles: UserRole.values),
    _DrawerItem(
        label: 'Collections',
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.collections,
        allowedRoles: UserRole.values),
    _DrawerItem(
        label: 'Overdue',
        icon: Icons.error_outline,
        route: AppRoutes.overdue,
        allowedRoles: UserRole.values),
    _DrawerItem(
        label: 'Chit Groups',
        icon: Icons.groups_2_outlined,
        route: AppRoutes.chitGroups,
        allowedRoles: [UserRole.owner, UserRole.admin]),
  ]),
  _DrawerSection(title: 'AGENT', items: [
    _DrawerItem(
        label: 'Agent',
        icon: Icons.support_agent_outlined,
        route: AppRoutes.agent,
        allowedRoles: [UserRole.owner, UserRole.admin]),
    _DrawerItem(
        label: 'Route Map',
        icon: Icons.map_outlined,
        route: AppRoutes.routeMap,
        allowedRoles: [UserRole.agent, UserRole.owner, UserRole.admin]),
  ]),
  _DrawerSection(title: 'INSIGHTS', items: [
    _DrawerItem(
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
        route: AppRoutes.reports,
        allowedRoles: [UserRole.owner, UserRole.admin]),
    _DrawerItem(
        label: 'Notifications',
        icon: Icons.notifications_none_rounded,
        route: AppRoutes.notifications,
        allowedRoles: UserRole.values),
  ]),
  _DrawerSection(title: 'SYSTEM', items: [
    _DrawerItem(
        label: 'User Management',
        icon: Icons.manage_accounts_outlined,
        route: AppRoutes.userManagement,
        allowedRoles: [UserRole.owner, UserRole.admin]),
    _DrawerItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        route: AppRoutes.settings,
        allowedRoles: [UserRole.owner, UserRole.admin]),
  ]),
];

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final AppUser user = SessionService.instance.currentUser!;

    return Drawer(
      backgroundColor: AppColors.kSurface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.kGold,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.account_balance,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FinCollect',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.kTextDark)),
                        Text('Loan & Collection',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.kTextMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final section in _sections)
                    _buildSection(context, section, user.role),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.kGold,
                    child: Text(user.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.kTextDark),
                            overflow: TextOverflow.ellipsis),
                        Text(user.role.label,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.kTextMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout,
                        color: AppColors.kTextMuted, size: 20),
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
    final visibleItems = section.items.where((i) {
      if (!i.allowedRoles.contains(role)) return false;
      if (role == UserRole.admin &&
          !PrivilegeService.instance.isEnabledForAdmin(i.route)) {
        return false;
      }
      return true;
    }).toList();

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
    final bool selected = currentRoute == item.route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AppColors.kGold : Colors.transparent,
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
                    color: selected ? Colors.white : AppColors.kTextDark),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? Colors.white : AppColors.kTextDark,
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
