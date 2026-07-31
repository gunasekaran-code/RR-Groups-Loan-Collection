class AgentSettlement {
  final String agentId;
  final String agentName;
  final double collected;
  final double handedOver;

  AgentSettlement({
    required this.agentId,
    required this.agentName,
    required this.collected,
    required this.handedOver,
  });

  double get pending => collected - handedOver;

  factory AgentSettlement.fromJson(Map<String, dynamic> json) {
    return AgentSettlement(
      agentId: json['agent_id'].toString(),
      agentName: json['agent_name']?.toString() ?? 'Unknown Agent',
      collected: _toDouble(json['collected']),
      handedOver: _toDouble(json['handed_over']),
    );
  }
}

/// A single handover row from the `handovers` table.
class HandoverRecord {
  final String id;
  final String agentId;
  final String agentName;
  final DateTime date;
  final double cashAmount;
  final double upiAmount;
  final bool verified;
  final String? notes;
  final String? receivedBy;

  HandoverRecord({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.date,
    required this.cashAmount,
    required this.upiAmount,
    required this.verified,
    this.notes,
    this.receivedBy,
  });

  double get totalAmount => cashAmount + upiAmount;

  factory HandoverRecord.fromJson(Map<String, dynamic> json) {
    return HandoverRecord(
      id: json['id'].toString(),
      agentId: json['agent_id'].toString(),
      agentName: json['agent_name']?.toString() ?? 'Unknown Agent',
      date: DateTime.tryParse(json['handover_date']?.toString() ?? '') ??
          DateTime.now(),
      cashAmount: _toDouble(json['cash_amount']),
      upiAmount: _toDouble(json['upi_amount']),
      verified: (json['status']?.toString() ?? '') == 'verified',
      notes: json['notes']?.toString(),
      receivedBy: json['received_by']?.toString(),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'agent_id': agentId,
      'agent_name': agentName,
      'handover_date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'cash_amount': cashAmount,
      'upi_amount': upiAmount,
      'total_amount': totalAmount,
      'notes': notes,
      'status': verified ? 'verified' : 'pending',
      if (receivedBy != null && receivedBy!.isNotEmpty) 'received_by': receivedBy,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'agent_id': agentId,
      'agent_name': agentName,
      'handover_date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'cash_amount': cashAmount,
      'upi_amount': upiAmount,
      'total_amount': totalAmount,
      'notes': notes,
      'status': verified ? 'verified' : 'pending',
      'received_by': receivedBy,
    };
  }

  HandoverRecord copyWith({
    String? id,
    String? agentId,
    String? agentName,
    DateTime? date,
    double? cashAmount,
    double? upiAmount,
    bool? verified,
    String? notes,
    String? receivedBy,
  }) {
    return HandoverRecord(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      date: date ?? this.date,
      cashAmount: cashAmount ?? this.cashAmount,
      upiAmount: upiAmount ?? this.upiAmount,
      verified: verified ?? this.verified,
      notes: notes ?? this.notes,
      receivedBy: receivedBy ?? this.receivedBy,
    );
  }
}

/// Overall summary card data.
class HandoverSummary {
  final double totalCollected;
  final double totalHandedOver;
  final double totalPending;
  final int agentsWithPending;
  final double todayCollected;

  HandoverSummary({
    required this.totalCollected,
    required this.totalHandedOver,
    required this.totalPending,
    required this.agentsWithPending,
    this.todayCollected = 0,
  });

  factory HandoverSummary.fromJson(Map<String, dynamic> json) {
    return HandoverSummary(
      totalCollected: _toDouble(json['total_collected']),
      totalHandedOver: _toDouble(json['total_handed_over']),
      totalPending: _toDouble(json['total_pending']),
      agentsWithPending: (json['agents_with_pending'] as num?)?.toInt() ?? 0,
      todayCollected: _toDouble(json['today_collected']),
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
