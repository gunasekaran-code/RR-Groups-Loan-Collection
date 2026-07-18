import 'user_role.dart';

class AppUser {
  final String userId;
  final String name;
  final UserRole role;

  const AppUser({
    required this.userId,
    required this.name,
    required this.role,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
