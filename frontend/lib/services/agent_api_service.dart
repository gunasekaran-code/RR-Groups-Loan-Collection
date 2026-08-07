import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_api_service.dart'; // adjust import path to wherever this actually lives
import '../config/api_config.dart';
import 'method_override_http.dart';

/// CRUD client for the generic `ResourceController`-backed agent/profile
/// endpoint. Mirrors AuthApiService's error handling so both services throw
/// the same ApiException type.
class AgentApiService {
  AgentApiService._();
  static final AgentApiService instance = AgentApiService._();

  // ---------------------------------------------------------------------
  // Read agents through the generic profiles REST entrypoint, but create
  // and update accounts through the admin-only users endpoint so passwords
  // are hashed and extra profile fields are handled correctly.
  // ---------------------------------------------------------------------
  static const String baseUrl = ApiConfig.baseUrl;
  static const String agentEndpoint = '$baseUrl/rest.php?table=profiles';
  static const String userEndpoint = '$baseUrl/users.php';

  Future<Map<String, String>> _headers() async {
    final token = await AuthApiService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// GET all profiles. We deliberately don't push role/status filters into
  /// the query string (unknown QueryParser syntax on your end) — filtering
  /// happens client-side in AgentManagementScreen, same as before.
  Future<List<Map<String, dynamic>>> getAgents() async {
    late http.Response res;
    try {
      res = await http
          .get(Uri.parse(agentEndpoint), headers: await _headers())
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ApiException(
          'Could not reach the server. Check your connection and try again.',
          0);
    }
    final decoded = _decode(res);
    if (decoded is! List) {
      throw ApiException('Unexpected server response.', res.statusCode);
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  /// POST a new user account via the admin-only users endpoint.
  /// This route hashes `password` using bcrypt and also accepts
  /// `avatar_url`, `customer_id`, and other profile fields.
  Future<Map<String, dynamic>> createAgent(Map<String, dynamic> data) async {
    late http.Response res;
    try {
      res = await http
          .post(Uri.parse(userEndpoint),
              headers: await _headers(), body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ApiException(
          'Could not reach the server. Check your connection and try again.',
          0);
    }
    final decoded = _decode(res);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('Unexpected server response.', res.statusCode);
  }

  /// PATCH an existing profile row, filtered by id via query string.
  /// ASSUMPTION #2: QueryParser reads the filter from `?id=...` — adjust
  /// if your backend expects a different param name.
  Future<Map<String, dynamic>> updateAgent(
      String id, Map<String, dynamic> data) async {
    late http.Response res;
    try {
      res = await postWithMethodOverride(
        Uri.parse('$userEndpoint?id=$id'),
        method: 'PATCH',
        headers: await _headers(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ApiException(
          'Could not reach the server. Check your connection and try again.',
          0);
    }
    final decoded = _decode(res);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('Unexpected server response.', res.statusCode);
  }

  Future<void> deleteAgent(String id) async {
    late http.Response res;
    try {
      res = await postWithMethodOverride(
        Uri.parse('$agentEndpoint?id=$id'),
        method: 'DELETE',
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ApiException(
          'Could not reach the server. Check your connection and try again.',
          0);
    }
    _decode(res); // throws on non-2xx
  }

  dynamic _decode(http.Response res) {
    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      throw ApiException('Unexpected server response.', res.statusCode);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = (data is Map && (data['error'] ?? data['message']) != null)
          ? (data['error'] ?? data['message']).toString()
          : 'Something went wrong';
      throw ApiException(msg, res.statusCode);
    }
    return data;
  }
}
