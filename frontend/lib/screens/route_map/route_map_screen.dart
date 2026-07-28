// screens/route_map/route_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:ui' as ui;
import 'package:latlong2/latlong.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';
import '../../models/collection_point.dart';
import '../../services/field_map_api_service.dart';
import '../chit_groups/chit_groups_screen.dart' show formatIndianCurrency;

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final MapController _mapController = MapController();

  bool _isLoading = true;
  String? _loadError;

  List<CollectionPoint> _points = [];
  List<AgentOption> _agents = [];
  FieldMapSummary? _summary;
  String _selectedAgentId = 'all';

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
      final agents = await FieldMapApiService.fetchAgents();
      final points =
          await FieldMapApiService.fetchPoints(agentId: _selectedAgentId);
      final summary =
          await FieldMapApiService.fetchSummary(agentId: _selectedAgentId);
      if (!mounted) return;
      setState(() {
        _agents = agents;
        _points = points;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
      ToastService.show(
        title: 'Failed to load field map',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _onAgentChanged(String? value) async {
    if (value == null) return;
    setState(() => _selectedAgentId = value);
    _loadData();
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

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.routeMap,
      title: 'Field Map',
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
                            onPressed: _loadData, child: const Text('Retry')),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'Where each agent has collected — live',
                        style: TextStyle(
                            color: AppColors.kTextMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.kSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.kBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedAgentId,
                                  isExpanded: true,
                                  icon: const Icon(Icons.unfold_more_rounded,
                                      color: AppColors.kTextMuted),
                                  style: const TextStyle(
                                      color: AppColors.kTextDark, fontSize: 15),
                                  items: [
                                    const DropdownMenuItem(
                                        value: 'all',
                                        child: Text('All agents')),
                                    ..._agents.map(
                                      (a) => DropdownMenuItem(
                                          value: a.id, child: Text(a.name)),
                                    ),
                                  ],
                                  onChanged: _onAgentChanged,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _RefreshButton(onTap: _loadData),
                        ],
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
                            label: 'On Map',
                            value: '${_summary?.onMap ?? _points.length}',
                          ),
                          _StatCard(
                            icon: Icons.check_circle_outline_rounded,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: AppColors.kSuccess,
                            label: 'Collected',
                            value:
                                '${_summary?.collectedCount ?? _points.where((p) => p.collected).length}',
                          ),
                          _StatCard(
                            icon: Icons.person_pin_circle_outlined,
                            iconBg: const Color(0xFFEDE9FE),
                            iconColor: const Color(0xFF7C3AED),
                            label: 'Active Agents',
                            value: '${_summary?.activeAgents ?? 0}',
                          ),
                          _StatCard(
                            icon: Icons.account_balance_wallet_outlined,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: AppColors.kGold,
                            label: 'Total Collected',
                            value: formatIndianCurrency(
                                _summary?.totalCollected ??
                                    _points.fold(0.0, (s, p) => s + p.amount)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_points.isEmpty)
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.kSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.kBorder),
                          ),
                          child: const EmptyState(
                            icon: Icons.map_outlined,
                            title: 'No collection points yet',
                            message:
                                "Once agents start collecting, their stops will be plotted here.",
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
                              height: 200,
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _mapCenter,
                                      initialZoom: 15,
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
                                        markers: _points
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
                                                  collected:
                                                      entry.value.collected,
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
                        child: const Row(
                          children: [
                            _LegendDot(color: AppColors.kSuccess),
                            SizedBox(width: 6),
                            Text('Collected',
                                style: TextStyle(
                                    color: AppColors.kTextDark, fontSize: 13)),
                            SizedBox(width: 20),
                            _LegendDot(color: AppColors.kDanger),
                            SizedBox(width: 6),
                            Text('Not collected',
                                style: TextStyle(
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
            Text(point.customerName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextDark)),
            const SizedBox(height: 6),
            Text(
              '${point.agentName} · ${formatIndianCurrency(point.amount)} · ${_formatTime(point.collectedAt)}',
              style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dd = d.day.toString().padLeft(2, '0');
    int hour12 = d.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$dd ${months[d.month - 1]} ${d.year} ${hour12.toString().padLeft(2, '0')}:$minute $ampm';
  }
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
          // Top Section: Number (Start) and Icon (End)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Value / Number -> Starting, Top
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
              // Icon -> End, Top
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

          const Spacer(), // Pushes the label text to the bottom

          // Bottom Section: Label Text -> Starting, Down
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
      {required this.index, required this.collected, required this.onTap});
  final int index;
  final bool collected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = collected ? AppColors.kSuccess : AppColors.kDanger;
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
                    color: Colors.black.withOpacity(0.25),
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

    // Explicitly use the UI path
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
