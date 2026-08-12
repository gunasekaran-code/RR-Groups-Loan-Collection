import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_api_service.dart';
import 'session_service.dart';
import 'collection_api_service.dart';
import 'method_override_http.dart';
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
  /// Each row is enriched with customer/location/loan-balance details
  /// pulled from the joined loan record, so the UI can group everything by
  /// customer without a second round trip.
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
            'loan_type': row['loan_type'] ??
                loan?['loan_type'] ??
                loan?['collection_type'],
            'loan_name': row['loan_name'] ??
                loan?['loan_name'] ??
                loan?['scheme_name'] ??
                loan?['collection_name'] ??
                loan?['loan_number'],
            'customer_name': row['customer_name'] ?? loan?['customer_name'],
            'customer_id': row['customer_id'] ?? loan?['customer_id'],
            'agent_id': row['agent_id'] ?? loan?['assigned_agent'],
            'agent_name': row['agent_name'] ?? loan?['agent_name'],
            'contact_phone': row['contact_phone'] ??
                row['phone'] ??
                loan?['contact_phone'] ??
                loan?['phone'],
            'address':
                row['address'] ?? loan?['address'] ?? loan?['customer_address'],
            'latitude': row['latitude'] ?? loan?['latitude'],
            'longitude': row['longitude'] ?? loan?['longitude'],
            'outstanding_balance': row['outstanding_balance'] ??
                loan?['outstanding_balance'] ??
                loan?['balance'],
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

  /// Fetches and groups the agent's due collections by customer in one call
  /// — this is what the collections list screen should use.
  static Future<List<AgentCustomerGroup>>
      fetchAssignedCollectionGroups() async {
    final items = await fetchAssignedCollections();
    return AgentCustomerGroup.groupItems(items);
  }

  /// Records a collection against a single installment: creates a row in
  /// `collections` via [CollectionApiService.createCollection], then
  /// (best-effort) updates the schedule row so it drops off the agent's due
  /// list once fully paid.
  ///
  /// [markPaid] controls whether the schedule row is flagged `paid`. Pass
  /// `false` for a partial payment so the remaining balance stays open —
  /// the schedule's `due_amount` is reduced by the collected amount instead.
  static Future<void> collectPayment({
    required AgentCollectionItem item,
    required double amount,
    required String paymentMethod,
    required DateTime collectionDate,
    String? notes,
    bool markPaid = true,
  }) async {
    final currentUser = SessionService.instance.currentUser;
    final payload = {
      'customer_id': item.customerId,
      'customer_name': item.customerName,
      'loan_id': item.loanId,
      'loan_number': item.loanNumber,
      'loan_type': item.loanType,
      'loan_name': item.loanName,
      'collection_amount': amount,
      'payment_method': paymentMethod,
      'collection_date': _toIsoDate(collectionDate),
      'agent_id': currentUser?.userId,
      'agent_name': currentUser?.name,
      'schedule_id': item.scheduleId ?? item.id,
      'receipt_number': _generateReceiptNumber(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    await CollectionApiService.createCollection(payload);

    try {
      if (markPaid) {
        await postWithMethodOverride(
          _scheduleUri({'id': item.id}),
          method: 'PATCH',
          headers: await _headers(),
          body: jsonEncode({'status': 'paid'}),
        );
      } else {
        final remainingDue =
            (item.dueAmount - amount) < 0 ? 0.0 : (item.dueAmount - amount);
        await postWithMethodOverride(
          _scheduleUri({'id': item.id}),
          method: 'PATCH',
          headers: await _headers(),
          body: jsonEncode({'due_amount': remainingDue}),
        );
      }
    } catch (_) {
      // Non-fatal — the collection itself was already recorded above.
    }
  }

  /// Records a single payment against a customer who may have several due
  /// loans/installments. The amount is applied like a payment waterfall —
  /// oldest due date first — fully settling each installment before moving
  /// to the next, so every affected schedule row is updated and every
  /// collection is persisted individually to the backend.
  static Future<int> collectForCustomer({
    required AgentCustomerGroup group,
    required double amount,
    required String paymentMethod,
    required DateTime collectionDate,
    String? notes,
  }) async {
    final sortedItems = [...group.items]..sort((a, b) {
        final aDate = a.dueDate ?? DateTime(2100);
        final bDate = b.dueDate ?? DateTime(2100);
        return aDate.compareTo(bDate);
      });

    double remaining = amount;
    var recordsCreated = 0;
    for (final item in sortedItems) {
      if (remaining <= 0) break;
      final payAmount =
          remaining >= item.dueAmount ? item.dueAmount : remaining;
      if (payAmount <= 0) continue;
      remaining -= payAmount;
      final fullyCovered = payAmount >= (item.dueAmount - 0.01);
      await collectPayment(
        item: item,
        amount: payAmount,
        paymentMethod: paymentMethod,
        collectionDate: collectionDate,
        notes: notes,
        markPaid: fullyCovered,
      );
      recordsCreated++;
    }
    return recordsCreated;
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
