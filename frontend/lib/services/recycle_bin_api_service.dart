import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/recycle_bin.dart';
import 'method_override_http.dart';
import 'session_service.dart';

class RecycleBinApiService {
  static String get _endpoint => '${ApiConfig.normalizedBaseUrl}/rest.php';

  static Map<String, String> get _headers {
    final token = SessionService.instance.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<RecycleBinItem>> fetchItems() async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'table': 'recycle_bin',
    });
    
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final data = decoded is List ? decoded : <dynamic>[];
      return data
          .map((item) => RecycleBinItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_errorMessage(response, 'Failed to load recycle bin items'));
  }

  static Future<void> restoreItem(String id) async {
    // RecycleBinController::restore() handles this as a real POST
    // (`POST ?table=recycle_bin&action=restore&id=<id>`) — it is not one of
    // the PATCH/PUT/DELETE verbs postWithMethodOverride exists to disguise,
    // so call http.post directly instead of routing it through that helper.
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'table': 'recycle_bin',
      'action': 'restore',
      'id': 'eq.$id',
    });

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'id': id}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errorMessage(response, 'Failed to restore item'));
    }
  }

  static Future<void> deletePermanently(String id) async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'table': 'recycle_bin',
      'id': 'eq.$id',
    });
    
    final response = await postWithMethodOverride(
      uri,
      method: 'DELETE',
      headers: _headers,
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_errorMessage(response, 'Failed to delete item permanently'));
    }
  }

  static Future<void> emptyRecycleBin() async {
    // Backend only wipes the whole table when `all=1` is present (see
    // RecycleBinController::handle) — without it, DELETE with no id/filter
    // is refused with "Refusing to delete without a filter".
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'table': 'recycle_bin',
      'all': '1',
    });
    
    final response = await postWithMethodOverride(
      uri,
      method: 'DELETE',
      headers: _headers,
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_errorMessage(response, 'Failed to empty recycle bin'));
    }
  }

  static String _errorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }
}