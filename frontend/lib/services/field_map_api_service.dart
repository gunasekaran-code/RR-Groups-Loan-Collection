// services/field_map_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/collection_point.dart';
import 'session_service.dart';

class FieldMapApiService {
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
    return Uri.parse(_restEndpoint)
        .replace(queryParameters: {'table': resource, ...?query});
  }

  static Never _throwFromResponse(http.Response res) {
    String message = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] != null) message = body['error'].toString();
    } catch (_) {}
    throw Exception(message);
  }

  static bool _hasCoords(Map<String, dynamic> row) {
    return row['latitude'] != null && row['longitude'] != null;
  }

  static String _agentNameFor(Map<String, dynamic> row, Map<String, String> agentNames) {
    final agentId = (row['assigned_agent'] ?? row['agent_id'])?.toString() ?? '';
    if (agentId.isEmpty) return (row['assigned_agent_name'] ?? row['agent_name'])?.toString() ?? 'Unknown Agent';
    return agentNames[agentId] ?? (row['assigned_agent_name'] ?? row['agent_name'])?.toString() ?? 'Unknown Agent';
  }

  static Future<List<Map<String, dynamic>>> _fetchCustomerRows({String? agentId}) async {
    final query = <String, String>{
      'latitude': 'is.not.null',
      'longitude': 'is.not.null',
    };
    if (agentId != null && agentId != 'all') {
      query['assigned_agent'] = 'eq.$agentId';
    }
    final res = await http.get(
      _uri('customers', query),
      headers: _headers,
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    final data = jsonDecode(res.body);
    final list = (data is Map && data['data'] is List) ? data['data'] as List : data as List;
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where(_hasCoords)
        .toList();
  }

  /// GET customer locations with lat/lng and map them onto the existing field
  /// map marker model.
  static Future<List<CollectionPoint>> fetchPoints({String? agentId}) async {
    final rows = await _fetchCustomerRows(agentId: agentId);
    final agents = await fetchAgents();
    final agentNames = {for (final a in agents) a.id: a.name};

    return rows.map((row) {
      return CollectionPoint.fromJson({
        ...row,
        'customer_name': row['customer_name'] ?? row['full_name'],
        'agent_id': row['assigned_agent'],
        'agent_name': _agentNameFor(row, agentNames),
        'amount': 0,
        'collected_at': row['created_at'],
        'collected': (row['loan_status']?.toString() ?? '') == 'active',
      });
    }).toList();
  }

  static Future<FieldMapSummary> fetchSummary({String? agentId}) async {
    final points = await _fetchCustomerRows(agentId: agentId);
    final activeAgents = points
        .map((p) => (p['assigned_agent'] ?? p['agent_id'])?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;
    final collectedCount = points
        .where((p) => (p['loan_status']?.toString() ?? '') == 'active')
        .length;
    return FieldMapSummary(
      onMap: points.length,
      collectedCount: collectedCount,
      activeAgents: activeAgents,
      totalCollected: 0,
    );
  }

  static Future<List<AgentOption>> fetchAgents() async {
    final res = await http.get(
      _uri('profiles', {'role': 'eq.agent'}),
      headers: _headers,
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    final data = jsonDecode(res.body);
    final list =
        (data is Map && data['data'] is List) ? data['data'] as List : data as List;
    return list.map((e) => AgentOption.fromJson(e as Map<String, dynamic>)).toList();
  }
}
