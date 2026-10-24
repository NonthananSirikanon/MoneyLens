import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moneylens/app/app.dart';

/// Launches the real app on a device or simulator: real SQLite database,
/// real startup recovery, real navigation. Camera and photo pickers are not
/// exercised; they need manual device testing (ROADMAP week 1).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app opens its database and every tab renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyLensApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);

    for (final destination
        in find.byType(NavigationDestination).evaluate().toList()) {
      await tester.tap(find.byWidget(destination.widget));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorWidget), findsNothing);
    }
  });
}
