class PromoPopup {
  final String id;
  final String title;
  final String imageUrl; // Supports base64 LONGTEXT or standard URL
  final String? targetUrl;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;

  PromoPopup({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.targetUrl,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
  });

  factory PromoPopup.fromJson(Map<String, dynamic> json) {
    return PromoPopup(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      targetUrl: json['target_url'] as String?,
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'target_url': targetUrl,
      'is_active': isActive ? 1 : 0,
    };
  }

  PromoPopup copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? targetUrl,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return PromoPopup(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}