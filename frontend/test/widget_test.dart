import 'package:flutter_test/flutter_test.dart';

import 'package:fincollect/main.dart';

void main() {
  testWidgets('FinCollect login screen smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FinCollectApp());

    expect(find.text('FinCollect'), findsWidgets);
  });
}
