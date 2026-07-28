// models/collection_point.dart

class CollectionPoint {
  final String id;
  final String customerName;
  final String agentName;
  final String agentId;
  final double amount;
  final DateTime collectedAt;
  final double latitude;
  final double longitude;
  final bool collected;

  CollectionPoint({
    required this.id,
    required this.customerName,
    required this.agentName,
    required this.agentId,
    required this.amount,
    required this.collectedAt,
    required this.latitude,
    required this.longitude,
    required this.collected,
  });

  factory CollectionPoint.fromJson(Map<String, dynamic> json) {
    return CollectionPoint(
      id: json['id'].toString(),
      customerName: (json['customer_name'] ?? json['full_name'] ?? json['name'])
              ?.toString() ??
          'Unknown',
      agentName: (json['agent_name'] ?? json['assigned_agent_name'])
              ?.toString() ??
          'Unknown Agent',
      agentId: (json['agent_id'] ?? json['assigned_agent'])?.toString() ?? '',
      amount: _toDouble(json['amount']),
      collectedAt: DateTime.tryParse(
              (json['collected_at'] ?? json['created_at'])?.toString() ?? '') ??
          DateTime.now(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      collected: (json['collected'] == true ||
          json['collected'] == 1 ||
          json['collected'] == '1' ||
          (json['status']?.toString() ?? '') == 'active' ||
          (json['loan_status']?.toString() ?? '') == 'active'),
    );
  }
}

class FieldMapSummary {
  final int onMap;
  final int collectedCount;
  final int activeAgents;
  final double totalCollected;

  FieldMapSummary({
    required this.onMap,
    required this.collectedCount,
    required this.activeAgents,
    required this.totalCollected,
  });

  factory FieldMapSummary.fromJson(Map<String, dynamic> json) {
    return FieldMapSummary(
      onMap: (json['on_map'] as num?)?.toInt() ?? 0,
      collectedCount: (json['collected_count'] as num?)?.toInt() ?? 0,
      activeAgents: (json['active_agents'] as num?)?.toInt() ?? 0,
      totalCollected: _toDouble(json['total_collected']),
    );
  }
}

class AgentOption {
  final String id;
  final String name;
  AgentOption({required this.id, required this.name});

  factory AgentOption.fromJson(Map<String, dynamic> json) {
    return AgentOption(
      id: json['id'].toString(),
      name: (json['full_name'] ?? json['name'])?.toString() ?? 'Unknown',
      // name: json['name']?.toString() ?? 'Unknown',
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
