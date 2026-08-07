import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cash_handover.dart';
import '../models/user_role.dart';
import 'method_override_http.dart';
import 'session_service.dart';

class HandoverAgentOption {
  final String id;
  final String name;
  final bool active;

  const HandoverAgentOption({
    required this.id,
    required this.name,
    required this.active,
  });
}

/// Talks to the existing PHP REST endpoint at /rest.php?table=handovers.
/// The backend exposes generic CRUD for the handovers table, so this service
/// reads the rows and derives the summary/settlement view on the Flutter side.
class CashHandoverApiService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _restEndpoint = '$_baseUrl/rest.php';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (SessionService.instance.token != null &&
            SessionService.instance.token!.isNotEmpty)
          'Authorization': 'Bearer ${SessionService.instance.token}',
      };

  static Uri _uri(String resource, [Map<String, String>? query]) {
    return Uri.parse(_restEndpoint).replace(
      queryParameters: {
        'table': resource,
        ...?query,
      },
    );
  }

  static Never _throwFromResponse(http.Response res) {
    String message = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      }
    } catch (_) {
      // leave default message
    }
    throw Exception(message);
  }

  static String? _currentUserId() {
    final user = SessionService.instance.currentUser;
    return user?.userId.trim().isNotEmpty == true ? user!.userId.trim() : null;
  }

  static bool get _isAdmin =>
      SessionService.instance.currentUser?.role == UserRole.admin ||
      SessionService.instance.currentUser?.role == UserRole.owner;

  static Map<String, String>? _handoverScopeQuery() {
    if (_isAdmin) return null;
    final userId = _currentUserId();
    if (userId == null) return {'agent_id': 'eq.__no_user__'};
    return {'agent_id': 'eq.$userId'};
  }

  static List<Map<String, dynamic>> _decodeRows(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _throwFromResponse(res);
    }

    final body = jsonDecode(res.body);
    if (body is List) {
      return body.cast<Map<String, dynamic>>();
    }
    if (body is Map && body['data'] is List) {
      return (body['data'] as List).cast<Map<String, dynamic>>();
    }
    if (body is Map<String, dynamic>) {
      return [body];
    }
    return [];
  }

  static Future<List<HandoverAgentOption>> fetchActiveAgents() async {
    final res = await http.get(
      _uri('profiles', {'role': 'eq.agent', 'status': 'eq.active'}),
      headers: _headers,
    );
    if (res.statusCode != 200) _throwFromResponse(res);

    final rows = _decodeRows(res);
    final currentUserId = _currentUserId();
    final agents = rows
        .map(
          (row) => HandoverAgentOption(
            id: row['id']?.toString() ?? '',
            name: row['full_name']?.toString() ??
                row['name']?.toString() ??
                'Unknown Agent',
            active: (row['status']?.toString() ?? '').toLowerCase() == 'active',
          ),
        )
        .where((a) => a.id.isNotEmpty)
        .where(
            (a) => _isAdmin || currentUserId == null || a.id == currentUserId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return agents;
  }

  static Future<HandoverSummary> fetchSummary() async {
    final rows = await _listRows();
    final records = rows.map(HandoverRecord.fromJson).toList();

    final totalCollected =
        records.fold<double>(0, (sum, row) => sum + row.totalAmount);
    final totalHandedOver = records
        .where((row) => row.verified)
        .fold<double>(0, (sum, row) => sum + row.totalAmount);
    final totalPending = records
        .where((row) => !row.verified)
        .fold<double>(0, (sum, row) => sum + row.totalAmount);
    final agentsWithPending = records
        .where((row) => !row.verified)
        .map((row) => row.agentId)
        .toSet()
        .length;

    return HandoverSummary(
      totalCollected: totalCollected,
      totalHandedOver: totalHandedOver,
      totalPending: totalPending,
      agentsWithPending: agentsWithPending,
    );
  }

  static Future<List<AgentSettlement>> fetchSettlements() async {
    final rows = await _listRows();
    final records = rows.map(HandoverRecord.fromJson).toList();
    final grouped = <String, List<HandoverRecord>>{};

    for (final record in records) {
      grouped.putIfAbsent(record.agentId, () => []).add(record);
    }

    return grouped.entries.map((entry) {
      final items = entry.value;
      final collected =
          items.fold<double>(0, (sum, row) => sum + row.totalAmount);
      final handedOver = items
          .where((row) => row.verified)
          .fold<double>(0, (sum, row) => sum + row.totalAmount);
      return AgentSettlement(
        agentId: entry.key,
        agentName: items.first.agentName,
        collected: collected,
        handedOver: handedOver,
      );
    }).toList()
      ..sort((a, b) => a.agentName.compareTo(b.agentName));
  }

  static Future<List<HandoverRecord>> fetchHistory({int? limit}) async {
    final rows = await _listRows();
    final records = rows.map(HandoverRecord.fromJson).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (limit != null && limit > 0) {
      return records.take(limit).toList();
    }
    return records;
  }

  static Future<HandoverRecord> createHandover(HandoverRecord record) async {
    final res = await http.post(
      _uri('handovers'),
      headers: _headers,
      body: jsonEncode(record.toCreateJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throwFromResponse(res);
    }

    final rows = _decodeRows(res);
    final row = rows.isNotEmpty ? rows.first : <String, dynamic>{};
    return HandoverRecord.fromJson(row);
  }

  static Future<HandoverRecord> verifyHandover(String id) async {
    final res = await postWithMethodOverride(
      _uri('handovers', {'id': id}),
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode({
        'status': 'verified',
        if (SessionService.instance.currentUser?.userId.isNotEmpty == true)
          'received_by': SessionService.instance.currentUser!.userId,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throwFromResponse(res);
    }

    final rows = _decodeRows(res);
    final row = rows.isNotEmpty ? rows.first : <String, dynamic>{};
    return HandoverRecord.fromJson(row);
  }

  static Future<HandoverRecord> updateHandover(HandoverRecord record) async {
    final res = await postWithMethodOverride(
      _uri('handovers', {'id': record.id}),
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode(record.toUpdateJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throwFromResponse(res);
    }

    final rows = _decodeRows(res);
    final row = rows.isNotEmpty ? rows.first : <String, dynamic>{};
    return HandoverRecord.fromJson(row);
  }

  static Future<void> deleteHandover(String id) async {
    final res = await postWithMethodOverride(
      _uri('handovers', {'id': id}),
      method: 'DELETE',
      headers: _headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throwFromResponse(res);
    }
  }

  static Future<List<Map<String, dynamic>>> _listRows() async {
    final res = await http.get(
      _uri('handovers', _handoverScopeQuery()),
      headers: _headers,
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    return _decodeRows(res);
  }
}
