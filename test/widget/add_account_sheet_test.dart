import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:moneylens/app/theme/app_theme.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/accounts/domain/account.dart';
import 'package:moneylens/features/accounts/presentation/accounts_screen.dart';
import 'package:moneylens/features/ledger/application/ledger.dart';
import 'package:moneylens/l10n/app_localizations.dart';

import '../support/test_support.dart';

void main() {
  final now = ReportingTimeZone.bangkok.toUtc(2026, 10, 24, 10, 45);
  const last4Label = 'Last 4 digits (optional)';
  const last4Hint = 'Only the last 4 digits are kept, to help match slips';

  Future<ProviderContainer> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = (await tester.runAsync(() => sampleContainer(now)))!;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.material(),
          locale: const Locale('en'),
          supportedLocales: const [Locale('th'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            FLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => FTheme(
            data: AppTheme.light,
            child: FToaster(child: child!),
          ),
          home: const AccountsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.ensureVisible(find.text('Add account'));
    await tester.pump();
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> pickKind(WidgetTester tester, String label) async {
    // Segments sit in the sheet, which is the last route; the accounts list
    // behind it can also contain the same words.
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  /// The editable text inside the field whose semantics label is [label].
  Finder input(String label) => find
      .descendant(
        of: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == label,
        ),
        matching: find.byType(EditableText),
      )
      .first;

  Finder last4Field() => find.text(last4Label);

  void expectLast4(bool shown) {
    expect(last4Field(), shown ? findsWidgets : findsNothing);
    expect(find.text(last4Hint), shown ? findsOneWidget : findsNothing);
  }

  testWidgets('bank and e-wallet show the last-4 field, cash hides it', (
    tester,
  ) async {
    await openSheet(tester);
    expectLast4(true); // bank is the default

    await pickKind(tester, 'e-Wallet');
    expectLast4(true);

    await pickKind(tester, 'Cash');
    expectLast4(false);
    expect(tester.takeException(), isNull);

    await pickKind(tester, 'Bank');
    expectLast4(true);
  });

  testWidgets('digits typed before switching to cash are not saved', (
    tester,
  ) async {
    final container = await openSheet(tester);
    await tester.enterText(input(last4Label), '1234');
    await tester.enterText(input('Account name'), 'Wallet at home');
    await pickKind(tester, 'Cash');
    await tester.tap(find.text('Save account'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(seconds: 5));

    final saved = container
        .read(ledgerProvider)
        .accounts
        .firstWhere((a) => a.name == 'Wallet at home');
    expect(saved.kind, AccountKind.cash);
    expect(saved.lastFour, isNull);
  });
}
