
import 'package:flutter_test/flutter_test.dart';

import 'package:spendly/main.dart';

void main() {
  testWidgets('App starts test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SpendlyApp());

    // Verify that our app has the Spendly title.
    expect(find.text('Spendly'), findsWidgets);
  });
}
