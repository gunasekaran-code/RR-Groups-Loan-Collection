double? _asFiniteCoord(double? v) {
  if (v == null || !v.isFinite) return null;
  return v;
}

bool _isValidLatLng(double? lat, double? lng) {
  if (lat == null || lng == null) return false;
  if (!lat.isFinite || !lng.isFinite) return false;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
  // (0, 0) almost always means "never set" rather than a real position.
  if (lat == 0 && lng == 0) return false;
  return true;
}

String initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

/// One stop on an agent's own collection route (Agent-role map).
class AgentStop {
  final String customerId;
  final String code;
  final String name;
  final String? mobile;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double pendingAmount;
  final bool overdue;
  final int itemCount;

  AgentStop({
    required this.customerId,
    required this.code,
    required this.name,
    required this.pendingAmount,
    required this.overdue,
    required this.itemCount,
    this.mobile,
    this.address,
    double? latitude,
    double? longitude,
  })  : latitude = _asFiniteCoord(latitude),
        longitude = _asFiniteCoord(longitude);

  bool get hasLocation => _isValidLatLng(latitude, longitude);
  bool get hasAddress => address != null && address!.trim().isNotEmpty;
  bool get hasMobile => mobile != null && mobile!.trim().isNotEmpty;
  String get initials => initialsFor(name);
}

/// Header stats for the agent's own route.
class AgentRouteSummary {
  final int remaining;
  final int completedToday;
  final double pendingAmount;

  const AgentRouteSummary({
    required this.remaining,
    required this.completedToday,
    required this.pendingAmount,
  });

  int get totalStops => remaining + completedToday;
}

class AgentMapPoint {
  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final String status; // 'active' | 'inactive'
  final int customerCount;
  final int activeCount;
  final int overdueCount;
  final double pendingAmount;
  final double? latitude;
  final double? longitude;

  AgentMapPoint({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.status,
    required this.customerCount,
    required this.activeCount,
    required this.overdueCount,
    required this.pendingAmount,
    double? latitude,
    double? longitude,
  })  : latitude = _asFiniteCoord(latitude),
        longitude = _asFiniteCoord(longitude);

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasLocation => _isValidLatLng(latitude, longitude);
  String get initials => initialsFor(fullName);
}

/// Header stats for the Admin/Owner agent map.
class AdminAgentMapSummary {
  final int totalAgents;
  final int activeAgents;
  final int customersMapped;
  final double pendingAmount;

  const AdminAgentMapSummary({
    required this.totalAgents,
    required this.activeAgents,
    required this.customersMapped,
    required this.pendingAmount,
  });
}
