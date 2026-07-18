enum AgentRole { admin, agent }

enum AgentStatus { active, inactive }

class Agent {
  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final AgentRole role;
  final AgentStatus status;
  final String address;
  final String aadhaar;
  final String pan;
  final String occupation;
  final String? profilePhotoUrl;
  final DateTime createdAt;

  const Agent({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.role,
    required this.status,
    this.address = '',
    this.aadhaar = '',
    this.pan = '',
    this.occupation = '',
    this.profilePhotoUrl,
    required this.createdAt,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String get roleLabel => role == AgentRole.admin ? 'Admin' : 'Agent';
  String get statusLabel =>
      status == AgentStatus.active ? 'Active' : 'Inactive';
  bool get isActive => status == AgentStatus.active;

  Agent copyWith({
    String? fullName,
    String? mobile,
    String? email,
    AgentRole? role,
    AgentStatus? status,
    String? address,
    String? aadhaar,
    String? pan,
    String? occupation,
    String? profilePhotoUrl,
  }) {
    return Agent(
      id: id,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      address: address ?? this.address,
      aadhaar: aadhaar ?? this.aadhaar,
      pan: pan ?? this.pan,
      occupation: occupation ?? this.occupation,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt,
    );
  }
}