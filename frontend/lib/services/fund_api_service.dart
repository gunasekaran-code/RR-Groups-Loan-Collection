import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/fund.dart';
import 'method_override_http.dart';
import 'session_service.dart';

class FundApiService {
  static String get _restEndpoint => '${ApiConfig.normalizedBaseUrl}/rest.php';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (SessionService.instance.token != null &&
            SessionService.instance.token!.isNotEmpty)
          'Authorization': 'Bearer ${SessionService.instance.token}',
      };

  static Uri _uri(String resource, [Map<String, String>? query]) {
    return Uri.parse(_restEndpoint).replace(
      queryParameters: {'table': resource, ...?query},
    );
  }

  static Never _throwFromResponse(http.Response res) {
    String message = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  static Map<String, dynamic> _normalizeRow(dynamic data) {
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    if (data is Map<String, dynamic>) {
      if (data['data'] is List && (data['data'] as List).isNotEmpty) {
        return Map<String, dynamic>.from((data['data'] as List).first as Map);
      }
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
      }
      return data;
    }
    throw Exception('Unexpected response format');
  }

  static Future<FundsSummary> fetchSummary() async {
    final res = await http.get(_uri('funds'), headers: _headers);
    if (res.statusCode != 200) _throwFromResponse(res);

    final data = jsonDecode(res.body);
    if (data is List) {
      final rows = data.cast<Map<String, dynamic>>();
      final activeFunds = rows.where((row) {
        return (row['status']?.toString() ?? '').toLowerCase() == 'active';
      }).length;
      return FundsSummary(
        totalFunds: rows.length,
        activeFunds: activeFunds,
        maturityPayoutTotal: rows.fold<double>(0, (sum, row) {
          return sum + Fund.fromJson(row).maturityPayout;
        }),
        collectedTotal: rows.fold<double>(0, (sum, row) {
          return sum + Fund.fromJson(row).depositedAmount;
        }),
      );
    }

    return FundsSummary.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<Fund>> fetchAll() async {
    final res = await http.get(_uri('funds'), headers: _headers);
    if (res.statusCode != 200) _throwFromResponse(res);
    final data = jsonDecode(res.body);
    final list = (data is Map && data['data'] is List)
        ? data['data'] as List
        : (data is List ? data : const []);
    return list.map((e) => Fund.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Fund> create(Fund fund) async {
    final res = await http.post(
      _uri('funds'),
      headers: _headers,
      body: jsonEncode(fund.toCreateJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) _throwFromResponse(res);
    final data = jsonDecode(res.body);
    final row = _normalizeRow(data);
    return Fund.fromJson(row);
  }

  /// Updates an existing fund's core parameters (weekly amount, weeks,
  /// bonus, customer, dates). Used by the admin "Edit" action. Admins pass
  /// the FundController's role check unconditionally, so any field set is fine.
  static Future<Fund> update(String id, Fund fund) async {
    final res = await postWithMethodOverride(
      _uri('funds', {'id': id}),
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode(fund.toCreateJson()),
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    final data = jsonDecode(res.body);
    final row = _normalizeRow(data);
    return Fund.fromJson(row);
  }

  static Future<void> delete(String id) async {
    final res = await postWithMethodOverride(
      _uri('funds', {'id': id}),
      method: 'DELETE',
      headers: _headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) _throwFromResponse(res);
  }

  /// Records a collection against the fund. The backend's FundController
  /// allow-lists agent PATCH bodies to EXACTLY `collected_amount` and
  /// `status` — any other key present (action, amount, payment_method,
  /// payment_date, ...) is rejected with 403 "Agents can only record fund
  /// collections", even if a valid key is also present. So the caller must
  /// pre-compute the new running total and resulting status client-side;
  /// this method sends only those two allow-listed fields.
  static Future<Fund> recordCollection(
    String id, {
    required double collectedAmount,
    required String status,
    double? paymentAmount,
    String? paymentMethod,
    DateTime? paymentDate,
    String? fundCode,
    String? customerId,
    String? customerName,
  }) async {
    final res = await postWithMethodOverride(
      _uri('funds', {'id': id}),
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode({
        'collected_amount': collectedAmount,
        'status': status,
      }),
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    final data = jsonDecode(res.body);
    final row = _normalizeRow(data);

    if (paymentAmount != null && paymentAmount > 0) {
      try {
        final dateStr = (paymentDate ?? DateTime.now()).toIso8601String().substring(0, 10);
        await http.post(
          _uri('fund_payments'),
          headers: _headers,
          body: jsonEncode({
            'fund_id': id,
            'fund_number': fundCode ?? '',
            'customer_id': customerId ?? '',
            'customer_name': customerName ?? '',
            'amount': paymentAmount,
            'balance_after': collectedAmount,
            'payment_method': (paymentMethod ?? 'Cash').toLowerCase(),
            'payment_date': dateStr,
            'agent_name': SessionService.instance.currentUser?.name ?? 'Admin',
          }),
        );
      } catch (_) {}
    }

    return Fund.fromJson(row);
  }

  /// Settles the fund in full: sets collected_amount to totalDeposit,
  /// marks status matured, and records a passbook entry.
  static Future<Fund> settleInFull(
    String id, {
    required String paymentMethod,
    required DateTime settlementDate,
    required double totalDeposit,
    double depositedAmount = 0,
    String? fundCode,
    String? customerId,
    String? customerName,
  }) async {
    final remaining = totalDeposit - depositedAmount;
    final res = await postWithMethodOverride(
      _uri('funds', {'id': id}),
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode({
        'collected_amount': totalDeposit,
        'status': FundStatus.matured.label,
      }),
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    final data = jsonDecode(res.body);
    final row = _normalizeRow(data);

    if (remaining > 0) {
      try {
        final dateStr = settlementDate.toIso8601String().substring(0, 10);
        await http.post(
          _uri('fund_payments'),
          headers: _headers,
          body: jsonEncode({
            'fund_id': id,
            'fund_number': fundCode ?? '',
            'customer_id': customerId ?? '',
            'customer_name': customerName ?? '',
            'amount': remaining,
            'balance_after': totalDeposit,
            'payment_method': paymentMethod.toLowerCase(),
            'payment_date': dateStr,
            'agent_name': SessionService.instance.currentUser?.name ?? 'Admin',
            'notes': 'Settled in full',
          }),
        );
      } catch (_) {}
    }

    return Fund.fromJson(row);
  }

  static Future<List<FundEntry>> fetchPassbook(String fundId) async {
    final res = await http.get(
      _uri('fund_payments', {'fund_id': fundId}),
      headers: _headers,
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    final data = jsonDecode(res.body);
    final list = (data is Map && data['data'] is List)
        ? data['data'] as List
        : (data is List ? data : const []);

    return list
        .map((e) => FundEntry.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.week.compareTo(b.week));
  }
}
