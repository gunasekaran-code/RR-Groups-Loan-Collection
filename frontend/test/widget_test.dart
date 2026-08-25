import 'package:flutter_test/flutter_test.dart';

import 'package:fincollect/main.dart';

void main() {
  testWidgets('RR Groups login screen smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FinCollectApp());

    expect(find.text('RR Groups'), findsWidgets);
  });
}
