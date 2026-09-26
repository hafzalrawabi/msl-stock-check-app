import 'package:flutter_test/flutter_test.dart';
import 'package:msl_stock_check_app/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MSLStockCheckApp());
    await tester.pumpAndSettle();

    // Verify that login screen UI loads.
    expect(find.text('MSL Stock Check'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}


