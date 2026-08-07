import '../models/loan_record.dart';
import '../models/customer.dart';
import '../models/agent.dart';
import 'api_client.dart';

/// Loan-specific data access. Resolves `customer_id` / `agent_id` into
/// display names client-side after fetching, since the generic rest.php
/// endpoint returns raw rows without joins.
class LoanService {
  LoanService._();
  static final LoanService instance = LoanService._();

  final ApiClient _api = ApiClient.instance;

  Future<List<Customer>> fetchCustomers() async {
    final rows = await _api.list('customers');
    return rows.map(Customer.fromJson).toList();
  }

  /// ASSUMPTION: agents are `profiles` rows with role == 'agent'. Adjust the
  /// table/query if agents are stored differently in your schema.
  Future<List<Agent>> fetchAgents() async {
    final rows = await _api.list('profiles', query: {'role': 'agent'});
    return rows.map(Agent.fromJson).toList();
  }

  Future<List<LoanRecord>> fetchLoans({
    List<Customer> customers = const [],
    List<Agent> agents = const [],
  }) async {
    final rows = await _api.list('loans');
    final customerById = {for (final c in customers) c.id: c.name};
    final agentById = {for (final a in agents) a.id: a.name};

    return rows.map((row) {
      final loan = LoanRecord.fromJson(row);
      if (loan.customerId != null &&
          customerById.containsKey(loan.customerId) &&
          (loan.customerName.isEmpty || loan.customerName == 'Unknown')) {
        loan.customerName = customerById[loan.customerId]!;
      }
      if (loan.agentId != null &&
          agentById.containsKey(loan.agentId) &&
          (loan.agentName.isEmpty || loan.agentName == 'Unassigned')) {
        loan.agentName = agentById[loan.agentId]!;
      }
      return loan;
    }).toList();
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
    final row = await _api.update('loans', id, {
      'status': 'Closed',
      'outstanding_balance': 0,
    });
    return LoanRecord.fromJson(row);
  }

  Future<void> deleteLoan(String id) async {
    await _api.delete('loans', id);
  }
}
