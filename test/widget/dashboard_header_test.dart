import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';
import 'package:moneylens/app/router.dart';
import 'package:moneylens/app/theme/app_theme.dart';
import 'package:moneylens/features/accounts/application/account_providers.dart';
import 'package:moneylens/features/categories/application/category_providers.dart';
import 'package:moneylens/features/transactions/application/transaction_providers.dart';
import 'package:moneylens/app/theme/icons.dart';
import 'package:moneylens/core/dates/clock.dart';
import 'package:moneylens/core/widgets/ml_button.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/dashboard/presentation/dashboard_screen.dart';
import 'package:moneylens/l10n/app_localizations.dart';

import '../support/test_support.dart';

void main() {
  Future<void> pumpHome(
    WidgetTester tester,
    DateTime instant, {
    String locale = 'th',
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = openTestDatabase();
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // Drift streams deadlock under widget-test fake time.
          allTransactionsProvider.overrideWith((ref) => Stream.value([])),
          activeAccountsProvider.overrideWith((ref) => Stream.value([])),
          activeCategoriesProvider.overrideWith((ref) => Stream.value([])),
          clockProvider.overrideWithValue(FixedClock(instant)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.material(),
          locale: Locale(locale),
          supportedLocales: const [Locale('th'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            FLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) =>
              FTheme(data: AppTheme.light, child: child!),
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
              GoRoute(
                path: AppRoutes.analytics,
                builder: (_, _) => const Text('analytics-route'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  DateTime bkk(int h, int m, {int day = 7}) =>
      ReportingTimeZone.bangkok.toUtc(2026, 11, day, h, m);

  final bands = [
    // (hour, minute, thai, english, icon)
    (4, 59, 'สวัสดีตอนค่ำ', 'Good night', MlIcons.moon),
    (5, 0, 'สวัสดีตอนเช้า', 'Good morning', MlIcons.sunrise),
    (11, 59, 'สวัสดีตอนเช้า', 'Good morning', MlIcons.sunrise),
    (12, 0, 'สวัสดีตอนบ่าย', 'Good afternoon', MlIcons.sun),
    (16, 59, 'สวัสดีตอนบ่าย', 'Good afternoon', MlIcons.sun),
    (17, 0, 'สวัสดีตอนเย็น', 'Good evening', MlIcons.sunset),
    (19, 59, 'สวัสดีตอนเย็น', 'Good evening', MlIcons.sunset),
    (20, 0, 'สวัสดีตอนค่ำ', 'Good night', MlIcons.moon),
    // 00:30 Bangkok is 17:30 UTC the previous day.
    (0, 30, 'สวัสดีตอนค่ำ', 'Good night', MlIcons.moon),
  ];

  for (final (h, m, th, en, icon) in bands) {
    final stamp =
        '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}';
    for (final (locale, text) in [('th', th), ('en', en)]) {
      testWidgets('greeting at $stamp Bangkok ($locale)', (tester) async {
        await pumpHome(tester, bkk(h, m), locale: locale);
        expect(find.text(text), findsOneWidget);
        expect(find.byIcon(icon), findsOneWidget);
      });
    }
  }

  testWidgets('00:30 Bangkok is the previous day in UTC', (tester) async {
    final instant = bkk(0, 30, day: 8);
    expect(instant, DateTime.utc(2026, 11, 7, 17, 30));
    await pumpHome(tester, instant);
    expect(find.text('สวัสดีตอนค่ำ'), findsOneWidget);
    expect(find.byIcon(MlIcons.moon), findsOneWidget);
  });

  testWidgets('greeting moves to the next band when the hour rolls over', (
    tester,
  ) async {
    final clock = FixedClock(bkk(11, 59));
    await pumpHome(tester, clock.now, locale: 'en');
    expect(find.text('Good morning'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DashboardScreen)),
    );
    // The provider override holds its own clock; advance the real source.
    (container.read(clockProvider) as FixedClock).now = bkk(12, 0);
    await tester.pump(const Duration(minutes: 2));
    expect(find.text('Good afternoon'), findsOneWidget);
  });

  testWidgets('header has the name on the right and no calendar button', (
    tester,
  ) async {
    await pumpHome(tester, bkk(9, 0));
    expect(find.byType(MlIconButton), findsNothing);
    expect(find.byIcon(MlIcons.calendar), findsNothing);
    // The month stays visible above the income and expense figures.
    expect(find.text('พ.ย. 2569'), findsWidgets);

    final greeting = tester.getRect(find.text('สวัสดีตอนเช้า'));
    final icon = tester.getRect(find.byIcon(MlIcons.sunrise));
    final name = tester.getRect(find.text('คุณ'));
    // Greeting, then its icon, then the name pushed to the right edge.
    expect(icon.left, greaterThan(greeting.right));
    expect(name.left, greaterThan(icon.right));
    // Flush with the 20px page margin on the right.
    expect(name.right, closeTo(390 - 20, 1));
  });
}
