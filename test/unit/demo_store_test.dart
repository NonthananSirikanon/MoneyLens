import 'dart:ui' show Color;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/demo/demo_models.dart';
import 'package:moneylens/demo/demo_store.dart';
import 'package:moneylens/features/accounts/domain/account.dart';
import 'package:moneylens/features/categories/domain/category.dart';
import 'package:moneylens/features/dashboard/application/home_view_providers.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';

import '../support/test_support.dart';

/// The UI store over a real (in-memory) database holding the sample data.
void main() {
  final now = ReportingTimeZone.bangkok.toUtc(2026, 10, 24, 10, 45);

  Future<ProviderContainer> container() => sampleContainer(now);

  TransactionInput input(
    TransactionType type,
    int minor, {
    String account = 'kbank',
  }) => TransactionInput(
    type: type,
    amount: thb(minor),
    accountId: account,
    destinationAccountId: type == TransactionType.transfer
        ? 'default-cash'
        : null,
    categoryId: type == TransactionType.transfer
        ? null
        : type == TransactionType.income
        ? 'default-income-salary'
        : 'default-expense-food',
    merchant: 'Test',
    occurredAt: now,
  );

  test('sample balances match the prototype', () async {
    final s = (await container()).read(demoStoreProvider);
    expect(s.balanceOf('kbank'), 1825000);
    expect(s.balanceOf('scb'), 642000);
    expect(s.balanceOf('truemoney'), 0);
    expect(s.balanceOf('default-cash'), 185000);
    expect(s.totalBalance, 2652000);
  });

  test('month totals come from transactions and exclude transfers', () async {
    final c = await container();
    final before = c.read(monthTotalsProvider);
    expect(before.income, 2500000);
    expect(before.expense, 65400); // 80 + 120 + 45 + 349 + 60 baht
    expect(before.transfers, 300000); // 2,000 + 1,000 baht

    final store = c.read(demoStoreProvider.notifier);
    await store.addTransaction(input(TransactionType.expense, 5000));
    await store.addTransaction(input(TransactionType.transfer, 70000));

    final after = c.read(monthTotalsProvider);
    expect(after.expense, before.expense + 5000);
    expect(after.income, before.income);
    expect(after.transfers, before.transfers + 70000);
    expect(
      after.expenseByCategory['default-expense-food'],
      before.expenseByCategory['default-expense-food']! + 5000,
    );
  });

  test('a saved transaction is visible as soon as the call returns', () async {
    final c = await container();
    final id = await c
        .read(demoStoreProvider.notifier)
        .addTransaction(input(TransactionType.expense, 12300));
    expect(c.read(demoStoreProvider).transaction(id)!.amount, thb(12300));
  });

  test('editing and deleting keep the balance correct', () async {
    final c = await container();
    final store = c.read(demoStoreProvider.notifier);
    final before = c.read(demoStoreProvider).balanceOf('kbank');

    await store.updateTransaction(
      'tx-1',
      input(TransactionType.expense, 10000),
    ); // Grab 80 -> 100 baht
    expect(c.read(demoStoreProvider).balanceOf('kbank'), before - 2000);

    await store.deleteTransaction('tx-1');
    expect(c.read(demoStoreProvider).balanceOf('kbank'), before + 8000);
    expect(c.read(demoStoreProvider).transaction('tx-1'), isNull);
  });

  test('new categories and accounts are saved to the database', () async {
    final c = await container();
    final store = c.read(demoStoreProvider.notifier);
    await store.addCategory(
      name: 'Pets',
      kind: CategoryKind.expense,
      iconKey: 'paw-print',
      accent: const Color(0xFFE09A88),
    );
    await store.addAccount(
      name: 'Krungsri',
      kind: AccountKind.bank,
      last4: '4321',
      openingBalanceMinor: 50000,
    );
    final s = c.read(demoStoreProvider);
    expect(s.categories.any((x) => x.name == 'Pets' && !x.isDefault), isTrue);
    final account = s.accounts.firstWhere((a) => a.name == 'Krungsri');
    expect(account.lastFour, '4321');
    expect(s.balanceOf(account.id), 50000);
    expect(s.accountDetails[account.id]!.mask, '•••• 4321');
  });

  test('wiping removes user data and restores the defaults', () async {
    final c = await container();
    final store = c.read(demoStoreProvider.notifier);
    await store.addCategory(
      name: 'Pets',
      kind: CategoryKind.expense,
      iconKey: 'paw-print',
      accent: const Color(0xFFE09A88),
    );
    await store.wipeAll();

    final s = c.read(demoStoreProvider);
    expect(s.transactions, isEmpty);
    expect(s.scans, isEmpty);
    expect(s.accounts.map((a) => a.id), ['default-cash']);
    expect(s.totalBalance, 0);
    expect(s.categories.every((x) => x.isDefault), isTrue);
    expect(c.read(monthTotalsProvider).expense, 0);
  });

  group('simulated slip queue', () {
    test('a capture is read, then needs review', () async {
      final c = await container();
      final store = c.read(demoStoreProvider.notifier);
      fakeAsync((async) {
        final id = store.captureFromCamera();
        expect(
          c.read(demoStoreProvider).scan(id)!.status,
          ScanStatus.processing,
        );
        async.elapse(const Duration(seconds: 3));
        final s = c.read(demoStoreProvider);
        expect(s.scan(id)!.status, ScanStatus.needsReview);
        expect(s.scanDetails[id]!.reading!.merchant, 'Café Amazon สาขาสามย่าน');
      });
    });

    test('retrying a failed read uses its prepared result', () async {
      final c = await container();
      final store = c.read(demoStoreProvider.notifier);
      fakeAsync((async) {
        store.retryFailed('s3');
        expect(
          c.read(demoStoreProvider).scan('s3')!.status,
          ScanStatus.processing,
        );
        async.elapse(const Duration(seconds: 3));
        expect(
          c.read(demoStoreProvider).scan('s3')!.status,
          ScanStatus.needsReview,
        );
      });
    });

    test('discarding a duplicate leaves one pending slip', () async {
      final c = await container();
      final store = c.read(demoStoreProvider.notifier);
      store.discardScan('s2');
      expect(
        c.read(demoStoreProvider).scan('s2')!.status,
        ScanStatus.discarded,
      );
      expect(store.pending.map((s) => s.id), ['s1']);
    });
  });
}
