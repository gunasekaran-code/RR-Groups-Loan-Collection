import '../models/loan_record.dart';
import '../models/customer.dart';
import '../models/agent.dart';
import '../models/repayment_installment.dart';
import 'api_client.dart';

/// Loan-specific data access. Resolves `customer_id` / `agent_id` into
/// display names client-side after fetching, since the generic rest.php
/// endpoint returns raw rows without joins.
class LoanService {
  LoanService._();
  static final LoanService instance = LoanService._();

  final ApiClient _api = ApiClient.instance;

  static final Map<String, List<Customer>> _customersCache = {};
  static final Map<String, List<Agent>> _agentsCache = {};
  static final Map<String, List<LoanRecord>> _loansCache = {};
  static final Map<String, Map<String, List<RepaymentInstallment>>> _scheduleCache = {};

  static Map<String, String> buildRepaymentScheduleQuery(
    List<String> loanIds, {
    int limit = 200,
    String order = 'loan_id.asc,installment_no.asc',
  }) {
    final ids = loanIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    return {
      if (ids.isNotEmpty) 'loan_id': 'in.(${ids.join(',')})',
      if (ids.isNotEmpty) 'limit': limit.toString(),
      if (ids.isNotEmpty) 'order': order,
    };
  }

  Future<List<Customer>> fetchCustomers() async {
    if (_customersCache.containsKey('all')) {
      return List.unmodifiable(_customersCache['all']!);
    }
    final rows = await _api.list('customers');
    final customers = rows.map(Customer.fromJson).toList();
    _customersCache['all'] = customers;
    return List.unmodifiable(customers);
  }

  /// ASSUMPTION: agents are `profiles` rows with role == 'agent'. Adjust the
  /// table/query if agents are stored differently in your schema.
  Future<List<Agent>> fetchAgents() async {
    if (_agentsCache.containsKey('all')) {
      return List.unmodifiable(_agentsCache['all']!);
    }
    final rows = await _api.list('profiles', query: {'role': 'agent'});
    final agents = rows.map(Agent.fromJson).toList();
    _agentsCache['all'] = agents;
    return List.unmodifiable(agents);
  }

  Future<List<LoanRecord>> fetchLoans({
    List<Customer> customers = const [],
    List<Agent> agents = const [],
  }) async {
    final cacheKey = '${customers.length}_${agents.length}';
    if (_loansCache.containsKey(cacheKey)) {
      return List.unmodifiable(_loansCache[cacheKey]!);
    }
    final rows = await _api.list('loans');
    final customerById = <String, Customer>{};
    for (final customer in customers) {
      customerById[customer.id] = customer;
      if (customer.customerId.isNotEmpty) {
        customerById[customer.customerId] = customer;
      }
    }
    final agentById = {for (final agent in agents) agent.id: agent};

    final loans = rows.map((row) {
      final loan = LoanRecord.fromJson(row);
      final customer = loan.customerId == null
          ? null
          : customerById[loan.customerId!];
      if (customer != null &&
          (loan.customerName.isEmpty || loan.customerName == 'Unknown')) {
        loan.customerName = customer.name;
      }
      if (loan.agentId != null &&
          agentById.containsKey(loan.agentId) &&
          (loan.agentName.isEmpty || loan.agentName == 'Unassigned')) {
        loan.agentName = agentById[loan.agentId!]!.name;
      }
      if ((loan.agentId == null || loan.agentId!.isEmpty) &&
          (loan.agentName.isEmpty || loan.agentName == 'Unassigned') &&
          customer?.assignedAgent != null) {
        loan.agentName = customer!.assignedAgentName ??
            agentById[customer.assignedAgent!]?.name ?? 'Unassigned';
      }
      return loan;
    }).toList();
    _loansCache[cacheKey] = loans;
    return List.unmodifiable(loans);
  }

  Future<Map<String, List<RepaymentInstallment>>> fetchRepaymentSchedulesForLoans(
    List<String> loanIds,
  ) async {
    final ids = loanIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};

    final cacheKey = ids.join(',');
    if (_scheduleCache.containsKey(cacheKey)) {
      final cached = _scheduleCache[cacheKey]!;
      return <String, List<RepaymentInstallment>>{
        for (final entry in cached.entries)
          entry.key: List.unmodifiable(entry.value),
      };
    }

    final rows = await _api.list(
      'repayment_schedule',
      query: buildRepaymentScheduleQuery(ids),
    );
    final grouped = <String, List<RepaymentInstallment>>{};
    for (final row in rows) {
      final loanId = (row['loan_id'] ?? '').toString();
      if (loanId.isEmpty) continue;
      grouped.putIfAbsent(loanId, () => <RepaymentInstallment>[]);
      grouped[loanId]!.add(RepaymentInstallment.fromJson(row));
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.installmentNo.compareTo(b.installmentNo));
    }
    _scheduleCache[cacheKey] = grouped;
    return <String, List<RepaymentInstallment>>{
      for (final entry in grouped.entries)
        entry.key: List.unmodifiable(entry.value),
    };
  }

  Future<List<RepaymentInstallment>> fetchRepaymentSchedule(String loanId) async {
    final grouped = await fetchRepaymentSchedulesForLoans([loanId]);
    return grouped[loanId] ?? const <RepaymentInstallment>[];
  }

  Future<LoanRecord> createLoan(Map<String, dynamic> data) async {
    final row = await _api.create('loans', data);
    return LoanRecord.fromJson(row);
  }

  Future<LoanRecord> updateLoan(String id, Map<String, dynamic> data) async {
    final row = await _api.update('loans', id, data);
    return LoanRecord.fromJson(row);
  }

  Future<LoanRecord> closeLoan(String id) async {
    // Only the status is sent — LoanController's afterWrite() runs
    // LoanRecalc on every PATCH regardless, which recomputes
    // outstanding_balance from the real collections/schedule and would
    // silently reopen the loan if any balance were actually still pending.
    final row = await _api.update('loans', id, {
      'status': 'closed',
    });
    return LoanRecord.fromJson(row);
  }

  Future<void> deleteLoan(String id) async {
    await _api.delete('loans', id);
  }
}
