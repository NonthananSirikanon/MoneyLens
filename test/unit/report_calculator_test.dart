import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/date_range.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/analytics/application/report_calculator.dart';
import 'package:moneylens/features/transactions/domain/transaction.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';

import '../support/test_support.dart';

void main() {
  const calc = ReportCalculator();
  final tz = ReportingTimeZone.bangkok;
  final october = tz.month(2026, 10);
  final september = tz.month(2026, 9);

  MoneyTransaction tx(
    TransactionType type,
    int minor,
    DateTime at, {
    String? category,
  }) => MoneyTransaction(
    id: '${type.name}-$minor-${at.millisecondsSinceEpoch}',
    type: type,
    amount: thb(minor),
    accountId: 'a',
    destinationAccountId: type == TransactionType.transfer ? 'b' : null,
    categoryId: category,
    occurredAt: at,
    source: TransactionSource.manual,
    createdAt: at,
    updatedAt: at,
  );

  final data = [
    tx(
      TransactionType.income,
      2500000,
      tz.toUtc(2026, 10, 1),
      category: 'salary',
    ),
    tx(TransactionType.expense, 12000, tz.toUtc(2026, 10, 5), category: 'food'),
    tx(
      TransactionType.expense,
      8000,
      tz.toUtc(2026, 10, 5, 20),
      category: 'food',
    ),
    tx(TransactionType.expense, 5000, tz.toUtc(2026, 10, 7)),
    tx(TransactionType.transfer, 200000, tz.toUtc(2026, 10, 8)),
    tx(
      TransactionType.expense,
      30000,
      tz.toUtc(2026, 9, 30, 23, 59),
      category: 'food',
    ),
  ];

  test('totals exclude transfers and other months', () {
    final t = calc.totals(data, october);
    expect(t.income, 2500000);
    expect(t.expense, 25000);
    expect(t.transfers, 200000);
    expect(t.net, 2475000);
    expect(t.expenseByCategory, {'food': 20000});
    expect(t.incomeByCategory, {'salary': 2500000});
  });

  test('month boundaries are half-open in Bangkok time', () {
    expect(calc.totals(data, september).expense, 30000);
    expect(calc.totals(data, october).expense, 25000);
  });

  test('trend returns one entry per range in order', () {
    final t = calc.trend(data, [september, october]);
    expect(t.map((p) => p.expense), [30000, 25000]);
  });

  test('daily expense buckets by day and ignores income and transfers', () {
    final days = calc.dailyExpense(
      data,
      october,
      dayCount: 31,
      dayOf: (i) => tz.wallClock(i).day - 1,
    );
    expect(days[4], 20000); // 5 Oct, both expenses
    expect(days[6], 5000);
    expect(days.reduce((a, b) => a + b), 25000);
  });

  test('empty period gives zero totals', () {
    final t = calc.totals(
      data,
      DateRange(tz.toUtc(2026, 4, 1), tz.toUtc(2026, 5, 1)),
    );
    expect(t.income + t.expense + t.transfers, 0);
    expect(t.expenseByCategory, isEmpty);
  });
}
