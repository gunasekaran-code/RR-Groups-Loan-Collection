import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import 'api_client.dart';

class SessionService {
  SessionService._internal();
  static final SessionService instance = SessionService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _profileKey = 'auth_profile';

  AppUser? currentUser;
  String? token;

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
    } catch (_) {
      currentUser = null;
      token = null;
    }
  }

  AppUser login(AppUser user, {String? token}) {
    currentUser = user;
    this.token = token;
    ApiClient.instance.authToken = token;
    return user;
  }

  void logout() {
    currentUser = null;
    token = null;
    ApiClient.instance.authToken = null;
  }

  UserRole? get role => currentUser?.role;

  bool get isLoggedIn => currentUser != null;
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
