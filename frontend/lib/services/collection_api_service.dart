// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../config/api_config.dart';
// import 'auth_api_service.dart'; // reuse your existing base URL + token storage

// class CollectionApiService {
//   static const String _baseUrl = ApiConfig.baseUrl;
//   static const String _restEndpoint = '$_baseUrl/rest.php';

//   static Future<Map<String, String>> _headers() async {
//     final token = await AuthApiService.instance.getToken();
//     return {
//       'Content-Type': 'application/json',
//       if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
//     };
//   }

//   static Uri _uri([Map<String, String>? query]) {
//     return Uri.parse(_restEndpoint).replace(queryParameters: {
//       'table': 'collections',
//       ...?query,
//     });
//   }

//   /// GET /collections -> raw list of rows from the `collections` table
//   static Future<List<Map<String, dynamic>>> fetchCollections() async {
//     final res = await http.get(
//       _uri(),
//       headers: await _headers(),
//     );

//     if (res.statusCode != 200) {
//       throw Exception('Failed to load collections (${res.statusCode}): ${res.body}');
//     }

//     final decoded = jsonDecode(res.body);
//     final List list = decoded is List ? decoded : (decoded['data'] ?? []);
//     return list.cast<Map<String, dynamic>>();
//   }

//   /// POST /collections
//   static Future<Map<String, dynamic>> createCollection(Map<String, dynamic> payload) async {
//     final res = await http.post(
//       _uri(),
//       headers: await _headers(),
//       body: jsonEncode(payload),
//     );

//     if (res.statusCode != 200 && res.statusCode != 201) {
//       throw Exception('Failed to create collection (${res.statusCode}): ${res.body}');
//     }
//     final decoded = jsonDecode(res.body);
//     return decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : {};
//   }

//   /// PATCH /collections/{id}
//   static Future<Map<String, dynamic>> updateCollection(String id, Map<String, dynamic> payload) async {
//     final res = await http.patch(
//       _uri({'id': id}),
//       headers: await _headers(),
//       body: jsonEncode(payload),
//     );

//     if (res.statusCode != 200) {
//       throw Exception('Failed to update collection (${res.statusCode}): ${res.body}');
//     }
//     final decoded = jsonDecode(res.body);
//     return decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : {};
//   }

//   /// DELETE /collections/{id}
//   static Future<void> deleteCollection(String id) async {
//     final res = await http.delete(
//       _uri({'id': id}),
//       headers: await _headers(),
//     );

//     if (res.statusCode != 200 && res.statusCode != 204) {
//       throw Exception('Failed to delete collection (${res.statusCode}): ${res.body}');
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_api_service.dart'; // reuse your existing base URL + token storage
import '../models/payment_history.dart';
import 'method_override_http.dart';

class CollectionApiService {
  static String get _restEndpoint => '${ApiConfig.normalizedBaseUrl}/rest.php';

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

  /// GET /collections -> raw list of rows from the `collections` table.
  /// Keep the payload small by applying reasonable pagination and ordering
  /// on the server when the caller is browsing the admin list.
  static Future<List<Map<String, dynamic>>> fetchCollections({
    int limit = 200,
    int offset = 0,
    String order = 'collection_date.desc',
  }) async {
    final res = await http.get(
      _uri({
        'limit': limit.toString(),
        'offset': offset.toString(),
        'order': order,
      }),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load collections (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    final List list = decoded is List ? decoded : (decoded['data'] ?? []);
    return list.cast<Map<String, dynamic>>();
  }

  /// GET payment history -> collections rows that are actually paid/collected,
  /// parsed into PaymentHistoryItem and scoped by the loan ids the caller
  /// passes in. This is more reliable than matching on customer_id/name
  /// directly, since customer_id can be null on collection rows — loan_id
  /// is always populated and is a hard foreign key back to the loan, which
  /// is itself tied to a trustworthy customer_id (see LoanService/loans).
  static Future<List<PaymentHistoryItem>> fetchPaymentHistory({
    String? customerId,
    List<String>? loanIds,
    String? agentId,
  }) async {
    final rows = await fetchCollections();
    final loanIdSet = loanIds?.toSet();
    final items = rows
        .map((row) => PaymentHistoryItem.fromJson(row))
        .where((item) => item.isPaidRecord)
        .where((item) {
          final matchesCustomer = customerId != null &&
              customerId.isNotEmpty &&
              item.customerId == customerId;
          final matchesLoan =
              loanIdSet != null && loanIdSet.contains(item.loanId);
          if (customerId != null && customerId.isNotEmpty) {
            return matchesCustomer || matchesLoan;
          }
          return loanIdSet == null || matchesLoan;
        })
        .where((item) => agentId == null || item.agentId == agentId)
        .toList();

    // Most recent first.
    items.sort((a, b) {
      final ad = a.collectedDate;
      final bd = b.collectedDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    return items;
  }

  /// POST /collections
  static Future<Map<String, dynamic>> createCollection(
      Map<String, dynamic> payload) async {
    final res = await http.post(
      _uri(),
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
          'Failed to create collection (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : {};
  }

  /// PATCH /collections/{id}
  static Future<Map<String, dynamic>> updateCollection(
      String id, Map<String, dynamic> payload) async {
    final res = await postWithMethodOverride(
      _uri({'id': id}),
      method: 'PATCH',
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception(
          'Failed to update collection (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : {};
  }

  /// DELETE /collections/{id}
  static Future<void> deleteCollection(String id) async {
    final res = await postWithMethodOverride(
      _uri({'id': id}),
      method: 'DELETE',
      headers: await _headers(),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
          'Failed to delete collection (${res.statusCode}): ${res.body}');
    }
  }
}
