import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../routes/app_routes.dart';
import '../services/session_service.dart';
import '../screens/agent_collection/agent_collection_screen.dart';
import '../screens/collections/collections_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/dashboard/admin_dashboard.dart';
import '../screens/dashboard/agent_dashboard.dart';
import '../screens/dashboard/customer_dashboard.dart';
import '../screens/funds/funds_screen.dart';
import '../screens/loans/loans_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/notifications/notification_state.dart';
import '../screens/repayment/repayment_schedule_screen.dart';
import '../screens/settings/profile_page.dart';
import 'app_navbar.dart';
import 'app_drawer.dart';
import 'user_avatar.dart';

class _AppShellContentOnly extends InheritedWidget {
  const _AppShellContentOnly({required super.child});

  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppShellContentOnly>() !=
        null;
  }

  @override
  bool updateShouldNotify(_AppShellContentOnly oldWidget) => false;
}

class AppShell extends StatefulWidget {
  final String currentRoute;
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.currentRoute,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  static const Map<String, String> _tabTitles = {
    AppRoutes.dashboard: 'Dashboard',
    AppRoutes.customers: 'Customers',
    AppRoutes.loans: 'Loans',
    AppRoutes.repayment: 'Repayment Schedule',
    AppRoutes.collections: 'Collections',
    AppRoutes.funds: 'My Funds',
    AppRoutes.notifications: 'Notifications',
    AppRoutes.profile: 'My Profile',
  };

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late String _activeRoute;

  @override
  void initState() {
    super.initState();
    _activeRoute = widget.currentRoute;
    NotificationState.instance.refreshUnreadCount();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _activeRoute = widget.currentRoute;
    }
  }

  String get _headerTitle {
    if (_activeRoute == widget.currentRoute) return widget.title;
    return AppShell._tabTitles[_activeRoute] ?? widget.title;
  }

  @override
  Widget build(BuildContext context) {
    if (_AppShellContentOnly.of(context)) {
      return widget.body;
    }

    final AppUser? user = SessionService.instance.currentUser;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        titleSpacing: 4,
        title: Text(
          _headerTitle,
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: NotificationState.instance,
            builder: (context, _) {
              final unreadCount = NotificationState.instance.unreadCount;
              return IconButton(
                tooltip: unreadCount == 0
                    ? 'Notifications'
                    : '$unreadCount unread notifications',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded),
                    if (unreadCount > 0)
                      Positioned(
                        right: -7,
                        top: -7,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  if (_activeRoute != AppRoutes.notifications) {
                    Navigator.of(context).pushNamed(AppRoutes.notifications);
                  }
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: Tooltip(
              message: 'My Profile',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _activeRoute = AppRoutes.profile),
                child: UserAvatar(
                  user: user,
                  radius: 16,
                  backgroundColor: scheme.primary,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: currentRoute),
      body: SafeArea(
        child: _buildActiveBody(),
      ),
      bottomNavigationBar: AppBottomNav(
        currentRoute: _activeRoute,
        onTabSelected: (route) => setState(() => _activeRoute = route),
      ),
      floatingActionButton: _activeRoute == widget.currentRoute
          ? widget.floatingActionButton
          : null,
    );
  }

  String get currentRoute => _activeRoute;

  Widget _buildActiveBody() {
    if (_activeRoute == widget.currentRoute) return widget.body;

    final user = SessionService.instance.currentUser;
    return _AppShellContentOnly(
      child: switch (_activeRoute) {
        AppRoutes.dashboard => _dashboardForRole(user?.role),
        AppRoutes.customers => const CustomersScreen(),
        AppRoutes.loans => const LoansScreen(),
        AppRoutes.repayment => const RepaymentScheduleScreen(),
        AppRoutes.funds => const FundsScreen(),
        AppRoutes.notifications => const NotificationsScreen(),
        AppRoutes.collections => user?.role == UserRole.agent
            ? const AgentCollectionScreen()
            : const CollectionsScreen(),
        AppRoutes.profile => const ProfilePage(showScaffold: false),
        _ => widget.body,
      },
    );
  }

  Widget _dashboardForRole(UserRole? role) {
    return switch (role) {
      UserRole.customer => const CustomerDashboardScreen(),
      UserRole.agent => const AgentDashboardScreen(),
      UserRole.owner || UserRole.admin || null => const DashboardScreen(),
    };
  }
}
