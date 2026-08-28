// screens/route_map/route_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:ui' as ui;
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';
import '../../models/collection_point.dart';
import '../../services/field_map_api_service.dart';

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final MapController _mapController = MapController();

  bool _isLoading = true;
  String? _loadError;
  String _searchQuery = '';
  String _selectedCustomerId = 'all';
  bool _mapReady = false;

  List<CollectionPoint> _points = [];
  FieldMapSummary? _summary;

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
      final points = await FieldMapApiService.fetchPoints();
      final summary = await FieldMapApiService.fetchSummary();

      if (!mounted) return;
      setState(() {
        _points = points;
        _summary = summary;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToPoints());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
      final l10n = AppLocalizations.of(context)!;
      ToastService.show(
        title: l10n.routeMapLoadFailedTitle,
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  LatLng get _mapCenter {
    if (_points.isEmpty) {
      // Default center: Thoothukudi
      return const LatLng(8.7642, 78.1348);
    }
    final avgLat =
        _points.map((p) => p.latitude).reduce((a, b) => a + b) / _points.length;
    final avgLng = _points.map((p) => p.longitude).reduce((a, b) => a + b) /
        _points.length;
    return LatLng(avgLat, avgLng);
  }

  List<CollectionPoint> get _filteredPoints {
    return _points.where((point) {
      final matchesCustomer = _selectedCustomerId == 'all' ||
          point.customerName == _selectedCustomerId;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          point.customerName.toLowerCase().contains(query) ||
          point.agentName.toLowerCase().contains(query);
      return matchesCustomer && matchesSearch;
    }).toList();
  }

  List<String> get _customerNames {
    final names = _points.map((p) => p.customerName).where((n) => n.isNotEmpty);
    return names.toSet().toList()..sort();
  }

  void _fitMapToPoints() {
    if (!_mapReady) return;

    final points = _filteredPoints;
    if (!mounted || points.isEmpty) return;

    // `CameraFit.bounds` can blow up when all visible points collapse to a
    // single coordinate or an almost-zero bounding box, so fall back to a
    // stable center/zoom in that case.
    final first = points.first;
    final hasMeaningfulSpread = points.any((p) =>
        (p.latitude - first.latitude).abs() > 0.000001 ||
        (p.longitude - first.longitude).abs() > 0.000001);

    if (points.length == 1 || !hasMeaningfulSpread) {
      _mapController.move(
        LatLng(
          points.map((p) => p.latitude).reduce((a, b) => a + b) /
              points.length,
          points.map((p) => p.longitude).reduce((a, b) => a + b) /
              points.length,
        ),
        15,
      );
      return;
    }

    final bounds = LatLngBounds.fromPoints(
      points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
    );
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  void _applyFilterState({String? customerId, String? searchQuery}) {
    setState(() {
      if (customerId != null) _selectedCustomerId = customerId;
      if (searchQuery != null) _searchQuery = searchQuery;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToPoints());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final points = _filteredPoints;
    return AppShell(
      currentRoute: AppRoutes.routeMap,
      title: l10n.routeMapTitle,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!,
                            style: const TextStyle(color: AppColors.kDanger)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _loadData,
                            child: Text(l10n.routeMapRetryButton)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.routeMapAllLocationsSubtitle,
                            style: const TextStyle(
                                color: AppColors.kTextMuted, fontSize: 14),
                          ),
                          _RefreshButton(onTap: _loadData),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          hintText: l10n.routeMapSearchHint,
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) =>
                            _applyFilterState(searchQuery: value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCustomerId,
                        decoration: InputDecoration(
                          labelText: l10n.routeMapCustomerLabel,
                          prefixIcon:
                              const Icon(Icons.person_search_outlined),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(l10n.routeMapAllCustomers),
                          ),
                          ..._customerNames.map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            _applyFilterState(customerId: value ?? 'all'),
                      ),
                      const SizedBox(height: 20),
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
                            label: l10n.routeMapTotalMapped,
                            value: '${_summary?.onMap ?? points.length}',
                          ),
                          _StatCard(
                            icon: Icons.check_circle_outline_rounded,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: AppColors.kSuccess,
                            label: l10n.routeMapActiveCustomers,
                            value:
                                '${_summary?.collectedCount ?? points.where((p) => p.collected).length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (points.isEmpty)
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.kSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.kBorder),
                          ),
                          child: EmptyState(
                            icon: Icons.map_outlined,
                            title: l10n.routeMapNoLocationsTitle,
                            message: l10n.routeMapNoLocationsMessage,
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.kBorder),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: SizedBox(
                              height:
                                  350, // Increased map height for better visibility
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
                                            'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                        subdomains: const ['a', 'b', 'c', 'd'],
                                        userAgentPackageName:
                                            'com.nexora.fincollect',
                                      ),
                                      MarkerLayer(
                                        markers: points
                                            .asMap()
                                            .entries
                                            .map(
                                              (entry) => Marker(
                                                point: LatLng(
                                                    entry.value.latitude,
                                                    entry.value.longitude),
                                                width: 40,
                                                height: 40,
                                                child: _MapPin(
                                                  index: entry.key + 1,
                                                  active: entry.value
                                                      .collected, // Reusing 'collected' for status
                                                  onTap: () => _showPointInfo(
                                                      entry.value),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                      const RichAttributionWidget(
                                        attributions: [
                                          TextSourceAttribution(
                                            '© OpenStreetMap contributors',
                                          ),
                                        ],
                                      ),
                                    ],
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
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.kSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.kBorder),
                        ),
                        child: Row(
                          children: [
                            const _LegendDot(color: AppColors.kSuccess),
                            const SizedBox(width: 6),
                            Text(l10n.routeMapActive,
                                style: const TextStyle(
                                    color: AppColors.kTextDark, fontSize: 13)),
                            const SizedBox(width: 20),
                            const _LegendDot(color: AppColors.kDanger),
                            const SizedBox(width: 6),
                            Text(l10n.routeMapInactive,
                                style: const TextStyle(
                                    color: AppColors.kTextDark, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  void _showPointInfo(CollectionPoint point) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                  child: Text(point.customerName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: point.collected
                        ? AppColors.kSuccess.withValues(alpha: 0.1)
                        : AppColors.kDanger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    point.collected ? l10n.routeMapActive : l10n.routeMapInactive,
                    style: TextStyle(
                      color: point.collected
                          ? AppColors.kSuccess
                          : AppColors.kDanger,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.kTextMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    point
                        .agentName, // We temporarily stored the address here in the API service
                    style: const TextStyle(
                        color: AppColors.kTextMuted, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.kTextMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.routeMapJoinedLabel(_formatDate(point.collectedAt)),
                    style: const TextStyle(
                        color: AppColors.kTextMuted, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);
}

/// -----------------------------------------------------------------------
/// STAT CARD
/// -----------------------------------------------------------------------
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

/// -----------------------------------------------------------------------
/// MAP PIN
/// -----------------------------------------------------------------------
class _MapPin extends StatelessWidget {
  const _MapPin(
      {required this.index, required this.active, required this.onTap});
  final int index;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.kSuccess : AppColors.kDanger;
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