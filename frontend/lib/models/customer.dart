class Customer {
  final String id;

  // New fields
  final String customerId;
  final String fullName;
  final String? mobile;
  final String? address;
  final String? aadhaar;
  final String? pan;
  final String? occupation;
  final String? photoUrl;
  final String? assignedAgent;
  final String? assignedAgentName;
  final double? latitude;
  final double? longitude;
  final String loanStatus;
  final DateTime? createdAt;

  Customer({
    required this.id,
    this.customerId = '',
    required this.fullName,
    this.mobile,
    this.address,
    this.aadhaar,
    this.pan,
    this.occupation,
    this.photoUrl,
    this.assignedAgent,
    this.assignedAgentName,
    this.latitude,
    this.longitude,
    this.loanStatus = 'none',
    this.createdAt,
  });

  /// Backward compatibility
  String get name => fullName;
  String? get phone => mobile;

  factory Customer.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      return double.tryParse(value.toString());
    }

    return Customer(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      fullName: (json['full_name'] ??
              json['name'] ??
              json['customer_name'] ??
              'Unnamed')
          .toString(),
      mobile: (json['mobile'] ?? json['phone'])?.toString(),
      address: json['address']?.toString(),
      aadhaar: json['aadhaar']?.toString(),
      pan: json['pan']?.toString(),
      occupation: json['occupation']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      assignedAgent: json['assigned_agent']?.toString(),
      assignedAgentName: json['assigned_agent_name']?.toString(),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      loanStatus: json['loan_status']?.toString() ?? 'none',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toRequestBody({
    String? email,
    String? password,
  }) {
    final body = <String, dynamic>{
      'full_name': fullName,
      'mobile': mobile,
      'address': address,
      'aadhaar': aadhaar,
      'pan': pan,
      'occupation': occupation,
      'photo_url': photoUrl,
      'assigned_agent': assignedAgent,
      'latitude': latitude,
      'longitude': longitude,
    };

    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    return body;
  }

  @override
  String toString() => fullName;
}