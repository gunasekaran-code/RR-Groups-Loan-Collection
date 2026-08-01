import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_api_service.dart';
import 'session_service.dart';
import 'collection_api_service.dart';
import '../models/agent_collection.dart';

class AgentCollectionApiService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _restEndpoint = '$_baseUrl/rest.php';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthApiService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _scheduleUri([Map<String, String>? query]) {
    return Uri.parse(_restEndpoint).replace(queryParameters: {
      'table': 'repayment_schedule',
      ...?query,
    });
  }

  static Uri _loanUri([Map<String, String>? query]) {
    return Uri.parse(_restEndpoint).replace(queryParameters: {
      'table': 'loans',
      ...?query,
    });
  }

  /// GET repayment_schedule -> only the rows assigned to the logged-in
  /// agent via the loan's assigned_agent field, and only unpaid schedules.
  static Future<List<AgentCollectionItem>> fetchAssignedCollections() async {
    final currentUser = SessionService.instance.currentUser;
    final agentId = currentUser?.userId;
    if (agentId == null) return [];

    final loanRes = await http.get(
      _loanUri({'assigned_agent': 'eq.$agentId'}),
      headers: await _headers(),
    );
    if (loanRes.statusCode != 200) {
      throw Exception(
          'Failed to load assigned loans (${loanRes.statusCode}): ${loanRes.body}');
    }

    final loanDecoded = jsonDecode(loanRes.body);
    final loanList =
        loanDecoded is List ? loanDecoded : (loanDecoded['data'] ?? []);
    final loans = loanList.cast<Map<String, dynamic>>();
    if (loans.isEmpty) return [];

    final loanById = {
      for (final row in loans) (row['id']?.toString() ?? ''): row
    };
    final loanIds = loanById.keys.where((id) => id.isNotEmpty).toList();
    if (loanIds.isEmpty) return [];

    final loanIdsParam = '(${loanIds.join(',')})';
    final scheduleRes = await http.get(
      _scheduleUri({
        'loan_id': 'in.$loanIdsParam',
        'status': 'neq.paid',
      }),
      headers: await _headers(),
    );
    if (scheduleRes.statusCode != 200) {
      throw Exception(
          'Failed to load collections (${scheduleRes.statusCode}): ${scheduleRes.body}');
    }

    final decoded = jsonDecode(scheduleRes.body);
    final List list = decoded is List ? decoded : (decoded['data'] ?? []);
    final rows = list.cast<Map<String, dynamic>>();

    final items = rows
        .map((row) {
          final loan = loanById[row['loan_id']?.toString() ?? ''];
          return AgentCollectionItem.fromJson({
            ...row,
            'loan_number': row['loan_number'] ?? loan?['loan_number'],
            'customer_name': row['customer_name'] ?? loan?['customer_name'],
            'agent_id': row['agent_id'] ?? loan?['assigned_agent'],
            'agent_name': row['agent_name'] ?? loan?['agent_name'],
            'due_amount':
                row['due_amount'] ?? row['balance'] ?? row['emi_amount'],
          });
        })
        .where((item) => !item.isPaid)
        .toList();

    items.sort((a, b) {
      int rank(AgentCollectionStatus s) =>
          s == AgentCollectionStatus.overdue ? 0 : 1;
      final rankCompare = rank(a.status).compareTo(rank(b.status));
      if (rankCompare != 0) return rankCompare;
      final aDate = a.dueDate ?? DateTime(2100);
      final bDate = b.dueDate ?? DateTime(2100);
      return aDate.compareTo(bDate);
    });

    return items;
  }

  /// Records a collection: creates a row in `collections` via
  /// [CollectionApiService.createCollection], then (best-effort) marks the
  /// schedule row as paid so it drops off the agent's due list.
  static Future<void> collectPayment({
    required AgentCollectionItem item,
    required double amount,
    required String paymentMethod,
    required DateTime collectionDate,
    String? notes,
  }) async {
    final currentUser = SessionService.instance.currentUser;
    final payload = {
      'customer_id': item.customerId,
      'customer_name': item.customerName,
      'loan_id': item.loanId,
      'loan_number': item.loanNumber,
      'collection_amount': amount,
      'payment_method': paymentMethod,
      'collection_date': _toIsoDate(collectionDate),
      'agent_id': currentUser?.userId,
      'agent_name': currentUser?.name,
      'schedule_id': item.scheduleId ?? item.id,
      'receipt_number': _generateReceiptNumber(), // <-- added
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    await CollectionApiService.createCollection(payload);

    try {
      await http.patch(
        _scheduleUri({'id': item.id}),
        headers: await _headers(),
        body: jsonEncode({'status': 'paid'}),
      );
    } catch (_) {
      // Non-fatal — the collection itself was already recorded above.
    }
  }

  static String _generateReceiptNumber() {
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch
        .toString()
        .substring(5); // last digits, keeps it short
    return 'RCT-$ts';
  }

  static String _toIsoDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
