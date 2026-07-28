import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Low-level REST client matching the PHP backend's generic resource
/// endpoint (`Model::forTable()` / `ResourceController` / `rest.php?table=`).
///
/// ASSUMED URL SHAPE — adjust `baseUrl` and, if needed, the path building in
/// [_uri] to match your actual router:
///   GET    /api/rest.php?table=loans              -> list rows (filterable via extra query params)
///   GET    /api/rest.php?table=loans&id=<id>      -> single row
///   POST   /api/rest.php?table=loans              -> insert (body: object, or array for bulk)
///   PATCH  /api/rest.php?table=loans&id=<id>      -> update by id
///   DELETE /api/rest.php?table=loans&id=<id>      -> delete by id
///
/// Auth: the backend's `requireAuth()` expects a bearer token — set
/// [ApiClient.instance.authToken] right after your login call succeeds
/// (and clear it on logout).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String baseUrl = ApiConfig.baseUrl;

  /// Set after login, e.g. `ApiClient.instance.authToken = token;`
  String? authToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Uri _uri(String table, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl/rest.php').replace(queryParameters: {
      'table': table,
      ...?query,
    });
  }

  Future<List<Map<String, dynamic>>> list(String table,
      {Map<String, String>? query}) async {
    final res = await http.get(_uri(table, query), headers: _headers);
    final data = _decode(res);
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getOne(String table, String id) async {
    final rows = await list(table, query: {'id': id});
    return rows.isEmpty ? null : rows.first;
  }

  /// Insert a row. Omit keys the server should fill in itself (e.g.
  /// `loan_number`, which `LoanController::fillLoanNumbers()` generates
  /// server-side when absent).
  Future<Map<String, dynamic>> create(
      String table, Map<String, dynamic> row) async {
    final res =
        await http.post(_uri(table), headers: _headers, body: jsonEncode(row));
    final data = _decode(res);
    if (data is List && data.isNotEmpty) {
      return data.first as Map<String, dynamic>;
    }
    if (data is Map<String, dynamic>) return data;
    throw ApiException(res.statusCode, 'Unexpected response creating $table');
  }

  Future<Map<String, dynamic>> update(
      String table, String id, Map<String, dynamic> row) async {
    final res = await http.patch(_uri(table, {'id': id}),
        headers: _headers, body: jsonEncode(row));
    final data = _decode(res);
    if (data is List && data.isNotEmpty) {
      return data.first as Map<String, dynamic>;
    }
    if (data is Map<String, dynamic>) return data;
    throw ApiException(res.statusCode, 'Unexpected response updating $table');
  }

  Future<void> delete(String table, String id) async {
    final res = await http.delete(_uri(table, {'id': id}), headers: _headers);
    if (res.statusCode >= 300) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 300) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] != null) return body['error'].toString();
    } catch (_) {
      // fall through to generic message
    }
    return 'Request failed (${res.statusCode})';
  }
}
