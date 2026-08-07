/// Save as: lib/services/chit_group_api_service.dart  (replaces existing file)

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'method_override_http.dart';
import 'session_service.dart';
import '../models/chit_group.dart';
import '../models/chit_member.dart';

class ChitGroupApiService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _restEndpoint = '$_baseUrl/rest.php';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (SessionService.instance.token != null)
          'Authorization': 'Bearer ${SessionService.instance.token}',
      };

  // ---- GROUPS: READ ----
  static Future<List<ChitGroup>> fetchAll() async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups');
    final res = await http.get(uri, headers: _headers);
    _throwIfError(res);
    return _listFrom(res).map((e) => ChitGroup.fromJson(e)).toList();
  }

  // ---- GROUPS: CREATE (admin only — enforced server-side) ----
  static Future<ChitGroup> create(ChitGroup group) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(group.toJson()),
    );
    _throwIfError(res);
    return ChitGroup.fromJson(_rowFrom(res));
  }

  // ---- GROUPS: UPDATE (admin full edit) ----
  static Future<ChitGroup> update(ChitGroup group) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups&id=${group.id}');
    final res = await postWithMethodOverride(
      uri,
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode(group.toJson()),
    );
    _throwIfError(res);
    return ChitGroup.fromJson(_rowFrom(res));
  }

  // ---- GROUPS: UPDATE (admin or agent — collection fields only,
  // per the PHP allow-list). Called after a member's payment is
  // recorded so the group's running totals + status stay in sync.
  // NOTE: previously this sent `pending_amount: null` — fixed to send
  // the real computed value so the backend actually persists it.
  static Future<ChitGroup> recordCollection({
    required String groupId,
    required double collectedAmount,
    required double pendingAmount,
    String? status,
  }) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups&id=$groupId');
    final res = await postWithMethodOverride(
      uri,
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode({
        'collected_amount': collectedAmount,
        'pending_amount': pendingAmount,
        if (status != null) 'status': status,
      }),
    );
    _throwIfError(res);
    return ChitGroup.fromJson(_rowFrom(res));
  }

  // ---- GROUPS: DELETE (admin only — enforced server-side) ----
  static Future<void> delete(String id) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups&id=$id');
    final res = await postWithMethodOverride(
      uri,
      method: 'DELETE',
      headers: _headers,
    );
    _throwIfError(res);
  }

  // ---- MEMBERS: READ ----
  static Future<List<ChitMember>> fetchMembers(String groupId) async {
    final uri =
        Uri.parse('$_restEndpoint?table=chit_members&group_id=$groupId');
    final res = await http.get(uri, headers: _headers);
    _throwIfError(res);
    return _listFrom(res).map((e) => ChitMember.fromJson(e)).toList();
  }

  // ---- MEMBERS: CREATE ----
  // Gated to admin only in the UI (see ChitGroupsScreen role checks) —
  // no member-level role check was shown on the backend, so this is a
  // frontend-only restriction per your request.
  static Future<ChitMember> addMember({
    required String groupId,
    required String customerId,
    required String memberName,
    String? phone,
    required double contributionAmount,
    DateTime? dueDate,
  }) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_members');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'group_id': groupId,
        'customer_id': customerId,
        'member_name': memberName,
        'contribution_amount': contributionAmount,
        if (dueDate != null)
          'due_date': dueDate.toIso8601String().split('T').first,
        'payment_status': 'pending',
      }),
    );
    _throwIfError(res);
    return ChitMember.fromJson(_rowFrom(res));
  }

  // ---- MEMBERS: DELETE ----
  // Gated to admin only in the UI, same note as addMember above.
  static Future<void> deleteMember(String memberId) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_members&id=$memberId');
    final res = await postWithMethodOverride(
      uri,
      method: 'DELETE',
      headers: _headers,
    );
    _throwIfError(res);
  }

  // ---- MEMBERS: record a contribution (admin or agent) ----
  static Future<ChitMember> collectFromMember({
    required String memberId,
    required ChitPaymentStatus status,
  }) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_members&id=$memberId');
    final res = await postWithMethodOverride(
      uri,
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode({'payment_status': ChitMember.statusToString(status)}),
    );
    _throwIfError(res);
    return ChitMember.fromJson(_rowFrom(res));
  }

  // ---- CUSTOMERS (for the Add Member dropdown) ----
  // ASSUMPTION: a `customers` resource exists at ?table=customers on the
  // same router. Adjust the table name / ChitCustomerOption.fromJson
  // keys if your customers endpoint differs.
  static Future<List<ChitCustomerOption>> fetchCustomers() async {
    final uri = Uri.parse('$_restEndpoint?table=customers');
    final res = await http.get(uri, headers: _headers);
    _throwIfError(res);
    return _listFrom(res).map((e) => ChitCustomerOption.fromJson(e)).toList();
  }

  // ---- helpers ----
  static List<Map<String, dynamic>> _listFrom(http.Response res) {
    final decoded = jsonDecode(res.body);
    final List list = decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded as List;
    return list.cast<Map<String, dynamic>>();
  }

  static Map<String, dynamic> _rowFrom(http.Response res) {
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return Map<String, dynamic>.from(data);
      if (data is List && data.isNotEmpty && data.first is Map) {
        return Map<String, dynamic>.from(data.first as Map);
      }
      return Map<String, dynamic>.from(decoded);
    }
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      return Map<String, dynamic>.from(decoded.first as Map);
    }
    throw ChitGroupApiException(
      'Unexpected response shape from server',
      res.statusCode,
    );
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
