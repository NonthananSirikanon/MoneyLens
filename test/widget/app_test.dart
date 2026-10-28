import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/app/app.dart';
import 'package:moneylens/app/app_preferences.dart';
import 'package:moneylens/app/providers.dart';
import 'package:moneylens/app/theme/icons.dart';
import 'package:moneylens/core/dates/clock.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/demo/demo_store.dart';

import '../support/test_support.dart';

/// Starts with onboarding finished and a fixed locale.
class _Prefs extends AppPreferencesController {
  _Prefs(this.initial);

  final AppPreferences initial;

  @override
  AppPreferences build() => initial;
}

void main() {
  // The prototype's "today": 24 Oct 2569 (2026), 10:45 Bangkok.
  final now = ReportingTimeZone.bangkok.toUtc(2026, 10, 24, 10, 45);

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    bool onboarded = true,
    Locale locale = const Locale('en'),
    Future<void> Function()? startup,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        appStartupProvider.overrideWith((ref) => (startup ?? () async {})()),
        clockProvider.overrideWithValue(FixedClock(now)),
        appPreferencesProvider.overrideWith(
          () =>
              _Prefs(AppPreferences(onboardingDone: onboarded, locale: locale)),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MoneyLensApp(),
      ),
    );
    await settle(tester);
    return container;
  }

  testWidgets('onboarding leads through permissions to Home', (tester) async {
    await pumpApp(tester, onboarded: false);
    expect(find.text('Skip'), findsOneWidget);

    await tapOn(tester, find.text('Skip'));
    await settle(tester);
    expect(find.text('Let MoneyLens read your slips'), findsOneWidget);

    await tapOn(tester, find.text('Allow and get started'));
    await settle(tester);
    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('฿26,520.00'), findsOneWidget); // sum of seed accounts
    expect(find.text('2 slips waiting for review'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('the eye button hides balances', (tester) async {
    await pumpApp(tester);
    await tapOn(tester, find.byIcon(MlIcons.eye));
    await settle(tester);
    expect(find.text('฿26,520.00'), findsNothing);
    expect(find.text('฿ ••••••'), findsOneWidget);
  });

  testWidgets('manual entry validates, then saves', (tester) async {
    final container = await pumpApp(tester);
    final before = container.read(demoStoreProvider).balanceOf('kbank');

    await tapOn(tester, find.text('Add manually').first);
    await settle(tester);
    expect(find.text('Add transaction'), findsOneWidget);

    await tapOn(tester, find.text('Save transaction'));
    await settle(tester);
    expect(find.text('Enter an amount greater than 0'), findsWidgets);

    await tester.enterText(input('Amount'), '1,20.00');
    await tapOn(tester, find.text('Save transaction'));
    await settle(tester);
    expect(find.text('Invalid amount format, e.g. 120.00'), findsWidgets);

    await tester.enterText(input('Amount'), '150');
    await tester.enterText(input('Merchant / payee'), 'Noodle shop');
    await tapOn(tester, find.text('Save transaction'));
    await settle(tester);

    expect(find.text('Saved'), findsOneWidget);
    expect(
      container.read(demoStoreProvider).balanceOf('kbank'),
      before - 15000,
    );
  });

  testWidgets('queue review of the misread slip, then next pending', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapOn(tester, find.text('2 slips waiting for review'));
    await settle(tester);
    expect(find.text('Imported slips · 7'), findsOneWidget);
    for (final status in [
      'Needs review',
      'Possible duplicate',
      "Couldn't read",
      'Waiting',
      'Saved',
      'Discarded',
    ]) {
      expect(find.text(status), findsWidgets, reason: status);
    }

    await tapOn(tester, find.text('Review'));
    await settle(tester);
    expect(find.text('Check 2 highlighted fields'), findsOneWidget);
    expect(find.text("OCR isn't sure — please check"), findsOneWidget);

    await tapOn(tester, find.text('Confirm and save'));
    await settle(tester);
    expect(find.text('Invalid amount format, e.g. 120.00'), findsWidgets);

    await tester.enterText(input('Amount'), '120.00');
    await tapOn(tester, find.text('Choose a category'));
    await settle(tester);
    await tapOn(tester, find.text('อาหารและเครื่องดื่ม').last);
    await settle(tester);
    await tapOn(tester, find.text('Confirm and save'));
    await settle(tester);

    expect(find.text('Saved'), findsOneWidget);
    await tapOn(tester, find.text('Review next slip (1)'));
    await settle(tester);
    expect(find.text('A very similar transaction exists'), findsOneWidget);

    await tapOn(tester, find.text('Discard this slip (duplicate)'));
    await settle(tester);
    expect(find.text('Duplicate slip discarded'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('transactions: search, transfer filter and empty search', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapOn(tester, find.text('Transactions').last);
    await tester.pump(); // builds the tab, which starts the 700ms load
    await tester.pump(const Duration(milliseconds: 800)); // skeleton
    await settle(tester);
    expect(find.text('Grab'), findsOneWidget);

    await tapOn(tester, find.text('Transfer'));
    await settle(tester);
    expect(
      find.text("Transfers aren't counted as income or expenses"),
      findsOneWidget,
    );
    expect(find.text('Grab'), findsNothing);
    expect(find.text('โอนเข้ากระเป๋า'), findsOneWidget);

    await tapOn(tester, find.text('All'));
    await tester.enterText(input('Search merchants, notes…'), 'latte');
    await settle(tester);
    expect(find.textContaining('Starbucks'), findsOneWidget);

    await tester.enterText(input('Search merchants, notes…'), 'zzz');
    await settle(tester);
    expect(find.text('No matching transactions'), findsOneWidget);
  });

  testWidgets('detail delete asks for confirmation', (tester) async {
    final container = await pumpApp(tester);
    await tapOn(tester, find.text('Grab'));
    await settle(tester);
    expect(find.text('-฿80.00'), findsWidgets);

    await tapOn(tester, find.text('Delete'));
    await settle(tester);
    expect(find.text('Delete this transaction?'), findsOneWidget);
    await tapOn(tester, find.text('Delete permanently'));
    await settle(tester);

    expect(container.read(demoStoreProvider).transaction('tx-1'), isNull);
    expect(find.text('Transaction deleted'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('analytics cycles to an empty period', (tester) async {
    await pumpApp(tester);
    await tapOn(tester, find.text('Analytics'));
    await settle(tester);
    expect(find.text('Total expenses'), findsOneWidget);

    await tapOn(tester, find.text('Oct 2026'));
    await settle(tester);
    await tapOn(tester, find.text('Sep 2026'));
    await settle(tester);
    expect(find.text('No data for this period'), findsOneWidget);

    await tapOn(tester, find.text('Change period'));
    await settle(tester);
    expect(find.text('Total expenses'), findsOneWidget);
  });

  testWidgets('settings language row switches to Thai', (tester) async {
    await pumpApp(tester);
    await tapOn(tester, find.text('Settings'));
    await settle(tester);
    await tapOn(tester, find.text('Language'));
    await settle(tester);
    expect(find.text('ตั้งค่า'), findsWidgets);
    expect(find.text('ภาษา'), findsOneWidget);
  });

  testWidgets('add category and account from settings', (tester) async {
    final container = await pumpApp(tester);
    await tapOn(tester, find.text('Settings'));
    await settle(tester);

    await tapOn(tester, find.text('Categories'));
    await settle(tester);
    await tapOn(tester, find.text('Add category'));
    await settle(tester);
    await tester.enterText(input('Category name'), 'Pets');
    await settle(tester);
    await tapOn(tester, find.text('Save category'));
    await settle(tester);
    expect(find.text('Pets'), findsOneWidget);
    await drain(tester); // the toast sits over the back button
    await tapOn(tester, find.byIcon(MlIcons.arrowLeft));
    await settle(tester);

    await tapOn(tester, find.text('Accounts'));
    await settle(tester);
    await tapOn(tester, find.text('Add account'));
    await settle(tester);
    await tester.enterText(input('Account name'), 'Krungsri');
    await tester.enterText(input('Last 4 digits (optional)'), '12ab345');
    await settle(tester);
    expect(find.text('1234'), findsOneWidget); // digits only, max 4
    await tapOn(tester, find.text('Save account'));
    await settle(tester);
    expect(container.read(demoStoreProvider).accounts.length, 5);
    await drain(tester);
  });

  testWidgets('startup failure shows a retryable error', (tester) async {
    await pumpApp(tester, startup: () async => throw StateError('db'));
    expect(
      find.text('MoneyLens could not open its local data.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}

/// Pumps frames without waiting for settle; some views animate forever
/// (skeleton shimmer, camera scan line).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// The editable text inside the [MlInput] labelled [label].
Finder input(String label) => find
    .descendant(
      of: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == label,
      ),
      matching: find.byType(EditableText),
    )
    .first;

/// Scrolls [finder] into view (the test font is wider than Noto Sans Thai,
/// so content wraps more), then taps it.
Future<void> tapOn(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    // Lazily built lists: scroll the front-most vertical list until found.
    final vertical = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(finder, 120, scrollable: vertical.last);
  }
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first);
}

/// Lets toast and loader timers finish before the test ends.
/// Several frames are needed: a toast's dismiss timer only starts once its
/// entrance animation has finished.
Future<void> drain(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}
