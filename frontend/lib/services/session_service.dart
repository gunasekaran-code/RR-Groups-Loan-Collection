import '../models/app_user.dart';
import '../models/user_role.dart';

/// Static/demo session handling.
/// TODO(backend): replace static login with real Sanctum token auth
/// (SharedPreferences 'auth_token' + Bearer header) once the API is wired up.
class SessionService {
  SessionService._internal();
  static final SessionService instance = SessionService._internal();

  AppUser? currentUser;

  static const List<AppUser> staticUsers = [
    AppUser(userId: 'OWN-001', name: 'Rajesh Kumar', role: UserRole.owner),
    AppUser(userId: 'ADM-001', name: 'Priya Sharma', role: UserRole.admin),
    AppUser(userId: 'AGT-001', name: 'Arjun Mehta', role: UserRole.agent),
  ];

  AppUser login(AppUser user) {
    currentUser = user;
    return user;
  }

  void logout() {
    currentUser = null;
  }

  bool get isLoggedIn => currentUser != null;
}
