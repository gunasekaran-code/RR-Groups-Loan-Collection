import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_service.dart'; // adjust path — wherever SessionService lives

class ApiService {
  static const String _baseUrl = 'http://localhost:8889';
  static const String _restEndpoint = '$_baseUrl/rest.php';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (SessionService.instance.token != null &&
            SessionService.instance.token!.isNotEmpty)
          'Authorization': 'Bearer ${SessionService.instance.token}',
      };

  static Future<dynamic> get(String table, {Map<String, String>? query}) async {
    final uri = Uri.parse(_restEndpoint).replace(queryParameters: {
      'table': table,
      ...?query,
    });
    final res = await http.get(uri, headers: _headers);
    return _handle(res);
  }

  static Future<dynamic> post(String table,
      {required Map<String, dynamic> body}) async {
    final uri = Uri.parse(_restEndpoint).replace(queryParameters: {'table': table});
    final res = await http.post(uri, headers: _headers, body: jsonEncode(body));
    return _handle(res);
  }

  static Future<dynamic> put(String table,
      {required String id, required Map<String, dynamic> body}) async {
    final uri = Uri.parse(_restEndpoint)
        .replace(queryParameters: {'table': table, 'id': id});
    final res = await http.put(uri, headers: _headers, body: jsonEncode(body));
    return _handle(res);
  }

  static Future<dynamic> delete(String table, {required String id}) async {
    final uri = Uri.parse(_restEndpoint)
        .replace(queryParameters: {'table': table, 'id': id});
    final res = await http.delete(uri, headers: _headers);
    return _handle(res);
  }

  static dynamic _handle(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message = 'Request failed (${res.statusCode})';
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'].toString();
        }
      } catch (_) {}
      throw ApiException(message, res.statusCode);
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;

  @override
  String toString() => message;
}