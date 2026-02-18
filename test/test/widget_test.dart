import 'package:flutter_test/flutter_test.dart';

import 'package:test_demos/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TestDemosApp());
    expect(find.text('Shader Wrap'), findsOneWidget);
    expect(find.text('Dynamic Preview'), findsOneWidget);
  });
}
