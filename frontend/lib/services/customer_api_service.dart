import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/customer.dart';
import 'method_override_http.dart';
import 'session_service.dart'; 

class CustomerApiException implements Exception {
  final String message;
  final int? statusCode;
  CustomerApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class AgentOption {
  final String id;
  final String fullName;
  AgentOption(this.id, this.fullName);
}

class CustomerApiService {
  CustomerApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String get _baseUrl => ApiConfig.normalizedBaseUrl;
  static String get _customerEndpoint => '$_baseUrl/customers.php';
  static String get _restEndpoint => '$_baseUrl/rest.php';

  Map<String, String> get _headers {
    final token = SessionService.instance.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decodeBody(http.Response res) {
    if (res.body.isEmpty) return {};
    try {
      return jsonDecode(res.body);
    } catch (_) {
      throw CustomerApiException('Invalid server response', res.statusCode);
    }
  }

  Map<String, dynamic> _decodeObject(http.Response res) {
    final data = _decodeBody(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CustomerApiException(
          _messageFromPayload(data, res.statusCode), res.statusCode);
    }

    if (data is List) {
      if (data.isEmpty) return {};
      if (data.first is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data.first as Map);
      }
      throw CustomerApiException('Invalid server response', res.statusCode);
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw CustomerApiException('Invalid server response', res.statusCode);
  }

  List<dynamic> _decodeList(http.Response res) {
    final data = _decodeBody(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CustomerApiException(
          _messageFromPayload(data, res.statusCode), res.statusCode);
    }

    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is List) return nested;
      if (nested is Map<String, dynamic>) return [nested];
      return [data];
    }

    throw CustomerApiException('Invalid server response', res.statusCode);
  }

  String _messageFromPayload(dynamic data, int? statusCode) {
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          'Request failed (${statusCode ?? 'unknown'})';
    }
    return 'Request failed (${statusCode ?? 'unknown'})';
  }

  Future<List<Customer>> fetchAll() async {
    final res = await _client.get(
      Uri.parse('$_restEndpoint?table=customers'),
      headers: _headers,
    );
    final list = _decodeList(res);
    return list
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Customer> create(Customer customer,
      {String? email, String? password}) async {
    final res = await _client.post(
      Uri.parse(_customerEndpoint),
      headers: _headers,
      body:
          jsonEncode(customer.toRequestBody(email: email, password: password)),
    );
    final data = _decodeObject(res);
    return Customer.fromJson(data);
  }

  Future<Customer> update(
    String id,
    Customer customer, {
    String? email,
    String? password,
  }) async {
    final body = jsonEncode(
      customer.toRequestBody(email: email, password: password),
    );
    final endpoint = email != null || password != null
        ? Uri.parse('$_customerEndpoint?id=$id')
        : Uri.parse('$_restEndpoint?table=customers&id=eq.$id');
    final res = await postWithMethodOverride(
      endpoint,
      method: 'PATCH',
      headers: _headers,
      body: body,
    );
    final data = _decodeObject(res);
    return Customer.fromJson(data);
  }

  Future<void> delete(String id) async {
    final res = await postWithMethodOverride(
      Uri.parse('$_restEndpoint?table=customers&id=eq.$id'),
      method: 'DELETE',
      headers: _headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _decodeList(res); // throws with server message
    }
  }

  Future<List<AgentOption>> fetchAgents() async {
    final res = await _client.get(
      Uri.parse('$_restEndpoint?table=profiles&role=eq.agent'),
      headers: _headers,
    );
    final list = _decodeList(res);
    return list
        .map((e) => AgentOption(
              (e as Map<String, dynamic>)['id'].toString(),
              e['full_name'].toString(),
            ))
        .toList();
  }

  Future<List<Map<String, String>>> fetchAllLite() async {
    final res = await _client.get(
      // Use the customers resource directly so the notification recipient
      // picker always represents every row in the customers table.
      Uri.parse('$_restEndpoint?table=customers'),
      headers: _headers,
    );

    final list = _decodeList(res);

    return list.map((e) {
      final map = e as Map<String, dynamic>;
      return {
        'id': map['id']?.toString() ?? '',
        // Fallback to 'name' if your DB uses 'name' instead of 'full_name'
        'name': map['full_name']?.toString() ??
            map['name']?.toString() ??
            'Unknown',
        'email': map['email']?.toString() ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, String>>> fetchCustomerLogins() async {
    final res = await _client.get(
      Uri.parse(
          '$_restEndpoint?table=profiles&role=eq.customer&select=id,customer_id'),
      headers: _headers,
    );
    final list = _decodeList(res);
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      return {
        'id': map['id']?.toString() ?? '',
        'customer_id': map['customer_id']?.toString() ?? '',
      };
    }).toList();
  }
}
