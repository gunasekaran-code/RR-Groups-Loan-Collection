// screens/route_map/route_map_screen.dart
//
// Role-aware Field Map screen:
//   - Agent role         -> "Today's Route": this agent's own pending
//                            customers, pinned using the customer's saved
//                            latitude/longitude.
//   - Admin/owner role   -> "Agent Map": every agent in the field, pinned at
//                            the centroid of the customers assigned to them.
//
// Fully wired to the backend (no backend changes) via FieldMapApiService.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/agent_collection.dart' show AgentCollectionItem;
import '../../models/agent_map_point.dart';
import '../../models/user_role.dart';
import '../../routes/app_routes.dart';
import '../../services/field_map_api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';

String _money(double v) => AgentCollectionItem.formatAmount(v);

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  bool _isLoading = true;
  String? _loadError;

  AgentRouteResult? _agentRoute;
  AdminAgentMapResult? _adminMap;

  bool get _isAdmin {
    final role = SessionService.instance.currentUser?.role;
    return role == UserRole.admin || role == UserRole.owner;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      if (_isAdmin) {
        final result = await FieldMapApiService.fetchAdminAgentMap();
        if (!mounted) return;
        setState(() {
          _adminMap = result;
          _isLoading = false;
        });
      } else {
        final result = await FieldMapApiService.fetchAgentRoute();
        if (!mounted) return;
        setState(() {
          _agentRoute = result;
          _isLoading = false;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToPoints());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
      ToastService.show(
        title: 'Failed to load map',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  // ---------------------------------------------------------------------
  // Shared map helpers
  // ---------------------------------------------------------------------

  List<LatLng> get _markerPositions {
    if (_isAdmin) {
      return (_adminMap?.agents ?? const <AgentMapPoint>[])
          .where((a) => a.hasLocation)
          .map((a) => LatLng(a.latitude!, a.longitude!))
          .toList();
    }
    return (_agentRoute?.stops ?? const <AgentStop>[])
        .where((s) => s.hasLocation)
        .map((s) => LatLng(s.latitude!, s.longitude!))
        .toList();
  }

  LatLng get _mapCenter {
    final points = _markerPositions;
    if (points.isEmpty) {
      // Default center: Thoothukudi.
      return const LatLng(8.7642, 78.1348);
    }
    final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) /
        points.length;
    final avgLng = points.map((p) => p.longitude).reduce((a, b) => a + b) /
        points.length;
    return LatLng(avgLat, avgLng);
  }

  void _fitMapToPoints() {
    if (!_mapReady || !mounted) return;
    final points = _markerPositions;
    if (points.isEmpty) return;

    final first = points.first;
    final hasSpread = points.any((p) =>
        (p.latitude - first.latitude).abs() > 0.000001 ||
        (p.longitude - first.longitude).abs() > 0.000001);

    if (points.length == 1 || !hasSpread) {
      _mapController.move(first, 14);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  Future<void> _call(String? phone) async {
    final p = phone?.trim() ?? '';
    if (p.isEmpty) {
      ToastService.show(
        title: 'No phone number',
        message: 'No phone number on file for this contact.',
        type: ToastType.error,
      );
      return;
    }
    final uri = Uri.parse('tel:${p.replaceAll(RegExp(r'[^0-9+]'), '')}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ToastService.show(
          title: 'Could not start call', message: p, type: ToastType.error);
    }
  }

  Future<void> _navigate({double? lat, double? lng, String? address}) async {
    Uri? uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else if (address != null && address.trim().isNotEmpty) {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address.trim())}');
    }
    if (uri == null) {
      ToastService.show(
        title: 'No location on file',
        message: 'Add an address or coordinates to enable navigation.',
        type: ToastType.error,
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ToastService.show(
        title: 'Could not open maps',
        message: 'Google Maps could not be launched on this device.',
        type: ToastType.error,
      );
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.routeMap,
      title: _isAdmin ? 'Agent Map' : "Today's Route",
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? ListView(
                children: const [
                  SizedBox(
                    height: 320,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : _loadError != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                size: 40, color: AppColors.kDanger),
                            const SizedBox(height: 12),
                            Text(_loadError!,
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(color: AppColors.kDanger)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : (_isAdmin ? _buildAdminBody(context) : _buildAgentBody(context)),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // AGENT VIEW — "Today's Route"
  // ---------------------------------------------------------------------

  Widget _buildAgentBody(BuildContext context) {
    final route = _agentRoute;
    final stops = route?.stops ?? const <AgentStop>[];
    final summary = route?.summary ??
        const AgentRouteSummary(remaining: 0, completedToday: 0, pendingAmount: 0);
    final mappedCount = stops.where((s) => s.hasLocation).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Route",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark)),
                  const SizedBox(height: 2),
                  Text('${summary.totalStops} stops assigned today',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.kTextMuted)),
                ],
              ),
            ),
            _RefreshButton(onTap: _loadData),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.agentCollection),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kGoldDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Start Collecting'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              icon: Icons.people_alt_rounded,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: AppColors.kWarning,
              label: 'Total Stops',
              value: '${summary.totalStops}',
            ),
            _StatCard(
              icon: Icons.check_circle_outline_rounded,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: AppColors.kSuccess,
              label: 'Completed',
              value: '${summary.completedToday}',
            ),
            _StatCard(
              icon: Icons.access_time_rounded,
              iconBg: const Color(0xFFDCEAFE),
              iconColor: AppColors.kInfo,
              label: 'Remaining',
              value: '${summary.remaining}',
            ),
            _StatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconBg: const Color(0xFFFDEBEC),
              iconColor: AppColors.kDanger,
              label: 'Pending',
              value: _money(summary.pendingAmount),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMapCard(
          empty: stops.isEmpty,
          emptyTitle: 'No stops assigned',
          emptyMessage: "You have no customers with a pending balance right now.",
          markers: [
            for (var i = 0; i < stops.length; i++)
              if (stops[i].hasLocation)
                Marker(
                  point: LatLng(stops[i].latitude!, stops[i].longitude!),
                  width: 40,
                  height: 40,
                  child: _MapPin(
                    index: i + 1,
                    color: stops[i].overdue ? AppColors.kDanger : AppColors.kGoldDark,
                    onTap: () => _showStopInfo(stops[i]),
                  ),
                ),
          ],
        ),
        if (stops.isNotEmpty && mappedCount < stops.length) ...[
          const SizedBox(height: 10),
          _InlineNote(
            '${stops.length - mappedCount} of ${stops.length} stop(s) have no location on file. '
            'Add coordinates or an address in Customers for exact directions.',
          ),
        ],
        const SizedBox(height: 12),
        _buildLegend(const [
          _LegendEntry(AppColors.kDanger, 'Overdue'),
          _LegendEntry(AppColors.kGoldDark, 'Pending'),
        ]),
        const SizedBox(height: 20),
        if (stops.isEmpty)
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'All caught up',
              message: 'No pending collections assigned to you right now.',
            ),
          )
        else
          for (var i = 0; i < stops.length; i++)
            _StopCard(
              index: i + 1,
              stop: stops[i],
              onTap: () => _showStopInfo(stops[i]),
              onCall: () => _call(stops[i].mobile),
              onNavigate: () => _navigate(
                lat: stops[i].latitude,
                lng: stops[i].longitude,
                address: stops[i].address,
              ),
            ),
      ],
    );
  }

  void _showStopInfo(AgentStop stop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailSheet(
        title: stop.name,
        subtitle: 'Code: ${stop.code}',
        badgeLabel: stop.overdue ? 'Overdue' : 'Pending',
        badgeColor: stop.overdue ? AppColors.kDanger : AppColors.kGoldDark,
        rows: [
          _DetailRow(Icons.account_balance_wallet_outlined,
              'Pending: ${_money(stop.pendingAmount)}'),
          _DetailRow(Icons.receipt_long_outlined,
              '${stop.itemCount} installment(s) due'),
          _DetailRow(Icons.phone_outlined,
              stop.hasMobile ? stop.mobile! : 'No phone on file'),
          _DetailRow(Icons.location_on_outlined,
              stop.hasAddress ? stop.address! : 'No address on file'),
        ],
        onCall: () => _call(stop.mobile),
        onNavigate: () => _navigate(
            lat: stop.latitude, lng: stop.longitude, address: stop.address),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // ADMIN VIEW — "Agent Map"
  // ---------------------------------------------------------------------

  Widget _buildAdminBody(BuildContext context) {
    final map = _adminMap;
    final agents = map?.agents ?? const <AgentMapPoint>[];
    final summary = map?.summary ??
        const AdminAgentMapSummary(
            totalAgents: 0, activeAgents: 0, customersMapped: 0, pendingAmount: 0);
    final mappedCount = agents.where((a) => a.hasLocation).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Agent Map',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark)),
                  const SizedBox(height: 2),
                  Text('${summary.totalAgents} agents in the field',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.kTextMuted)),
                ],
              ),
            ),
            _RefreshButton(onTap: _loadData),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.agent),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kGoldDark,
                  side: const BorderSide(color: AppColors.kGoldDark),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.support_agent_outlined, size: 18),
                label: const Text('Manage Agents'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              icon: Icons.groups_2_outlined,
              iconBg: const Color(0xFFDCEAFE),
              iconColor: AppColors.kInfo,
              label: 'Total Agents',
              value: '${summary.totalAgents}',
            ),
            _StatCard(
              icon: Icons.check_circle_outline_rounded,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: AppColors.kSuccess,
              label: 'Active Agents',
              value: '${summary.activeAgents}',
            ),
            _StatCard(
              icon: Icons.people_alt_rounded,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: AppColors.kWarning,
              label: 'Customers Mapped',
              value: '${summary.customersMapped}',
            ),
            _StatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconBg: const Color(0xFFFDEBEC),
              iconColor: AppColors.kDanger,
              label: 'Pending',
              value: _money(summary.pendingAmount),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMapCard(
          empty: agents.isEmpty,
          emptyTitle: 'No agents found',
          emptyMessage: 'Add agents from User Management to see them here.',
          markers: [
            for (var i = 0; i < agents.length; i++)
              if (agents[i].hasLocation)
                Marker(
                  point: LatLng(agents[i].latitude!, agents[i].longitude!),
                  width: 40,
                  height: 40,
                  child: _MapPin(
                    index: i + 1,
                    color: agents[i].isActive
                        ? AppColors.kSuccess
                        : AppColors.kTextMuted,
                    onTap: () => _showAgentInfo(agents[i]),
                  ),
                ),
          ],
        ),
        if (agents.isNotEmpty && mappedCount < agents.length) ...[
          const SizedBox(height: 10),
          _InlineNote(
            '${agents.length - mappedCount} agent(s) have no mapped location yet — '
            'their assigned customers have no coordinates on file.',
          ),
        ],
        const SizedBox(height: 12),
        _buildLegend(const [
          _LegendEntry(AppColors.kSuccess, 'Active'),
          _LegendEntry(AppColors.kTextMuted, 'Inactive'),
        ]),
        const SizedBox(height: 20),
        if (agents.isEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: const EmptyState(
              icon: Icons.support_agent_outlined,
              title: 'No agents found',
              message: 'Add agents from User Management to see them here.',
            ),
          )
        else
          for (var i = 0; i < agents.length; i++)
            _AgentCard(
              index: i + 1,
              agent: agents[i],
              onTap: () => _showAgentInfo(agents[i]),
              onCall: () => _call(agents[i].mobile),
              onNavigate: () => _navigate(
                lat: agents[i].latitude,
                lng: agents[i].longitude,
              ),
            ),
      ],
    );
  }

  void _showAgentInfo(AgentMapPoint agent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailSheet(
        title: agent.fullName,
        subtitle: agent.email.isNotEmpty ? agent.email : 'Field Agent',
        badgeLabel: agent.isActive ? 'Active' : 'Inactive',
        badgeColor: agent.isActive ? AppColors.kSuccess : AppColors.kTextMuted,
        rows: [
          _DetailRow(Icons.people_alt_rounded,
              '${agent.customerCount} customer(s) assigned'),
          _DetailRow(Icons.check_circle_outline_rounded,
              '${agent.activeCount} active • ${agent.overdueCount} overdue'),
          _DetailRow(Icons.account_balance_wallet_outlined,
              'Pending: ${_money(agent.pendingAmount)}'),
          _DetailRow(Icons.phone_outlined,
              agent.mobile.isNotEmpty ? agent.mobile : 'No phone on file'),
        ],
        onCall: () => _call(agent.mobile),
        onNavigate: agent.hasLocation
            ? () => _navigate(lat: agent.latitude, lng: agent.longitude)
            : null,
      ),
    );
  }

  Widget _buildMapCard({
    required bool empty,
    required String emptyTitle,
    required String emptyMessage,
    required List<Marker> markers,
  }) {
    if (empty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: EmptyState(
          icon: Icons.map_outlined,
          title: emptyTitle,
          message: emptyMessage,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.kBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          height: 320,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: 10,
                  onMapReady: () {
                    _mapReady = true;
                    _fitMapToPoints();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nexora.fincollect',
                    maxNativeZoom: 19,
                  ),
                  MarkerLayer(markers: markers),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
              if (markers.isEmpty)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: _NoPinsBanner(),
                    ),
                  ),
                ),
              Positioned(
                top: 12,
                left: 12,
                child: Column(
                  children: [
                    _MapZoomButton(
                      icon: Icons.add,
                      onTap: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1),
                    ),
                    const SizedBox(height: 6),
                    _MapZoomButton(
                      icon: Icons.remove,
                      onTap: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(List<_LegendEntry> entries) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: 20),
            _LegendDot(color: entries[i].color),
            const SizedBox(width: 6),
            Text(entries[i].label,
                style: const TextStyle(
                    color: AppColors.kTextDark, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _LegendEntry {
  final Color color;
  final String label;
  const _LegendEntry(this.color, this.label);
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.index,
    required this.stop,
    required this.onTap,
    required this.onCall,
    required this.onNavigate,
  });

  final int index;
  final AgentStop stop;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final statusColor = stop.overdue ? AppColors.kDanger : AppColors.kWarning;
    final statusBg = stop.overdue
        ? AppColors.kDanger.withValues(alpha: 0.12)
        : AppColors.kWarning.withValues(alpha: 0.12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IndexBadge(index: index),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(stop.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.kTextDark)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stop.overdue ? 'Overdue' : 'Pending',
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${stop.code} • ${_money(stop.pendingAmount)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.kTextMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCall,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextDark,
                      side: const BorderSide(color: AppColors.kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onNavigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kGoldDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.navigation_outlined, size: 16),
                    label: const Text('Navigate'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (stop.hasAddress)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 15, color: AppColors.kTextMuted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(stop.address!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.kTextMuted)),
                  ),
                ],
              )
            else
              const _InlineNote(
                'No address on file — add it in Customers for exact directions.',
                dense: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.index,
    required this.agent,
    required this.onTap,
    required this.onCall,
    required this.onNavigate,
  });

  final int index;
  final AgentMapPoint agent;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final statusColor = agent.isActive ? AppColors.kSuccess : AppColors.kTextMuted;
    final statusBg = statusColor.withValues(alpha: 0.12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IndexBadge(index: index),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(agent.fullName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.kTextDark)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              agent.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${agent.customerCount} customers • ${agent.activeCount} active • ${agent.overdueCount} overdue',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.kTextMuted),
                      ),
                      const SizedBox(height: 2),
                      Text('Pending: ${_money(agent.pendingAmount)}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextDark)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCall,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextDark,
                      side: const BorderSide(color: AppColors.kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: agent.hasLocation ? onNavigate : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kGoldDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.kBorder,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.navigation_outlined, size: 16),
                    label: const Text('Navigate'),
                  ),
                ),
              ],
            ),
            if (!agent.hasLocation) ...[
              const SizedBox(height: 8),
              const _InlineNote(
                'No mapped location — this agent\'s customers have no coordinates on file.',
                dense: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$index',
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.kGoldDark)),
    );
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote(this.text, {this.dense = false});
  final String text;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 0 : 12, vertical: dense ? 0 : 10),
      decoration: dense
          ? null
          : BoxDecoration(
              color: AppColors.kWarning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.kWarning.withValues(alpha: 0.3)),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.kWarning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: dense ? 11.5 : 12.5,
                    color: AppColors.kWarning.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _NoPinsBanner extends StatelessWidget {
  const _NoPinsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: const Text(
        'No locations on file yet',
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.kTextMuted),
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String text;
  const _DetailRow(this.icon, this.text);
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
    required this.rows,
    required this.onCall,
    this.onNavigate,
  });

  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color badgeColor;
  final List<_DetailRow> rows;
  final VoidCallback onCall;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextDark)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.kTextMuted)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(row.icon, size: 16, color: AppColors.kTextMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(row.text,
                        style: const TextStyle(
                            color: AppColors.kTextMuted, fontSize: 14)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kTextDark,
                    side: const BorderSide(color: AppColors.kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kGoldDark,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.kBorder,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: const Text('Navigate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.kTextDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.kTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin(
      {required this.index, required this.color, required this.onTap});
  final int index;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          CustomPaint(
            size: const Size(10, 6),
            painter: _PinTailPainter(color: color),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: const Icon(Icons.refresh_rounded, color: AppColors.kTextDark),
      ),
    );
  }
}

class _MapZoomButton extends StatelessWidget {
  const _MapZoomButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.kTextDark),
        ),
      ),
    );
  }
}
