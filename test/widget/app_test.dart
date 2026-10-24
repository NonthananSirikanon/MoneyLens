import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/app/app.dart';
import 'package:moneylens/app/providers.dart';
import 'package:moneylens/core/dates/clock.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/slip_import/application/slip_import_providers.dart';
import 'package:moneylens/features/slip_import/domain/scan_record.dart';
import 'package:moneylens/features/transactions/application/transaction_providers.dart';
import 'package:moneylens/features/transactions/domain/transaction.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';

import '../support/test_support.dart';

void main() {
  final now = ReportingTimeZone.bangkok.toUtc(2026, 10, 14, 12);

  Widget app({
    List<MoneyTransaction> transactions = const [],
    Future<void> Function()? startup,
  }) => ProviderScope(
    retry: (_, _) => null,
    overrides: [
      appStartupProvider.overrideWith((ref) => (startup ?? () async {})()),
      clockProvider.overrideWithValue(FixedClock(now)),
      transactionRepositoryProvider.overrideWithValue(
        FakeTransactionRepository(transactions),
      ),
      visibleScansProvider.overrideWith(
        (ref) => Stream.value(const <ScanRecord>[]),
      ),
    ],
    child: const MoneyLensApp(),
  );

  testWidgets('shows empty states and navigates between tabs', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('฿0.00'), findsNWidgets(3));

    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    expect(find.text('No transactions yet'), findsOneWidget);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(find.text('Import a slip'), findsOneWidget);
    expect(find.text('No imported slips'), findsOneWidget);
    expect(
      find.text(
        'Imported slips are always shown for review before anything is saved.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('dashboard excludes transfers from totals', (tester) async {
    await tester.pumpWidget(
      app(
        transactions: [
          transaction(
            id: '1',
            type: TransactionType.income,
            minor: 1000000,
            occurredAt: now,
          ),
          transaction(
            id: '2',
            type: TransactionType.expense,
            minor: 25050,
            occurredAt: now,
          ),
          transaction(
            id: '3',
            type: TransactionType.transfer,
            minor: 500000,
            occurredAt: now,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('฿10,000.00'), findsOneWidget); // income
    expect(find.text('฿250.50'), findsOneWidget); // expense
    expect(find.text('฿9,749.50'), findsOneWidget); // net
    expect(find.text('1 transfer (not counted)'), findsOneWidget);
  });

  testWidgets('startup failure shows a retryable error', (tester) async {
    await tester.pumpWidget(app(startup: () async => throw StateError('db')));
    await tester.pumpAndSettle();

    expect(
      find.text('MoneyLens could not open its local data.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}
