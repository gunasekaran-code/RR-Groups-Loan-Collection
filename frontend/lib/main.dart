import 'package:flutter/material.dart';
import 'models/user_role.dart';
import 'routes/app_routes.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';
import 'theme/glass_toast.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/loans/loans_screen.dart';
import 'screens/repayment/repayment_schedule_screen.dart';
import 'screens/collections/collections_screen.dart';
import 'screens/overdue/overdue_screen.dart';
import 'screens/route_map/route_map_screen.dart';
import 'screens/chit_groups/chit_groups_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/user_management/user_management_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/profile_page.dart';
import 'screens/agent_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionService.instance.restoreFromStorage();
  runApp(const FinCollectApp());
}

class FinCollectApp extends StatelessWidget {
  const FinCollectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: ToastService.navigatorKey,
      title: 'FinCollect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // initialRoute: AppRoutes.login,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case AppRoutes.splash:
        page = const SplashScreen();
        break;
      case AppRoutes.login:
        page = const LoginScreen();
        break;
      case AppRoutes.dashboard:
        page = _guarded(const DashboardScreen(), UserRole.values);
        break;
      case AppRoutes.customers:
        page = _guarded(const CustomersScreen(), UserRole.values);
        break;
      case AppRoutes.loans:
        page = _guarded(const LoansScreen(), UserRole.values);
        break;
      case AppRoutes.repayment:
        page = _guarded(const RepaymentScheduleScreen(), UserRole.values);
        break;
      case AppRoutes.collections:
        page = _guarded(const CollectionsScreen(), UserRole.values);
        break;
      case AppRoutes.overdue:
        page = _guarded(const OverdueScreen(), UserRole.values);
        break;
      case AppRoutes.agent:
        page =
            _guarded(const AgentManagementScreen(), const [UserRole.owner, UserRole.admin]);
        break;
      case AppRoutes.routeMap:
        page = _guarded(const RouteMapScreen(), const [UserRole.agent]);
        break;
      case AppRoutes.chitGroups:
        page = _guarded(
            const ChitGroupsScreen(), const [UserRole.owner, UserRole.admin]);
        break;
      case AppRoutes.reports:
        page = _guarded(
            const ReportsScreen(), const [UserRole.owner, UserRole.admin]);
        break;
      case AppRoutes.notifications:
        page = _guarded(const NotificationsScreen(), UserRole.values);
        break;
      case AppRoutes.userManagement:
        page = _guarded(const UserManagementScreen(), const [UserRole.owner]);
        break;
      case AppRoutes.settings:
        page = _guarded(
            const SettingsScreen(), const [UserRole.owner, UserRole.admin]);
        break;
      case AppRoutes.profile:
        page = _guarded(const ProfilePage(), UserRole.values);
        break;
      default:
        page = const LoginScreen();
    }

    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  /// Redirects to Login if nobody is signed in, or to Dashboard if the
  /// signed-in role isn't allowed on this page.
  Widget _guarded(Widget page, List<UserRole> allowedRoles) {
    final user = SessionService.instance.currentUser;
    if (user == null) return const LoginScreen();
    if (!allowedRoles.contains(user.role)) return const DashboardScreen();
    return page;
  }
}
