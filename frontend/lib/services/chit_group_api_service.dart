import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_service.dart';
import '../models/chit_group.dart';

class ChitGroupApiService {
  static const String _baseUrl = 'http://localhost:8889';
  static const String _restEndpoint = '$_baseUrl/rest.php';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (SessionService.instance.token != null)
          'Authorization': 'Bearer ${SessionService.instance.token}',
      };

  // ---- READ ----
  static Future<List<ChitGroup>> fetchAll() async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups');
    final res = await http.get(uri, headers: _headers);
    _throwIfError(res);

    final decoded = jsonDecode(res.body);
    final List list = decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded as List;

    return list
        .map((e) => ChitGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- CREATE ----
  static Future<ChitGroup> create(ChitGroup group) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(group.toJson()),
    );
    _throwIfError(res);

    final decoded = jsonDecode(res.body);
    final data = decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
    return ChitGroup.fromJson(data as Map<String, dynamic>);
  }

  // ---- UPDATE (admin: full edit) ----
  static Future<ChitGroup> update(ChitGroup group) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups&id=${group.id}');
    final res = await http.patch(
      uri,
      headers: _headers,
      body: jsonEncode(group.toJson()),
    );
    _throwIfError(res);

    final decoded = jsonDecode(res.body);
    final data = decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
    return ChitGroup.fromJson(data as Map<String, dynamic>);
  }

  // ---- UPDATE (agent: collection-only fields, per your PHP allow-list) ----
  static Future<void> recordCollection({
    required String groupId,
    required double collectedAmount,
    String? status,
  }) async {
    final uri =
        Uri.parse('$_restEndpoint?table=chit_groups&id=$groupId');
    final res = await http.patch(
      uri,
      headers: _headers,
      body: jsonEncode({
        'collected_amount': collectedAmount,
        'pending_amount': null, // let backend compute if it does; else calc here
        if (status != null) 'status': status,
      }),
    );
    _throwIfError(res);
  }

  // ---- DELETE ----
  static Future<void> delete(String id) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups&id=$id');
    final res = await http.delete(uri, headers: _headers);
    _throwIfError(res);
  }

  static void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String message = 'Request failed (${res.statusCode})';
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['error'] != null) {
        message = decoded['error'].toString();
      }
    } catch (_) {}
    throw ChitGroupApiException(message, res.statusCode);
  }
}

class ChitGroupApiException implements Exception {
  ChitGroupApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;

  @override
  String toString() => message;
}