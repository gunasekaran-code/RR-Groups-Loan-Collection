
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fund.dart';
import 'session_service.dart';

class FundApiService {
  static const String _baseUrl = 'http://localhost:8889';
  static const String _restEndpoint = '$_baseUrl/rest.php';

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
    final row = (data is Map && data['data'] != null) ? data['data'] : data;
    return Fund.fromJson(row as Map<String, dynamic>);
  }

  static Future<void> delete(String id) async {
    final res = await http.delete(_uri('funds/$id'), headers: _headers);
    if (res.statusCode != 200 && res.statusCode != 204) _throwFromResponse(res);
  }

  /// Settles the fund in full: collects the remaining balance,
  /// credits the full maturity bonus, and marks the fund matured.
  static Future<Fund> settleInFull(
    String id, {
    required String paymentMethod,
    required DateTime settlementDate,
  }) async {
    final res = await http.patch(
      _uri('funds/$id'),
      headers: _headers,
      body: jsonEncode({
        'action': 'settle_in_full',
        'payment_method': paymentMethod,
        'settlement_date':
            '${settlementDate.year.toString().padLeft(4, '0')}-${settlementDate.month.toString().padLeft(2, '0')}-${settlementDate.day.toString().padLeft(2, '0')}',
      }),
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    final data = jsonDecode(res.body);
    final row = (data is Map && data['data'] != null) ? data['data'] : data;
    return Fund.fromJson(row as Map<String, dynamic>);
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