class UserAccount {
  final String id;
  final String fullName;
  final String email;
  final String? mobile;
  final String role; // 'admin' | 'agent' | 'customer'
  final String? customerId;
  final String? address;
  final String? aadhaar;
  final String? pan;
  final String? occupation;
  final String status; // 'active' | 'inactive'
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.mobile,
    this.customerId,
    this.address,
    this.aadhaar,
    this.pan,
    this.occupation,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      mobile: json['mobile']?.toString(),
      role: (json['role'] ?? 'agent').toString(),
      customerId: json['customer_id']?.toString(),
      address: json['address']?.toString(),
      aadhaar: json['aadhaar']?.toString(),
      pan: json['pan']?.toString(),
      occupation: json['occupation']?.toString(),
      status: (json['status'] ?? 'active').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  /// Payload for create (POST). Password is required by the backend.
  Map<String, dynamic> toCreateJson({required String password}) {
    return {
      'full_name': fullName,
      'email': email,
      'password': password,
      'mobile': mobile,
      'role': role,
      'customer_id': customerId,
      'address': address,
      'aadhaar': aadhaar,
      'pan': pan,
      'occupation': occupation,
      'status': status,
      'avatar_url': avatarUrl,
    }..removeWhere((k, v) => v == null);
  }

  /// Payload for update (PATCH). Only include fields you want to change;
  /// pass [password] only when the user wants to reset it.
  Map<String, dynamic> toUpdateJson({String? password}) {
    final map = {
      'full_name': fullName,
      'email': email,
      'mobile': mobile,
      'role': role,
      'customer_id': customerId,
      'address': address,
      'aadhaar': aadhaar,
      'pan': pan,
      'occupation': occupation,
      'status': status,
      'avatar_url': avatarUrl,
    };
    if (password != null && password.isNotEmpty) {
      map['password'] = password;
    }
    map.removeWhere((k, v) => v == null);
    return map;
  }

  UserAccount copyWith({
    String? fullName,
    String? email,
    String? mobile,
    String? role,
    String? customerId,
    String? address,
    String? aadhaar,
    String? pan,
    String? occupation,
    String? status,
    String? avatarUrl,
  }) {
    return UserAccount(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      role: role ?? this.role,
      customerId: customerId ?? this.customerId,
      address: address ?? this.address,
      aadhaar: aadhaar ?? this.aadhaar,
      pan: pan ?? this.pan,
      occupation: occupation ?? this.occupation,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}