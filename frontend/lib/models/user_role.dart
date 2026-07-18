enum UserRole { owner, admin, agent }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.agent:
        return 'Collection Agent';
    }
  }

  String get subtitle {
    switch (this) {
      case UserRole.owner:
        return 'Full system access';
      case UserRole.admin:
        return 'Operations management';
      case UserRole.agent:
        return 'Field collections';
    }
  }
}
