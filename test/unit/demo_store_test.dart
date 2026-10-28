import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/clock.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/demo/demo_models.dart';
import 'package:moneylens/demo/demo_store.dart';
import 'package:moneylens/features/dashboard/application/home_view_providers.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';

import '../support/test_support.dart';

void main() {
  final now = ReportingTimeZone.bangkok.toUtc(2026, 10, 24, 10, 45);

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(FixedClock(now))],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('seed balances match the prototype', () {
    final s = container().read(demoStoreProvider);
    expect(s.balanceOf('kbank'), 1825000);
    expect(s.balanceOf('scb'), 642000);
    expect(s.balanceOf('truemoney'), 0);
    expect(s.balanceOf('cash'), 185000);
  });

  test('month totals exclude transfers and include new entries', () {
    final c = container();
    final before = c.read(monthTotalsProvider);
    expect(before.income, 2840000);
    expect(before.expense, 1235000);

    final store = c.read(demoStoreProvider.notifier);
    TransactionInput input(TransactionType type, int minor) => TransactionInput(
      type: type,
      amount: thb(minor),
      accountId: 'kbank',
      destinationAccountId: type == TransactionType.transfer ? 'cash' : null,
      categoryId: type == TransactionType.transfer ? null : 'food',
      merchant: 'Test',
      occurredAt: now,
    );
    store
      ..addTransaction(input(TransactionType.expense, 5000))
      ..addTransaction(input(TransactionType.transfer, 70000));

    final after = c.read(monthTotalsProvider);
    expect(after.expense, before.expense + 5000);
    expect(after.income, before.income);
    expect(after.transfers, before.transfers + 70000);
    expect(
      after.expenseByCategory['food'],
      before.expenseByCategory['food']! + 5000,
    );
  });

  test('deleting a transaction restores the account balance', () {
    final c = container();
    final store = c.read(demoStoreProvider.notifier);
    final before = c.read(demoStoreProvider).balanceOf('kbank');
    store.deleteTransaction('tx-1'); // Grab ฿80 from KBank
    expect(c.read(demoStoreProvider).balanceOf('kbank'), before + 8000);
  });

  test('simulated OCR moves a capture to needs review', () {
    fakeAsync((async) {
      final c = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(FixedClock(now))],
      );
      final id = c.read(demoStoreProvider.notifier).captureFromCamera();
      async.elapse(const Duration(seconds: 3));
      final s = c.read(demoStoreProvider);
      expect(s.scan(id)!.status, ScanStatus.needsReview);
      expect(s.scanDetails[id]!.reading!.merchant, 'Café Amazon สาขาสามย่าน');
      c.dispose();
    });
  });

  test('retrying a failed read uses its prepared result', () {
    fakeAsync((async) {
      final c = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(FixedClock(now))],
      );
      c.read(demoStoreProvider.notifier).retryFailed('s3');
      expect(
        c.read(demoStoreProvider).scan('s3')!.status,
        ScanStatus.processing,
      );
      async.elapse(const Duration(seconds: 3));
      expect(
        c.read(demoStoreProvider).scan('s3')!.status,
        ScanStatus.needsReview,
      );
      c.dispose();
    });
  });

  test('discarding a duplicate keeps it in the queue as discarded', () {
    final c = container();
    c.read(demoStoreProvider.notifier).discardScan('s2');
    expect(c.read(demoStoreProvider).scan('s2')!.status, ScanStatus.discarded);
    expect(c.read(demoStoreProvider.notifier).pending.map((s) => s.id), ['s1']);
  });

  test('wiping clears transactions, scans and balances', () {
    final c = container();
    c.read(demoStoreProvider.notifier).wipeAll();
    final s = c.read(demoStoreProvider);
    expect(s.transactions, isEmpty);
    expect(s.scans, isEmpty);
    expect(s.totalBalance, 0);
    expect(c.read(monthTotalsProvider).expense, 0);
  });
}
