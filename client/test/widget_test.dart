import 'package:flutter_test/flutter_test.dart';
import 'package:client/main.dart';

void main() {
  testWidgets('App renders Home Screen smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Final Project Mobile'), findsOneWidget);
    expect(find.text('Mobile App & Backend Ready'), findsOneWidget);
  });
}
