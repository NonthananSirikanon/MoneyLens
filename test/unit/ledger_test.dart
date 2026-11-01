import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/accounts/domain/account.dart';
import 'package:moneylens/features/categories/domain/category.dart';
import 'package:moneylens/features/accounts/application/account_actions.dart';
import 'package:moneylens/features/categories/application/category_actions.dart';
import 'package:moneylens/features/dashboard/application/home_view_providers.dart';
import 'package:moneylens/features/ledger/application/ledger.dart';
import 'package:moneylens/features/settings/application/wipe_all_data.dart';
import 'package:moneylens/features/slip_import/application/slip_queue.dart';
import 'package:moneylens/features/transactions/application/transaction_actions.dart';
import 'package:moneylens/features/transactions/application/transaction_input.dart';
import 'package:moneylens/features/transactions/application/transaction_providers.dart';
import 'package:moneylens/features/transactions/domain/transaction.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';

import '../support/test_support.dart';

/// The ledger (read through the stream providers, written through the
/// action providers) over a real in-memory database holding the sample data.
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
    final s = (await container()).read(ledgerProvider);
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

    final actions = c.read(transactionActionsProvider);
    await actions.add(input(TransactionType.expense, 5000));
    await actions.add(input(TransactionType.transfer, 70000));

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
        .read(transactionActionsProvider)
        .add(input(TransactionType.expense, 12300));
    expect(c.read(ledgerProvider).transaction(id)!.amount, thb(12300));
  });

  test('editing and deleting keep the balance correct', () async {
    final c = await container();
    final actions = c.read(transactionActionsProvider);
    final before = c.read(ledgerProvider).balanceOf('kbank');

    await actions.update(
      'tx-1',
      input(TransactionType.expense, 10000),
    ); // Grab 80 -> 100 baht
    expect(c.read(ledgerProvider).balanceOf('kbank'), before - 2000);

    await actions.delete('tx-1');
    expect(c.read(ledgerProvider).balanceOf('kbank'), before + 8000);
    expect(c.read(ledgerProvider).transaction('tx-1'), isNull);
  });

  test('new categories and accounts are saved to the database', () async {
    final c = await container();
    await c
        .read(categoryActionsProvider)
        .add(
          name: 'Pets',
          kind: CategoryKind.expense,
          iconKey: 'paw-print',
          accent: const Color(0xFFE09A88),
        );
    await c
        .read(accountActionsProvider)
        .add(
          name: 'Krungsri',
          kind: AccountKind.bank,
          last4: '4321',
          openingBalanceMinor: 50000,
        );
    final s = c.read(ledgerProvider);
    expect(s.categories.any((x) => x.name == 'Pets' && !x.isDefault), isTrue);
    final account = s.accounts.firstWhere((a) => a.name == 'Krungsri');
    expect(account.lastFour, '4321');
    expect(s.balanceOf(account.id), 50000);
    expect(s.accountDetails[account.id]!.mask, '•••• 4321');
  });

  test('wiping removes user data and restores the defaults', () async {
    final c = await container();
    await c
        .read(categoryActionsProvider)
        .add(
          name: 'Pets',
          kind: CategoryKind.expense,
          iconKey: 'paw-print',
          accent: const Color(0xFFE09A88),
        );
    await c.read(wipeAllDataProvider)();

    final s = c.read(ledgerProvider);
    expect(s.transactions, isEmpty);
    expect(c.read(slipQueueProvider).scans, isEmpty);
    expect(s.accounts.map((a) => a.id), ['default-cash']);
    expect(s.totalBalance, 0);
    expect(s.categories.every((x) => x.isDefault), isTrue);
    expect(c.read(monthTotalsProvider).expense, 0);
  });

  group('reloading after a write', () {
    // A provider that hands out its own Ref, so a test can call the same
    // reload helper the action classes use.
    final refProvider = Provider<Ref>((ref) => ref);

    MoneyTransaction tx(String id) => MoneyTransaction(
      id: id,
      type: TransactionType.expense,
      amount: thb(100),
      accountId: 'a',
      occurredAt: now,
      source: TransactionSource.manual,
      createdAt: now,
      updatedAt: now,
    );

    test('a slower, older read never overwrites a newer one', () async {
      // Each (re)subscription reads the transactions once; the test decides
      // when each read finishes.
      final reads = <Completer<List<MoneyTransaction>>>[];
      final c = ProviderContainer(
        overrides: [
          allTransactionsProvider.overrideWith((ref) {
            final read = Completer<List<MoneyTransaction>>();
            reads.add(read);
            return Stream.fromFuture(read.future);
          }),
        ],
      );
      addTearDown(c.dispose);
      final sub = c.listen(ledgerProvider, (_, _) {});
      addTearDown(sub.close);
      reads[0].complete(const []);
      await c.read(allTransactionsProvider.future);

      final ref = c.read(refProvider);
      final older = reloadTransactions(ref); // read #1: slow
      final newer = reloadTransactions(ref); // read #2: fast
      expect(reads, hasLength(3));

      reads[2].complete([tx('newer')]);
      await newer;
      expect(c.read(ledgerProvider).transactions.map((t) => t.id), ['newer']);

      // The older read finishes last and is ignored.
      reads[1].complete([tx('older')]);
      await older;
      await pumpEventQueue();
      expect(c.read(ledgerProvider).transactions.map((t) => t.id), ['newer']);
    });

    test(
      'a write is visible when it returns, even if the stream lags',
      () async {
        // The stream never emits on its own after the first read, as in widget
        // tests; only the reload after the write can show the new row.
        final saved = <MoneyTransaction>[];
        final c = ProviderContainer(
          overrides: [
            allTransactionsProvider.overrideWith(
              (ref) => Stream.fromFuture(Future.value([...saved])),
            ),
          ],
        );
        addTearDown(c.dispose);
        final sub = c.listen(ledgerProvider, (_, _) {});
        addTearDown(sub.close);
        await c.read(allTransactionsProvider.future);
        expect(c.read(ledgerProvider).transactions, isEmpty);

        saved.add(tx('written'));
        await reloadTransactions(c.read(refProvider));
        expect(c.read(ledgerProvider).transactions.map((t) => t.id), [
          'written',
        ]);
      },
    );
  });
}
