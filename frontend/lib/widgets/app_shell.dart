import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../routes/app_routes.dart';
import '../services/session_service.dart';
import '../screens/agent_collection/agent_collection_screen.dart';
import '../screens/collections/collections_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/loans/loans_screen.dart';
import '../screens/repayment/repayment_schedule_screen.dart';
import '../screens/settings/profile_page.dart';
import 'app_bottom_nav.dart';
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

  static const List<String> _tabRoutes = [
    AppRoutes.dashboard,
    AppRoutes.customers,
    AppRoutes.loans,
    AppRoutes.repayment,
    AppRoutes.collections,
  ];

  // Titles for every tab reachable from the bottom nav, so the AppBar can
  // show the right title the instant a tab is tapped — without having to
  // wait for that screen to build and report its own title back up.
  static const Map<String, String> _tabTitles = {
    AppRoutes.dashboard: 'Dashboard',
    AppRoutes.customers: 'Customers',
    AppRoutes.loans: 'Loans',
    AppRoutes.repayment: 'Repayment Schedule',
    AppRoutes.collections: 'Collections',
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
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _activeRoute = widget.currentRoute;
    }
  }

  /// Title to show in the AppBar for whatever tab/page is currently active.
  /// Falls back to widget.title (the title the page itself was given) if
  /// the active route isn't in the lookup — e.g. for routes reached outside
  /// the bottom nav.
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
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              if (_activeRoute != AppRoutes.notifications) {
                Navigator.of(context).pushNamed(AppRoutes.notifications);
              }
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
        currentRoute:
            AppShell._tabRoutes.contains(_activeRoute) ? _activeRoute : '',
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
        AppRoutes.dashboard => const DashboardScreen(),
        AppRoutes.customers => const CustomersScreen(),
        AppRoutes.loans => const LoansScreen(),
        AppRoutes.repayment => const RepaymentScheduleScreen(),
        AppRoutes.collections =>
          user?.role == UserRole.agent
              ? const AgentCollectionScreen()
              : const CollectionsScreen(),
        AppRoutes.profile => const ProfilePage(showScaffold: false),
        _ => widget.body,
      },
    );
  }
}
