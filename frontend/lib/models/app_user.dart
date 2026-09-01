import 'user_role.dart';

class AppUser {
  final String userId;
  final String? customerId;
  final String name;
  final UserRole role;
  final String? avatarUrl;

  const AppUser({
    required this.userId,
    this.customerId,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  String get agentId => userId;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

