import 'dart:io';

import 'package:flutter/material.dart' show TextField;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/app/app.dart';
import 'package:moneylens/app/app_preferences.dart';
import 'package:moneylens/app/providers.dart';
import 'package:moneylens/app/theme/icons.dart';
import 'package:moneylens/core/dates/clock.dart';
import 'package:moneylens/core/errors/app_failure.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/demo/demo_config.dart';
import 'package:moneylens/features/auth/application/local_data_eraser.dart';
import 'package:moneylens/features/slip_import/application/slip_import_providers.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';
import 'package:moneylens/features/export/application/export_service.dart';
import 'package:moneylens/features/auth/application/session.dart';
import 'package:moneylens/features/auth/data/fake_auth_repository.dart';
import 'package:moneylens/features/auth/domain/auth_models.dart';
import 'package:moneylens/features/accounts/application/account_providers.dart';
import 'package:moneylens/features/categories/application/category_providers.dart';
import 'package:moneylens/features/transactions/application/transaction_providers.dart';
import 'package:moneylens/app/app_state.dart';
import 'package:moneylens/app/app_store.dart';
import 'package:moneylens/features/analytics/application/analytics_view_providers.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';

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
    bool sample = true,
    bool signedIn = true,
    FakeAuthRepository? auth,
    RecordingEraser? eraser,
    RecordingSharer? sharer,
    StubOcrService? ocr,
    FakeImageSource? camera,
    FakeImageSource? gallery,
  }) async {
    final authRepo =
        auth ??
        FakeAuthRepository(
          signedIn: signedIn
              ? const AppUser(
                  id: 'u',
                  method: SignInMethod.google,
                  email: 'a@b.co',
                  displayName: 'Somchai',
                )
              : null,
          birthDate: signedIn ? DateTime.utc(1997, 3, 14) : null,
        );
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = openTestDatabase();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sampleDataEnabledProvider.overrideWithValue(sample),
        authRepositoryProvider.overrideWithValue(authRepo),
        localDataEraserProvider.overrideWithValue(eraser ?? RecordingEraser()),
        fileSharerProvider.overrideWithValue(sharer ?? RecordingSharer()),
        // Slip import: no real camera, photo picker, OCR engine or disk.
        imageSourcesProvider.overrideWithValue({
          ImportSource.camera: camera ?? FakeImageSource(ImportSource.camera),
          ImportSource.gallery:
              gallery ?? FakeImageSource(ImportSource.gallery),
        }),
        ocrServiceProvider.overrideWithValue(ocr ?? StubOcrService()),
        slipImageStoreProvider.overrideWithValue(MemorySlipImageStore()),
        // Drift stream queries and writes deadlock under the fake clock of
        // widget tests, so the ledger streams emit one-shot reads instead.
        // The store re-reads after every write, so the UI still updates.
        allTransactionsProvider.overrideWith(
          (ref) => Stream.fromFuture(
            ref.watch(transactionRepositoryProvider).findAll(),
          ),
        ),
        activeAccountsProvider.overrideWith(
          (ref) => Stream.fromFuture(
            ref.watch(accountRepositoryProvider).findActive(),
          ),
        ),
        activeCategoriesProvider.overrideWith(
          (ref) => Stream.fromFuture(
            ref.watch(categoryRepositoryProvider).findActive(),
          ),
        ),
        if (startup != null)
          appStartupProvider.overrideWith((ref) => startup()),
        clockProvider.overrideWithValue(FixedClock(now)),
        appPreferencesProvider.overrideWith(
          () =>
              _Prefs(AppPreferences(onboardingDone: onboarded, locale: locale)),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await tester.runAsync(db.close);
    });
    if (startup == null) {
      // Drift does real I/O, which fake time in widget tests does not drive.
      await tester.runAsync(() => container.read(appStartupProvider.future));
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MoneyLensApp(),
      ),
    );
    await settle(tester);
    return container;
  }

  testWidgets('signing in with Google leads to Home', (tester) async {
    final auth = FakeAuthRepository();
    final container = await pumpApp(
      tester,
      onboarded: false,
      signedIn: false,
      auth: auth,
    );
    expect(find.text('Skip'), findsOneWidget);

    // Skipping onboarding goes to sign-in, never straight into the app.
    await tapOn(tester, find.text('Skip'));
    await settle(tester);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with phone number'), findsNothing);

    await tapOn(tester, find.text('Continue with Google'));
    await settle(tester);

    // Signed in but no birth date yet: the app cannot be entered.
    expect(find.text('Your date of birth'), findsOneWidget);
    await tester.enterText(input('Day'), '31');
    await tapOn(tester, find.text('Choose month'));
    await settle(tester);
    await tapOn(tester, find.text('Feb'));
    await settle(tester);
    await tester.enterText(input('Year (B.E.)'), '2540');
    await settle(tester);
    await tapOn(tester, find.text('Continue'));
    await settle(tester);
    expect(find.text('There is no 31 Feb in 2540'), findsOneWidget);

    await tester.enterText(input('Day'), '14');
    await settle(tester);
    expect(find.text('Age 28'), findsNothing);
    await tapOn(tester, find.text('February'));
    await settle(tester);
    await tapOn(tester, find.text('Mar'));
    await settle(tester);
    expect(find.text('Age 29'), findsOneWidget);
    await tapOn(tester, find.text('Continue'));
    await settle(tester);
    expect(auth.birthDate, DateTime.utc(1997, 3, 14));

    expect(find.text('Let MoneyLens read your slips'), findsOneWidget);
    await tapOn(tester, find.text('Allow and get started'));
    await settle(tester);
    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('฿26,520.00'), findsOneWidget); // sum of seed accounts
    expect(find.text('2 slips waiting for review'), findsOneWidget);
    expect(container.read(sessionProvider).status, SessionStatus.ready);
    await drain(tester);
  });

  testWidgets('a signed-in user starts at Home and can sign out', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    expect(find.text('Total balance'), findsOneWidget);

    await tapOn(tester, find.text('Settings'));
    await settle(tester);
    expect(find.text('Somchai'), findsWidgets);
    await tapOn(tester, find.text('Somchai').first);
    await settle(tester);
    expect(find.text('My account'), findsOneWidget);
    expect(find.text('Signed in with Google'), findsOneWidget);
    expect(find.text('14 Mar 1997'), findsOneWidget);
    expect(find.text('Date of birth'), findsOneWidget);

    await tapOn(tester, find.text('Sign out'));
    await settle(tester);
    expect(find.text('Sign out?'), findsOneWidget);
    await tapOn(tester, find.text('Cancel'));
    await settle(tester);
    expect(container.read(sessionProvider).isSignedIn, isTrue);

    await tapOn(tester, find.text('Sign out'));
    await settle(tester);
    await tapOn(tester, find.text('Sign out').last);
    await settle(tester);
    expect(container.read(sessionProvider).status, SessionStatus.signedOut);
    expect(find.text('Continue with Google'), findsOneWidget);
    // The data on the device is still there.
    expect(container.read(appStoreProvider).transactions, isNotEmpty);
    await drain(tester);
  });

  testWidgets('deleting the account asks twice, then erases everything', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      signedIn: const AppUser(
        id: 'u',
        method: SignInMethod.google,
        email: 'a@b.co',
        displayName: 'Somchai',
      ),
      birthDate: DateTime.utc(1997, 3, 14),
    );
    final eraser = RecordingEraser();
    final container = await pumpApp(tester, auth: auth, eraser: eraser);

    await tapOn(tester, find.text('Settings'));
    await settle(tester);
    await tapOn(tester, find.text('Somchai').first);
    await settle(tester);
    expect(find.text('Delete account'), findsOneWidget);

    // Cancelling at either step changes nothing.
    await tapOn(tester, find.text('Delete account'));
    await settle(tester);
    expect(find.text('Delete this account?'), findsOneWidget);
    await tapOn(tester, find.text('Cancel'));
    await settle(tester);
    await tapOn(tester, find.text('Delete account'));
    await settle(tester);
    await tapOn(tester, find.text('Continue'));
    await settle(tester);
    expect(find.text('Delete permanently'), findsOneWidget);
    await tapOn(tester, find.text('Cancel'));
    await settle(tester);
    expect(auth.accountDeleted, isFalse);
    expect(container.read(sessionProvider).isSignedIn, isTrue);

    // Both confirmed: the account is deleted, then the device is cleared.
    await tapOn(tester, find.text('Delete account'));
    await settle(tester);
    await tapOn(tester, find.text('Continue'));
    await settle(tester);
    await tapOn(tester, find.text('Delete account permanently'));
    await settle(tester);
    expect(auth.accountDeleted, isTrue);
    expect(container.read(sessionProvider).status, SessionStatus.signedOut);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(eraser.erased.single.userId, 'u');
    // The sample slips point at a bundled asset, which is never erased.
    expect(eraser.erased.single.slipPaths, isEmpty);
    await drain(tester);
  });

  testWidgets('CSV export: choose a period, share the file', (tester) async {
    final sharer = RecordingSharer();
    await pumpApp(tester, sharer: sharer);
    await tapOn(tester, find.text('Settings'));
    await settle(tester);
    await tapOn(tester, find.textContaining('Data and export'));
    await settle(tester);
    expect(find.text('This month'), findsOneWidget);
    // The sample ledger has 8 entries in October 2569, more over all time.
    final month = find.textContaining(RegExp(r'^\d+ transactions$'));
    expect(month, findsOneWidget);
    final monthCount = (tester.widget<Text>(month).data ?? '');

    await tapOn(tester, find.text('Period'));
    await settle(tester);
    await tapOn(tester, find.text('All time'));
    await settle(tester);
    expect(find.text('All time'), findsOneWidget);

    await tapOn(tester, find.text('Export CSV'));
    await settle(tester);
    expect(sharer.files.single.name, 'moneylens-all.csv');
    expect(sharer.files.single.mime, 'text/csv');
    final text = String.fromCharCodes(sharer.files.single.bytes);
    expect(sharer.files.single.bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(text, contains('Merchant / payee'));
    expect(
      text.split('\r\n').length - 2,
      greaterThanOrEqualTo(int.parse(monthCount.split(' ').first)),
    );
    expect(find.text('Exported moneylens-all.csv'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('CSV export of an empty period shares nothing', (tester) async {
    final sharer = RecordingSharer();
    await pumpApp(tester, sample: false, sharer: sharer);
    await tapOn(tester, find.text('Settings'));
    await settle(tester);
    await tapOn(tester, find.textContaining('Data and export'));
    await settle(tester);
    await tapOn(tester, find.text('Export CSV'));
    await settle(tester);
    expect(sharer.files, isEmpty);
    expect(find.text('No transactions in this period'), findsOneWidget);
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
    final before = container.read(appStoreProvider).balanceOf('kbank');

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
      container.read(appStoreProvider).balanceOf('kbank'),
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

    expect(container.read(appStoreProvider).transaction('tx-1'), isNull);
    expect(find.text('Transaction deleted'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('analytics: pick a month and year, empty period, reset', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    await tapOn(tester, find.text('Analytics'));
    await settle(tester);
    expect(find.text('Total expenses'), findsOneWidget);

    // The pill opens a month and year picker instead of cycling.
    await tapOn(tester, find.text('Oct 2026'));
    await settle(tester);
    expect(find.text('Choose month and year'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    // Nothing before the oldest transaction's year, nothing after today.
    await tapOn(tester, find.byIcon(MlIcons.chevronLeft));
    await settle(tester);
    expect(find.text('2026'), findsOneWidget);
    // A future month cannot be chosen: the tap does nothing.
    await tester.tap(find.text('Nov'), warnIfMissed: false);
    await settle(tester);
    expect(find.text('Choose month and year'), findsOneWidget);

    await tapOn(tester, find.text('Sep'));
    await settle(tester);
    expect(find.text('Sep 2026'), findsOneWidget);
    expect(find.text('No data for this period'), findsOneWidget);

    await tapOn(tester, find.text('Change period'));
    await settle(tester);
    expect(find.text('Oct 2026'), findsOneWidget);
    expect(find.text('Total expenses'), findsOneWidget);
    expect(container.read(analyticsProvider).periodIndex, 0);

    // The whole year is one choice, and it is marked in the picker.
    await tapOn(tester, find.text('Oct 2026'));
    await settle(tester);
    await tapOn(tester, find.text('Whole year'));
    await settle(tester);
    expect(find.text('All of 2026'), findsOneWidget);
    expect(find.text('Total expenses'), findsOneWidget);
    expect(container.read(analyticsProvider).wholeYear, 2026);
    // Picking a month leaves the whole-year view.
    await tapOn(tester, find.text('All of 2026'));
    await settle(tester);
    await tapOn(tester, find.text('Oct'));
    await settle(tester);
    expect(find.text('Oct 2026'), findsOneWidget);
    expect(container.read(analyticsProvider).wholeYear, isNull);
  });

  testWidgets('analytics: the picker can go back to an earlier year', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    // An expense in Dec 2025 makes 2025 available.
    await container
        .read(appStoreProvider.notifier)
        .addTransaction(
          TransactionInput(
            type: TransactionType.expense,
            amount: thb(55500),
            accountId: 'kbank',
            categoryId: 'default-expense-food',
            merchant: 'Old shop',
            occurredAt: ReportingTimeZone.bangkok.toUtc(2025, 12, 5, 12),
          ),
        );
    await tapOn(tester, find.text('Analytics'));
    await settle(tester);
    await tapOn(tester, find.text('Oct 2026'));
    await settle(tester);
    await tapOn(tester, find.byIcon(MlIcons.chevronLeft));
    await settle(tester);
    expect(find.text('2025'), findsOneWidget);
    await tapOn(tester, find.text('Dec'));
    await settle(tester);
    expect(find.text('Dec 2025'), findsOneWidget);
    expect(find.text('฿555'), findsWidgets);
    expect(container.read(analyticsProvider).periodIndex, 10);

    // The whole of 2025 holds just that expense; 2026 holds the sample data.
    await tapOn(tester, find.text('Dec 2025'));
    await settle(tester);
    await tapOn(tester, find.text('Whole year'));
    await settle(tester);
    expect(find.text('All of 2025'), findsOneWidget);
    expect(find.text('฿555'), findsWidgets);
    await tapOn(tester, find.text('All of 2025'));
    await settle(tester);
    await tapOn(tester, find.byIcon(MlIcons.chevronRight));
    await settle(tester);
    await tapOn(tester, find.text('Whole year'));
    await settle(tester);
    expect(find.text('All of 2026'), findsOneWidget);
    expect(find.text('฿555'), findsNothing);
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
    expect(container.read(appStoreProvider).accounts.length, 5);
    await drain(tester);
  });

  testWidgets('a fresh install is empty and records a first transaction', (
    tester,
  ) async {
    final container = await pumpApp(tester, sample: false);
    expect(find.text('Total balance'), findsOneWidget);
    expect(find.textContaining('slips waiting'), findsNothing);
    expect(container.read(appStoreProvider).transactions, isEmpty);
    expect(container.read(appStoreProvider).scans, isEmpty);

    // Scanning opens the system camera; cancelling it leaves everything as is.
    await tapOn(tester, find.text('Scan slip'));
    await settle(tester);
    expect(container.read(appStoreProvider).scans, isEmpty);
    expect(find.text('Total balance'), findsOneWidget);

    await tapOn(tester, find.text('Add manually').first);
    await settle(tester);
    await tester.enterText(input('Amount'), '150');
    await tester.enterText(input('Merchant / payee'), 'Noodle shop');
    await tapOn(tester, find.text('Save transaction'));
    await settle(tester);

    expect(find.text('Saved'), findsOneWidget);
    final s = container.read(appStoreProvider);
    expect(s.transactions.single.accountId, 'default-cash');
    expect(s.balanceOf('default-cash'), -15000);
  });

  testWidgets('scanning a real slip: read, review, save', (tester) async {
    final slipText = File('test/fixtures/slips/kbank_transfer.txt')
        .readAsStringSync();
    final camera = FakeImageSource(ImportSource.camera, bytes: fakeJpeg(3));
    final container = await pumpApp(
      tester,
      sample: false,
      camera: camera,
      ocr: StubOcrService(text: slipText),
    );

    await tapOn(tester, find.text('Scan slip'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(camera.calls, 1);

    // The read finishes and the review form opens with what was found.
    expect(find.text('Review transaction'), findsOneWidget);
    final filled = find
        .byType(TextField)
        .evaluate()
        .map((e) => (e.widget as TextField).controller?.text)
        .toList();
    expect(filled, containsAll(['1250.50', 'นาย สมชาย ทดสอบ']));
    expect(
      container.read(appStoreProvider).scans.single.status,
      ScanStatus.needsReview,
    );

    // The category is the user's to pick; saving without it is refused.
    await tapOn(tester, find.text('Confirm and save'));
    await settle(tester);
    expect(container.read(appStoreProvider).transactions, isEmpty);
    await tapOn(tester, find.text('Choose a category'));
    await settle(tester);
    await tapOn(tester, find.text('อาหารและเครื่องดื่ม'));
    await settle(tester);
    await tapOn(tester, find.text('Confirm and save'));
    await settle(tester);

    expect(find.text('Saved'), findsOneWidget);
    final s = container.read(appStoreProvider);
    expect(s.transactions.single.amount, thb(125050));
    expect(s.transactions.single.scanRecordId, s.scans.single.id);
    expect(s.scans.single.status, ScanStatus.confirmed);
    expect(s.balanceOf('default-cash'), -125050);
    await drain(tester);
  });

  testWidgets('a slip that cannot be read says why', (tester) async {
    await pumpApp(
      tester,
      sample: false,
      gallery: FakeImageSource(ImportSource.gallery, bytes: fakeJpeg(4)),
      ocr: StubOcrService(failWith: FailureCode.unreadableImage),
    );
    await tapOn(tester, find.text('Scan slip'));
    await settle(tester);
    // The camera is empty (cancelled); use the photo picker from the add sheet.
    await tapOn(tester, find.byIcon(MlIcons.plus));
    await settle(tester);
    await tapOn(tester, find.text('Choose from Photos'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text("The details couldn't be read"), findsOneWidget);
    expect(find.text('The image could not be read.'), findsOneWidget);
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
  for (var i = 0; i < 40; i++) {
    // Let pending database work finish in real time, then advance the clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump(const Duration(milliseconds: 16));
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
