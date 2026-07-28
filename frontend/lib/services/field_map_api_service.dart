// services/field_map_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/collection_point.dart';
import 'session_service.dart';

class FieldMapApiService {
  static const String _baseUrl = 'http://localhost:8889';
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

  /// GET all collection points with lat/lng for today (or filtered by agent).
  /// Backend scopes to own collections if role == agent.
  static Future<List<CollectionPoint>> fetchPoints({String? agentId}) async {
    final res = await http.get(
      _uri('collections', {
        'view': 'map',
        if (agentId != null && agentId != 'all') 'agent_id': agentId,
      }),
      headers: _headers,
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    final data = jsonDecode(res.body);
    final list =
        (data is Map && data['data'] is List) ? data['data'] as List : data as List;
    return list.map((e) => CollectionPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<FieldMapSummary> fetchSummary({String? agentId}) async {
    final res = await http.get(
      _uri('collections', {
        'view': 'map_summary',
        if (agentId != null && agentId != 'all') 'agent_id': agentId,
      }),
      headers: _headers,
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    return FieldMapSummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
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