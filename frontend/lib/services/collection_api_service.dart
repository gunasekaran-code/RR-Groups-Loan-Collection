import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_api_service.dart'; // reuse your existing base URL + token storage

class CollectionApiService {
  static const String _baseUrl = 'http://localhost:8889';
  static const String _restEndpoint = '$_baseUrl/rest.php';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthApiService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri([Map<String, String>? query]) {
    return Uri.parse(_restEndpoint).replace(queryParameters: {
      'table': 'collections',
      ...?query,
    });
  }

  /// GET /collections -> raw list of rows from the `collections` table
  static Future<List<Map<String, dynamic>>> fetchCollections() async {
    final res = await http.get(
      _uri(),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load collections (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    final List list = decoded is List ? decoded : (decoded['data'] ?? []);
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /collections
  static Future<Map<String, dynamic>> createCollection(Map<String, dynamic> payload) async {
    final res = await http.post(
      _uri(),
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create collection (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : {};
  }

  /// PATCH /collections/{id}
  static Future<Map<String, dynamic>> updateCollection(String id, Map<String, dynamic> payload) async {
    final res = await http.patch(
      _uri({'id': id}),
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update collection (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : {};
  }

  /// DELETE /collections/{id}
  static Future<void> deleteCollection(String id) async {
    final res = await http.delete(
      _uri({'id': id}),
      headers: await _headers(),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete collection (${res.statusCode}): ${res.body}');
    }
  }
}