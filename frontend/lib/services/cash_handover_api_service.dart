import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cash_handover.dart';
import '../models/user_role.dart';
import 'method_override_http.dart';
import 'session_service.dart';

class HandoverAgentOption {
  final String id;
  final String name;
  final bool active;

  const HandoverAgentOption({
    required this.id,
    required this.name,
    required this.active,
  });
}

/// Talks to the existing PHP REST endpoint at /rest.php?table=handovers.
/// The backend exposes generic CRUD for the handovers table, so this service
/// reads the rows and derives the summary/settlement view on the Flutter side.
class CashHandoverApiService {
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
      queryParameters: {
        'table': resource,
        ...?query,
      },
    );
  }

  static Never _throwFromResponse(http.Response res) {
    String message = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      }
    } catch (_) {
      // leave default message
    }
    throw Exception(message);
  }

  static String? _currentUserId() {
    final user = SessionService.instance.currentUser;
    return user?.userId.trim().isNotEmpty == true ? user!.userId.trim() : null;
  }

  static bool get _isAdmin =>
      SessionService.instance.currentUser?.role == UserRole.admin ||
      SessionService.instance.currentUser?.role == UserRole.owner;

  static Map<String, String>? _handoverScopeQuery() {
    if (_isAdmin) return null;
    final userId = _currentUserId();
    if (userId == null) return {'agent_id': 'eq.__no_user__'};
    return {'agent_id': 'eq.$userId'};
  }

  // Same scoping rule as handovers, applied to the `collections` table —
  // an agent only ever sees what they themselves collected.
  static Map<String, String>? _collectionsScopeQuery() =>
      _handoverScopeQuery();

  static double _rowDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  static List<Map<String, dynamic>> _decodeRows(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _throwFromResponse(res);
    }

    final body = jsonDecode(res.body);
    if (body is List) {
      return body.cast<Map<String, dynamic>>();
    }
    if (body is Map && body['data'] is List) {
      return (body['data'] as List).cast<Map<String, dynamic>>();
    }
    if (body is Map<String, dynamic>) {
      return [body];
    }
    return [];
  }

  static Future<List<HandoverAgentOption>> fetchActiveAgents() async {
    final res = await http.get(
      _uri('profiles', {'role': 'eq.agent', 'status': 'eq.active'}),
      headers: _headers,
    );
    if (res.statusCode != 200) _throwFromResponse(res);

    final rows = _decodeRows(res);
    final currentUserId = _currentUserId();
    final agents = rows
        .map(
          (row) => HandoverAgentOption(
            id: row['id']?.toString() ?? '',
            name: row['full_name']?.toString() ??
                row['name']?.toString() ??
                'Unknown Agent',
            active: (row['status']?.toString() ?? '').toLowerCase() == 'active',
          ),
        )
        .where((a) => a.id.isNotEmpty)
        .where(
            (a) => _isAdmin || currentUserId == null || a.id == currentUserId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return agents;
  }

  /// Total collected — and pending-to-hand-over — is what an agent actually
  /// received from customers, so it has to be read from `collections`
  /// (payments as they happen), not from `handovers` (only what's since been
  /// settled to the office). Mixing them up previously made "Total
  /// Collected" equal handover records instead of real collections, and made
  /// "Pending" mean "unverified handover rows" instead of the real
  /// collected-minus-handed-over gap.
  static Future<HandoverSummary> fetchSummary() async {
    final handoverRows = await _listRows();
    final handovers = handoverRows.map(HandoverRecord.fromJson).toList();
    final totalHandedOver = handovers
        .where((row) => row.verified)
        .fold<double>(0, (sum, row) => sum + row.totalAmount);

    final collections = await _fetchCollectionTotals();

    // An agent counts as "still pending" when what they've collected exceeds
    // what they've handed over and had verified — not merely because one
    // handover record happens to be sitting unverified.
    final handedOverByAgent = <String, double>{};
    for (final row in handovers) {
      if (!row.verified) continue;
      handedOverByAgent[row.agentId] =
          (handedOverByAgent[row.agentId] ?? 0) + row.totalAmount;
    }
    final agentsWithPending = collections.byAgent.entries
        .where((e) => e.value - (handedOverByAgent[e.key] ?? 0) > 0.01)
        .length;

    final totalPending =
        (collections.total - totalHandedOver).clamp(0.0, double.infinity);

    return HandoverSummary(
      totalCollected: collections.total,
      totalHandedOver: totalHandedOver,
      totalPending: totalPending,
      agentsWithPending: agentsWithPending,
      todayCollected: collections.todayTotal,
      cashCollected: collections.cash,
      onlineCollected: collections.online,
      todayCashCollected: collections.todayCash,
      todayOnlineCollected: collections.todayOnline,
    );
  }

  static Future<List<AgentSettlement>> fetchSettlements() async {
    final handoverRows = await _listRows();
    final handovers = handoverRows.map(HandoverRecord.fromJson).toList();
    final handedOverByAgent = <String, double>{};
    final agentNames = <String, String>{};
    for (final row in handovers) {
      agentNames[row.agentId] = row.agentName;
      if (row.verified) {
        handedOverByAgent[row.agentId] =
            (handedOverByAgent[row.agentId] ?? 0) + row.totalAmount;
      }
    }

    final collections = await _fetchCollectionTotals();
    collections.agentNames
        .forEach((id, name) => agentNames.putIfAbsent(id, () => name));

    final agentIds = {...collections.byAgent.keys, ...handedOverByAgent.keys};

    return agentIds.map((id) {
      return AgentSettlement(
        agentId: id,
        agentName: agentNames[id] ?? 'Unknown Agent',
        collected: collections.byAgent[id] ?? 0,
        handedOver: handedOverByAgent[id] ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.agentName.compareTo(b.agentName));
  }

  /// Reads the `collections` table (scoped the same way as handovers — an
  /// agent only ever sees their own) and aggregates it into overall, method
  /// (cash vs. online) and per-agent totals in one pass.
  static Future<_CollectionTotals> _fetchCollectionTotals() async {
    final rows = await _listCollectionRows();
    final now = DateTime.now();

    double total = 0, cash = 0, online = 0;
    double todayTotal = 0, todayCash = 0, todayOnline = 0;
    final byAgent = <String, double>{};
    final agentNames = <String, String>{};

    for (final row in rows) {
      final amount = _rowDouble(row['collection_amount']);
      if (amount == 0) continue;
      final isCash =
          (row['payment_method'] ?? '').toString().toLowerCase() == 'cash';
      final date = DateTime.tryParse(row['collection_date']?.toString() ?? '');
      final agentId = (row['agent_id'] ?? '').toString();

      total += amount;
      if (isCash) {
        cash += amount;
      } else {
        online += amount;
      }
      if (_isSameDay(date, now)) {
        todayTotal += amount;
        if (isCash) {
          todayCash += amount;
        } else {
          todayOnline += amount;
        }
      }
      if (agentId.isNotEmpty) {
        byAgent[agentId] = (byAgent[agentId] ?? 0) + amount;
        final name = (row['agent_name'] ?? '').toString();
        if (name.isNotEmpty) agentNames.putIfAbsent(agentId, () => name);
      }
    }

    return _CollectionTotals(
      total: total,
      cash: cash,
      online: online,
      todayTotal: todayTotal,
      todayCash: todayCash,
      todayOnline: todayOnline,
      byAgent: byAgent,
      agentNames: agentNames,
    );
  }

  static Future<List<Map<String, dynamic>>> _listCollectionRows() async {
    final res = await http.get(
      _uri('collections', _collectionsScopeQuery()),
      headers: _headers,
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    return _decodeRows(res);
  }

  static Future<List<HandoverRecord>> fetchHistory({int? limit}) async {
    final rows = await _listRows();
    final records = rows.map(HandoverRecord.fromJson).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (limit != null && limit > 0) {
      return records.take(limit).toList();
    }
    return records;
  }

  static Future<HandoverRecord> createHandover(HandoverRecord record) async {
    final res = await http.post(
      _uri('handovers'),
      headers: _headers,
      body: jsonEncode(record.toCreateJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throwFromResponse(res);
    }

    final rows = _decodeRows(res);
    final row = rows.isNotEmpty ? rows.first : <String, dynamic>{};
    return HandoverRecord.fromJson(row);
  }

  static Future<HandoverRecord> verifyHandover(String id) async {
    final res = await postWithMethodOverride(
      _uri('handovers', {'id': id}),
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode({
        'status': 'verified',
        if (SessionService.instance.currentUser?.userId.isNotEmpty == true)
          'received_by': SessionService.instance.currentUser!.userId,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throwFromResponse(res);
    }

    final rows = _decodeRows(res);
    final row = rows.isNotEmpty ? rows.first : <String, dynamic>{};
    return HandoverRecord.fromJson(row);
  }

  static Future<HandoverRecord> updateHandover(HandoverRecord record) async {
    final res = await postWithMethodOverride(
      _uri('handovers', {'id': record.id}),
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode(record.toUpdateJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throwFromResponse(res);
    }

    final rows = _decodeRows(res);
    final row = rows.isNotEmpty ? rows.first : <String, dynamic>{};
    return HandoverRecord.fromJson(row);
  }

  static Future<void> deleteHandover(String id) async {
    final res = await postWithMethodOverride(
      _uri('handovers', {'id': id}),
      method: 'DELETE',
      headers: _headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throwFromResponse(res);
    }
  }

  static Future<List<Map<String, dynamic>>> _listRows() async {
    final res = await http.get(
      _uri('handovers', _handoverScopeQuery()),
      headers: _headers,
    );
    if (res.statusCode != 200) _throwFromResponse(res);
    return _decodeRows(res);
  }
}

/// Aggregated `collections` figures — internal to this service, consumed by
/// [CashHandoverApiService.fetchSummary] and
/// [CashHandoverApiService.fetchSettlements] so both read the same numbers.
class _CollectionTotals {
  final double total;
  final double cash;
  final double online;
  final double todayTotal;
  final double todayCash;
  final double todayOnline;
  final Map<String, double> byAgent;
  final Map<String, String> agentNames;

  const _CollectionTotals({
    required this.total,
    required this.cash,
    required this.online,
    required this.todayTotal,
    required this.todayCash,
    required this.todayOnline,
    required this.byAgent,
    required this.agentNames,
  });
}
