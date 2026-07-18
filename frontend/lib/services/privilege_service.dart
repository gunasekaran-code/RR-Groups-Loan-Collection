/// Owner-controlled visibility for select Admin sidebar pages
/// (Owner requirement: "set privilege for the admin user pages show and disable").
/// TODO(backend): persist these toggles server-side once the API is connected —
/// right now they only live in memory for this app session.
class PrivilegeService {
  PrivilegeService._internal();
  static final PrivilegeService instance = PrivilegeService._internal();

  final Map<String, bool> _adminAccess = {
    '/chit-groups': true,
    '/reports': true,
    '/settings': true,
  };

  bool isEnabledForAdmin(String route) => _adminAccess[route] ?? true;

  void setEnabledForAdmin(String route, bool enabled) {
    if (_adminAccess.containsKey(route)) {
      _adminAccess[route] = enabled;
    }
  }

  Map<String, bool> get adminAccessMap => Map.unmodifiable(_adminAccess);
}
