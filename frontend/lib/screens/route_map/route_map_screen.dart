import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';

class RouteMapScreen extends StatelessWidget {
  const RouteMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.routeMap,
      title: 'Route Map',
      body: const EmptyState(
        icon: Icons.map_outlined,
        title: 'Route map coming soon',
        message: "Today's collection stops will be plotted here once the maps integration and backend are connected.",
      ),
    );
  }
}
