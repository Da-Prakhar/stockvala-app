import 'package:flutter_test/flutter_test.dart';
import 'package:stockvala/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StockValaApp());
    expect(find.byType(StockValaApp), findsOneWidget);
  });
}
