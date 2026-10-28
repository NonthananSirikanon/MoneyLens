import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moneylens/app/app.dart';

/// Launches the real app on a device or simulator: real SQLite startup and
/// navigation through onboarding and every tab. Screens use the in-memory
/// demo store (lib/demo); camera and photo pickers are simulated and still
/// need manual device testing.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding leads to Home and every tab renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyLensApp()));
    await tester.pump(const Duration(seconds: 2));

    // Thai is the default locale.
    await tester.tap(find.text('ข้าม'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('อนุญาตและเริ่มใช้งาน'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ยอดคงเหลือรวม'), findsOneWidget);

    for (final tab in ['รายการ', 'วิเคราะห์', 'ตั้งค่า', 'หน้าหลัก']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: tab);
    }
  });
}
