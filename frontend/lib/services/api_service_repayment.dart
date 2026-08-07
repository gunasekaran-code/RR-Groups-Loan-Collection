import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/repayment_installment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'method_override_http.dart';

/// Talks to the `ScheduleController` endpoint backing `repayment_schedule`.
///
/// NOTE: I don't have your project's real base-URL/auth-token setup in
/// context (no other .dart files were shared), so both are stubbed below
/// with TODOs. If you already have a shared `ApiService`/`AuthStorage`
/// class, swap `_baseUrl` and `_authHeaders()` to call into it instead of
/// duplicating this here.
class ApiServiceRepayment {
  ApiServiceRepayment._();
  static final ApiServiceRepayment instance = ApiServiceRepayment._();

  static String get _baseUrl => '${ApiConfig.baseUrl}rest.php';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // match your login save key
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri([Map<String, String>? query]) {
    return Uri.parse(_baseUrl).replace(queryParameters: {
      'table': 'repayment_schedule',
      ...?query,
    });
  }

  Future<List<RepaymentInstallment>> fetchSchedule(String loanId) async {
    final uri = _uri({'loan_id': loanId});
    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode != 200) {
      throw ApiException(
          'Failed to load repayment schedule', res.statusCode, res.body);
    }

    final decoded = jsonDecode(res.body);
    final List<dynamic> rows = decoded is List
        ? decoded
        : (decoded['data'] ?? decoded['rows'] ?? []) as List<dynamic>;

    return rows
        .map((e) => RepaymentInstallment.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.installmentNo.compareTo(b.installmentNo));
  }

  /// Create a new installment row (admin/agent only, per PHP role check).
  Future<RepaymentInstallment> createInstallment(
    RepaymentInstallment installment,
  ) async {
    final res = await http.post(
      _uri(),
      headers: await _headers(),
      body: jsonEncode(installment.toJson()),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException(
          'Failed to create installment', res.statusCode, res.body);
    }
    return RepaymentInstallment.fromJson(jsonDecode(res.body));
  }

  /// Update paid/balance/status on an installment (admin/agent only).
  Future<RepaymentInstallment> updateInstallment(
    String id,
    Map<String, dynamic> changes,
  ) async {
    final res = await postWithMethodOverride(
      _uri({'id': id}),
      method: 'PATCH',
      headers: await _headers(),
      body: jsonEncode(changes),
    );

    if (res.statusCode != 200) {
      throw ApiException(
          'Failed to update installment', res.statusCode, res.body);
    }
    return RepaymentInstallment.fromJson(jsonDecode(res.body));
  }

  /// Delete an installment row (admin only).
  Future<void> deleteInstallment(String id) async {
    final res = await postWithMethodOverride(
      _uri({'id': id}),
      method: 'DELETE',
      headers: await _headers(),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw ApiException(
          'Failed to delete installment', res.statusCode, res.body);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String body;
  ApiException(this.message, this.statusCode, this.body);

  @override
  String toString() => '$message (status $statusCode): $body';
}
