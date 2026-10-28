import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moneylens/app/app.dart';

/// Launches the real app on a device or simulator: real SQLite startup and
/// navigation through sign-in and every tab. Sign-in uses the in-memory fake
/// because no Supabase key is passed; the real Supabase and Google flows
/// need manual testing. Camera and photo pickers are simulated.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign in, then every tab renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyLensApp()));
    await tester.pump(const Duration(seconds: 2));

    // Thai is the default locale. Onboarding leads to sign-in.
    await tester.tap(find.text('ข้าม'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('ลงทะเบียน'));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField).at(0), 'somchai');
    await tester.enterText(find.byType(TextField).at(1), 'password1');
    await tester.enterText(find.byType(TextField).at(2), 'password1');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('ลงทะเบียน').last);
    await tester.pump(const Duration(seconds: 1));

    // Birth date, then permissions.
    await tester.enterText(find.byType(TextField).at(0), '14');
    await tester.enterText(find.byType(TextField).at(1), '2540');
    await tester.tap(find.text('เลือกเดือน').first);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('มี.ค.'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('ดำเนินการต่อ'));
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
