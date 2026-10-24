import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/dashboard/application/summary_calculator.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';

import '../support/test_support.dart';

void main() {
  const calculator = SummaryCalculator();
  const bkk = ReportingTimeZone.bangkok;
  final october = bkk.month(2026, 10);

  test('transfers never count as income or expense (TX-06)', () {
    final at = bkk.toUtc(2026, 10, 15, 12);
    final summary = calculator.summarize([
      transaction(type: TransactionType.income, minor: 5000000, occurredAt: at),
      transaction(type: TransactionType.expense, minor: 125050, occurredAt: at),
      transaction(
        type: TransactionType.transfer,
        minor: 999999,
        occurredAt: at,
      ),
    ], october);

    expect(summary.income, thb(5000000));
    expect(summary.expense, thb(125050));
    expect(summary.net, thb(5000000 - 125050));
    expect(summary.transferCount, 1);
  });

  test('uses Asia/Bangkok month boundaries, half-open', () {
    // 00:30 on 1 Oct in Bangkok is still 30 Sep in UTC.
    final firstMinuteOfOctober = bkk.toUtc(2026, 10, 1, 0, 30);
    expect(firstMinuteOfOctober, DateTime.utc(2026, 9, 30, 17, 30));
    // Midnight starting 1 Nov in Bangkok belongs to November.
    final startOfNovember = bkk.toUtc(2026, 11, 1);

    final summary = calculator.summarize([
      transaction(
        type: TransactionType.expense,
        minor: 100,
        occurredAt: firstMinuteOfOctober,
      ),
      transaction(
        type: TransactionType.expense,
        minor: 999,
        occurredAt: startOfNovember,
      ),
      transaction(
        type: TransactionType.expense,
        minor: 999,
        occurredAt: october.startUtc.subtract(const Duration(seconds: 1)),
      ),
    ], october);

    expect(summary.expense, thb(100));
  });

  test('an empty period sums to zero', () {
    final summary = calculator.summarize(const [], october);
    expect(summary.income.minor, 0);
    expect(summary.expense.minor, 0);
    expect(summary.net.minor, 0);
  });

  test('monthContaining handles December rollover', () {
    final dec = bkk.monthContaining(
      DateTime.utc(2026, 12, 31, 18),
    ); // 1 Jan BKK
    expect(dec, bkk.month(2027, 1));
  });
}
