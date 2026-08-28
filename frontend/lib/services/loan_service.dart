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
    final customerById = <String, Customer>{};
    for (final customer in customers) {
      customerById[customer.id] = customer;
      if (customer.customerId.isNotEmpty) {
        customerById[customer.customerId] = customer;
      }
    }
    final agentById = {for (final agent in agents) agent.id: agent};

    return rows.map((row) {
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
  }

  Future<List<RepaymentInstallment>> fetchRepaymentSchedule(String loanId) async {
    final rows = await _api.list('repayment_schedule', query: {'loan_id': loanId});
    final schedule = rows.map(RepaymentInstallment.fromJson).toList();
    schedule.sort((a, b) => a.installmentNo.compareTo(b.installmentNo));
    return schedule;
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
