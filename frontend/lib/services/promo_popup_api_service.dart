import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/promo_popup.dart';
import 'method_override_http.dart';
import 'session_service.dart';

class PromoPopupApiService {
  static String get _promoPopupEndpoint =>
      '${ApiConfig.normalizedBaseUrl}/rest.php';

  static Map<String, String> get _headers {
    final token = SessionService.instance.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<PromoPopup>> fetchPopups() async {
    final uri = Uri.parse(_promoPopupEndpoint).replace(queryParameters: {
      'table': 'promo_popups',
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final data = decoded is List ? decoded : <dynamic>[];
      return data
          .map((item) => PromoPopup.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_errorMessage(response, 'Failed to load promo popups'));
  }

  static Future<PromoPopup> createPopup(Map<String, dynamic> payload) async {
    final uri = Uri.parse(_promoPopupEndpoint).replace(queryParameters: {
      'table': 'promo_popups',
    });
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return PromoPopup.fromJson(_firstRow(response));
    }
    throw Exception(_errorMessage(response, 'Failed to create popup'));
  }

  static Future<PromoPopup> updatePopup(String id, Map<String, dynamic> payload) async {
    final uri = Uri.parse(_promoPopupEndpoint).replace(queryParameters: {
      'table': 'promo_popups',
      'id': 'eq.$id',
    });
    final response = await postWithMethodOverride(
      uri,
      method: 'PUT',
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return PromoPopup.fromJson(_firstRow(response));
    }
    throw Exception(_errorMessage(response, 'Failed to update popup'));
  }

  static Future<void> deletePopup(String id) async {
    final uri = Uri.parse(_promoPopupEndpoint).replace(queryParameters: {
      'table': 'promo_popups',
      'id': 'eq.$id',
    });
    final response = await postWithMethodOverride(
      uri,
      method: 'DELETE',
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_errorMessage(response, 'Failed to delete popup'));
    }
  }

  static Future<void> toggleActive(String id, bool isActive) async {
    // Making one active should ideally set others to inactive via backend logic
    await updatePopup(id, {'is_active': isActive ? 1 : 0});
  }

  static Map<String, dynamic> _firstRow(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      return Map<String, dynamic>.from(decoded.first as Map);
    }
    throw Exception('The server returned no promotional popup.');
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