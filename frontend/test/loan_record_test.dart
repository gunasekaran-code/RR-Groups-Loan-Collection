import 'package:flutter_test/flutter_test.dart';
import 'package:fincollect/models/loan_record.dart';

void main() {
  group('LoanRecord.fromJson', () {
    test('uses backend customer and agent names when provided', () {
      final loan = LoanRecord.fromJson({
        'id': 'loan-1',
        'loan_number': 'LN-100001',
        'customer_id': null,
        'customer_name': 'Ramesh Iyer',
        'assigned_agent': 'agent-1',
        'agent_name': 'Arjun Mehta',
        'principal_amount': 50000,
        'interest_rate': 10,
        'duration_months': 10,
        'collection_type': 'monthly',
        'start_date': '2026-05-14',
        'outstanding_balance': 44000,
        'emi_amount': 5500,
        'processing_fee': 500,
        'status': 'active',
      });

      expect(loan.customerName, 'Ramesh Iyer');
      expect(loan.agentName, 'Arjun Mehta');
      expect(loan.agentId, 'agent-1');
    });
  });
}
