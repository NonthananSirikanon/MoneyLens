import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:moneylens/app/theme/app_theme.dart';
import 'package:moneylens/core/dates/clock.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/transactions/application/transaction_view_providers.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';
import 'package:moneylens/features/transactions/presentation/transaction_tile.dart';
import 'package:moneylens/l10n/app_localizations.dart';

import '../support/test_support.dart';

void main() {
  // Saturday 7 Nov 2026, 18:30 in Bangkok.
  final now = ReportingTimeZone.bangkok.toUtc(2026, 11, 7, 18, 30);
  final timeText = RegExp(r'\d{2}:\d{2}');

  TransactionView viewAt(DateTime occurredAt) => TransactionView(
    transaction: transaction(
      type: TransactionType.expense,
      minor: 12000,
      occurredAt: occurredAt,
    ),
    category: null,
    categoryTint: null,
    account: null,
    accountDetails: null,
    destination: null,
    destinationDetails: null,
    wallClock: ReportingTimeZone.bangkok.wallClock(occurredAt),
  );

  Future<void> pumpTile(
    WidgetTester tester,
    DateTime occurredAt, {
    required String locale,
    TileTrailing trailing = TileTrailing.time,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clockProvider.overrideWithValue(FixedClock(now))],
        child: MaterialApp(
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: FTheme(data: AppTheme.light, child: child!),
          ),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: TransactionTile(
                view: viewAt(occurredAt),
                onPressed: () {},
                trailing: trailing,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final today = ReportingTimeZone.bangkok.toUtc(2026, 11, 7, 9, 15);
  final yesterday = ReportingTimeZone.bangkok.toUtc(2026, 11, 6, 23, 50);
  final monday = ReportingTimeZone.bangkok.toUtc(2026, 11, 2, 9, 15);

  testWidgets('dashboard variant: today reads วันนี้ with no clock time', (
    tester,
  ) async {
    await pumpTile(
      tester,
      today,
      locale: 'th',
      trailing: TileTrailing.dateWeekday,
    );
    expect(find.text('วันนี้'), findsOneWidget);
    expect(find.textContaining(timeText), findsNothing);
  });

  testWidgets('dashboard variant: today reads Today in English', (
    tester,
  ) async {
    await pumpTile(
      tester,
      today,
      locale: 'en',
      trailing: TileTrailing.dateWeekday,
    );
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('dashboard variant: yesterday', (tester) async {
    await pumpTile(
      tester,
      yesterday,
      locale: 'th',
      trailing: TileTrailing.dateWeekday,
    );
    expect(find.text('เมื่อวาน'), findsOneWidget);
    await pumpTile(
      tester,
      yesterday,
      locale: 'en',
      trailing: TileTrailing.dateWeekday,
    );
    expect(find.text('Yesterday'), findsOneWidget);
  });

  testWidgets('dashboard variant: other day shows weekday and date', (
    tester,
  ) async {
    await pumpTile(
      tester,
      monday,
      locale: 'th',
      trailing: TileTrailing.dateWeekday,
    );
    expect(find.text('จันทร์ 2 พ.ย.'), findsOneWidget);
    expect(find.textContaining(timeText), findsNothing);
    await pumpTile(
      tester,
      monday,
      locale: 'en',
      trailing: TileTrailing.dateWeekday,
    );
    expect(find.text('Mon 2 Nov'), findsOneWidget);
  });

  testWidgets('dashboard variant: semantics carry the date, not the time', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpTile(
      tester,
      monday,
      locale: 'en',
      trailing: TileTrailing.dateWeekday,
    );
    final label = tester.getSemantics(find.byType(TransactionTile)).label;
    expect(label, contains('Mon 2 Nov'));
    expect(label, isNot(contains(timeText)));
    handle.dispose();
  });

  testWidgets('default variant keeps the clock time', (tester) async {
    await pumpTile(tester, monday, locale: 'th');
    expect(find.text('09:15'), findsOneWidget);
    expect(find.text('จันทร์ 2 พ.ย.'), findsNothing);
  });

  testWidgets('no overflow at large text scale', (tester) async {
    await pumpTile(
      tester,
      monday,
      locale: 'th',
      trailing: TileTrailing.dateWeekday,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
