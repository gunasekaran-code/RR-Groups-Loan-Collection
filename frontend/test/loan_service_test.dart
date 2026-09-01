import 'package:flutter_test/flutter_test.dart';
import 'package:fincollect/services/loan_service.dart';

void main() {
  group('LoanService schedule request optimization', () {
    test('builds one batched repayment schedule query for multiple loan ids', () {
      const ids = ['loan-1', 'loan-2', 'loan-3'];
      final query = LoanService.buildRepaymentScheduleQuery(ids);

      expect(query['loan_id'], 'in.(loan-1,loan-2,loan-3)');
      expect(query['limit'], '200');
      expect(query['order'], 'loan_id.asc,installment_no.asc');
    });
  });
}
