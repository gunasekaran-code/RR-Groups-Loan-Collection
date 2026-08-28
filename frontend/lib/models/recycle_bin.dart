import 'dart:convert';

class RecycleBinItem {
  final String id;
  final String tableName;
  final String? recordId;
  final String? label;
  final String payload;
  final int childCount;
  final String? deletedBy;
  final String? deletedByName;
  final String? deletedByRole;
  final DateTime deletedAt;
  final DateTime? restoredAt;

  RecycleBinItem({
    required this.id,
    required this.tableName,
    this.recordId,
    this.label,
    required this.payload,
    required this.childCount,
    this.deletedBy,
    this.deletedByName,
    this.deletedByRole,
    required this.deletedAt,
    this.restoredAt,
  });

  bool get isRestored => restoredAt != null;

  String get displayTitle => label ?? recordId ?? 'Unknown Record';

  /// Formats raw table names (e.g., 'account_book_entry') into UI badges ('Account Book Entry')
  String get formattedTableName {
    return tableName
        .split('_')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' 
            : '')
        .join(' ');
  }

  factory RecycleBinItem.fromJson(Map<String, dynamic> json) {
    return RecycleBinItem(
      id: json['id'] as String,
      tableName: json['table_name'] as String,
      recordId: json['record_id'] as String?,
      label: json['label'] as String?,
      payload: json['payload'] as String,
      childCount: (json['child_count'] ?? 0) as int,
      deletedBy: json['deleted_by'] as String?,
      deletedByName: json['deleted_by_name'] as String?,
      deletedByRole: json['deleted_by_role'] as String?,
      deletedAt: DateTime.parse(json['deleted_at'] as String),
      restoredAt: json['restored_at'] != null
          ? DateTime.parse(json['restored_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_name': tableName,
      'record_id': recordId,
      'label': label,
      'payload': payload,
      'child_count': childCount,
      'deleted_by': deletedBy,
      'deleted_by_name': deletedByName,
      'deleted_by_role': deletedByRole,
      'deleted_at': deletedAt.toIso8601String(),
      'restored_at': restoredAt?.toIso8601String(),
    };
  }
}