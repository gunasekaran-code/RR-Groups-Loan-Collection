import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../theme/locale_controller.dart';
import 'api_client.dart';

class SessionService {
  SessionService._internal();
  static final SessionService instance = SessionService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _profileKey = 'auth_profile';

  AppUser? currentUser;
  String? token;
  bool _promoPopupAttempted = false;

  Future<void> restoreFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    ApiClient.instance.authToken = token;

    final rawProfile = prefs.getString(_profileKey);
    if (rawProfile == null || rawProfile.isEmpty) {
      currentUser = null;
      return;
    }

    try {
      final profile = jsonDecode(rawProfile) as Map<String, dynamic>;
      currentUser = AppUser(
        userId: (profile['id'] ?? '').toString(),
        customerId: profile['customer_id']?.toString(),
        name: (profile['full_name'] as String?)?.trim().isNotEmpty == true
            ? profile['full_name'] as String
            : (profile['email'] ?? 'User').toString(),
        role: _roleFromProfile(profile['role']),
        avatarUrl: profile['avatar_url']?.toString(),
      );
      // A session survived an app restart — restore this user's own saved
      // language (or English if they've never picked one) rather than
      // whatever LocaleController's in-memory default happens to be.
      await LocaleController.loadForUser(currentUser!.userId);
    } catch (_) {
      currentUser = null;
      token = null;
      ApiClient.instance.authToken = null;
    }
  }

  AppUser login(AppUser user, {String? token}) {
    currentUser = user;
    this.token = token;
    _promoPopupAttempted = false;
    ApiClient.instance.authToken = token;
    // Fire-and-forget: apply this user's saved language (English if they've
    // never set one). Not awaited so login isn't blocked on local I/O; the
    // UI updates the moment the read resolves, which is effectively instant.
    LocaleController.loadForUser(user.userId);
    return user;
  }

  void logout() {
    currentUser = null;
    token = null;
    _promoPopupAttempted = false;
    ApiClient.instance.authToken = null;
    // Don't leave the outgoing user's language active for whoever signs in
    // next on this device — reset it, then their own login() call above
    // loads their saved choice.
    LocaleController.resetToDefault();
  }

  UserRole? get role => currentUser?.role;

  bool get isLoggedIn => currentUser != null;

  bool claimPromoPopupAttempt() {
    if (_promoPopupAttempted) return false;
    _promoPopupAttempted = true;
    return true;
  }
}

UserRole _roleFromProfile(dynamic rawRole) {
  switch ((rawRole ?? '').toString().trim().toLowerCase()) {
    case 'owner':
      return UserRole.owner;
    case 'admin':
      return UserRole.admin;
    case 'agent':
      return UserRole.agent;
    case 'customer':
      return UserRole.customer;
    default:
      return UserRole.agent;
  }
}
