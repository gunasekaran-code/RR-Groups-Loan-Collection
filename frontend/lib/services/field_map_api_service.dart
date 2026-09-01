import '../models/agent_collection.dart';
import '../models/agent_map_point.dart';
import '../models/customer.dart';
import 'agent_api_service.dart';
import 'agent_collection_api_service.dart';
import 'api_client.dart';
import 'customer_api_service.dart';
import 'session_service.dart';

class AgentRouteResult {
  final AgentRouteSummary summary;
  final List<AgentStop> stops;
  const AgentRouteResult({required this.summary, required this.stops});
}

class AdminAgentMapResult {
  final AdminAgentMapSummary summary;
  final List<AgentMapPoint> agents;
  const AdminAgentMapResult({required this.summary, required this.agents});
}

class FieldMapApiService {
  FieldMapApiService._();
  static Future<AgentRouteResult> fetchAgentRoute() async {
    final user = SessionService.instance.currentUser;
    final agentId = user?.userId ?? '';

    final Future<List<AgentCustomerGroup>> groupsFuture =
        AgentCollectionApiService.fetchAssignedCollectionGroups();
    final customersFuture = CustomerApiService().fetchAll();
    final todayStatsFuture = _fetchTodayCollectionStats(agentId);

    final List<AgentCustomerGroup> groups = await groupsFuture;
    final customers = await customersFuture;
    final todayStats = await todayStatsFuture;

    final customerById = <String, Customer>{
      for (final c in customers)
        if (c.id.isNotEmpty) c.id: c,
    };

    final stops = groups.map((g) {
      final customer = customerById[g.customerId];
      final code = (customer?.customerId.trim().isNotEmpty ?? false)
          ? customer!.customerId
          : (g.loanNumbers.isNotEmpty ? g.loanNumbers.first : g.customerId);
      final address = (customer?.address?.trim().isNotEmpty ?? false)
          ? customer!.address
          : g.address;
      final mobile = (customer?.mobile?.trim().isNotEmpty ?? false)
          ? customer!.mobile
          : g.contactPhone;

      return AgentStop(
        customerId: g.customerId,
        code: code,
        name: g.customerName,
        mobile: mobile,
        address: address,
        latitude: customer?.latitude,
        longitude: customer?.longitude,
        pendingAmount: g.totalDueWithPenalty,
        overdue: g.hasOverdue,
        itemCount: g.items.length,
      );
    }).toList();

    stops.sort((a, b) {
      if (a.overdue != b.overdue) return a.overdue ? -1 : 1;
      return b.pendingAmount.compareTo(a.pendingAmount);
    });

    final pendingAmount =
        stops.fold<double>(0, (sum, s) => sum + s.pendingAmount);

    return AgentRouteResult(
      summary: AgentRouteSummary(
        remaining: stops.length,
        completedToday: todayStats.count,
        pendingAmount: pendingAmount,
      ),
      stops: stops,
    );
  }
  static Future<AdminAgentMapResult> fetchAdminAgentMap() async {
    final agentsFuture = AgentApiService.instance.getAgents();
    final customersFuture = CustomerApiService().fetchAll();
    final loansFuture = ApiClient.instance.list('loans');

    final rawAgents = await agentsFuture;
    final customers = await customersFuture;
    final loans = await loansFuture;

    final agentsOnly = rawAgents.where(
      (row) => (row['role']?.toString().toLowerCase() ?? '') == 'agent',
    );

    final customersByAgent = <String, List<Customer>>{};
    for (final c in customers) {
      final agentId = c.assignedAgent;
      if (agentId == null || agentId.isEmpty) continue;
      customersByAgent.putIfAbsent(agentId, () => []).add(c);
    }

    final pendingByAgent = <String, double>{};
    for (final loan in loans) {
      final agentId = loan['assigned_agent']?.toString();
      if (agentId == null || agentId.isEmpty) continue;
      final status = (loan['status']?.toString() ?? '').toLowerCase();
      if (status == 'closed') continue;
      final balance = _toDouble(loan['outstanding_balance']);
      pendingByAgent[agentId] = (pendingByAgent[agentId] ?? 0) + balance;
    }

    final points = agentsOnly.map((row) {
      final id = row['id'].toString();
      final assigned = customersByAgent[id] ?? const <Customer>[];
      final withCoords = assigned
          .where((c) => _isValidLatLng(c.latitude, c.longitude))
          .toList();

      double? lat;
      double? lng;
      if (withCoords.isNotEmpty) {
        lat = withCoords.map((c) => c.latitude!).reduce((a, b) => a + b) /
            withCoords.length;
        lng = withCoords.map((c) => c.longitude!).reduce((a, b) => a + b) /
            withCoords.length;
      }

      return AgentMapPoint(
        id: id,
        fullName: (row['full_name'] ?? row['name'] ?? 'Unnamed').toString(),
        mobile: (row['mobile'] ?? '').toString(),
        email: (row['email'] ?? '').toString(),
        status: (row['status'] ?? 'active').toString(),
        customerCount: assigned.length,
        activeCount:
            assigned.where((c) => c.loanStatus.toLowerCase() == 'active').length,
        overdueCount: assigned
            .where((c) => c.loanStatus.toLowerCase() == 'overdue')
            .length,
        pendingAmount: pendingByAgent[id] ?? 0,
        latitude: lat,
        longitude: lng,
      );
    }).toList();
    points.sort((a, b) {
      final aPriority = a.isActive || a.pendingAmount > 0;
      final bPriority = b.isActive || b.pendingAmount > 0;
      if (aPriority != bPriority) return aPriority ? -1 : 1;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });

    final customersMapped = customers
        .where((c) =>
            (c.assignedAgent?.isNotEmpty ?? false) &&
            _isValidLatLng(c.latitude, c.longitude))
        .length;

    return AdminAgentMapResult(
      summary: AdminAgentMapSummary(
        totalAgents: points.length,
        activeAgents: points.where((a) => a.isActive).length,
        customersMapped: customersMapped,
        pendingAmount: pendingByAgent.values.fold(0, (a, b) => a + b),
      ),
      agents: points,
    );
  }

  static Future<_TodayStats> _fetchTodayCollectionStats(
      String agentId) async {
    if (agentId.isEmpty) return const _TodayStats(count: 0, amount: 0);
    final rows = await ApiClient.instance
        .list('collections', query: {'agent_id': 'eq.$agentId'});
    final today = DateTime.now();
    bool isToday(dynamic raw) {
      if (raw == null) return false;
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed == null) return false;
      return parsed.year == today.year &&
          parsed.month == today.month &&
          parsed.day == today.day;
    }

    var count = 0;
    var amount = 0.0;
    for (final row in rows) {
      if (!isToday(row['collection_date'] ?? row['created_at'])) continue;
      count++;
      amount += _toDouble(row['collection_amount'] ?? row['amount']);
    }
    return _TodayStats(count: count, amount: amount);
  }
}

class _TodayStats {
  final int count;
  final double amount;
  const _TodayStats({required this.count, required this.amount});
}

bool _isValidLatLng(double? lat, double? lng) {
  if (lat == null || lng == null) return false;
  if (!lat.isFinite || !lng.isFinite) return false;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
  if (lat == 0 && lng == 0) return false;
  return true;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
