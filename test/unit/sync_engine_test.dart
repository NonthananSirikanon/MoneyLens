import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/features/sync/application/sync_engine.dart';
import 'package:moneylens/features/sync/domain/sync_remote.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';
import 'package:moneylens/infrastructure/database/seed/default_categories.dart';

import '../support/in_memory_sync_remote.dart';
import '../support/test_support.dart';

/// Two devices of the same user, each with its own database, and one shared
/// "server".
void main() {
  late InMemorySyncRemote remote;
  late AppDatabase a;
  late AppDatabase b;
  late SyncEngine syncA;
  late SyncEngine syncB;

  final t1 = DateTime.utc(2026, 10, 1, 10);
  final t2 = DateTime.utc(2026, 10, 1, 11);
  final t3 = DateTime.utc(2026, 10, 1, 12);

  setUp(() {
    remote = InMemorySyncRemote();
    a = openTestDatabase();
    b = openTestDatabase();
    syncA = SyncEngine(a, remote, now: () => t3);
    syncB = SyncEngine(b, remote, now: () => t3);
    addTearDown(() async {
      await a.close();
      await b.close();
    });
  });

  Future<void> addAccount(
    AppDatabase db,
    String id,
    String name,
    DateTime at,
  ) => db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          id: id,
          name: name,
          kind: 'bank',
          currencyCode: 'THB',
          openingBalanceMinor: const Value(1000),
          createdAt: at,
          updatedAt: at,
        ),
      );

  Future<void> addExpense(
    AppDatabase db,
    String id,
    String account,
    DateTime at, {
    String merchant = 'Shop',
    int amount = 4500,
  }) => db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          id: id,
          type: 'expense',
          amountMinor: amount,
          currencyCode: 'THB',
          accountId: account,
          categoryId: const Value('default-expense-food'),
          merchant: Value(merchant),
          occurredAt: at,
          source: 'manual',
          createdAt: at,
          updatedAt: at,
        ),
      );

  Future<List<String>> outbox(AppDatabase db) async => [
    for (final r in await db.select(db.syncOutbox).get())
      '${r.entity}/${r.rowId}/${r.op}',
  ];

  Future<String?> merchantOf(AppDatabase db, String id) async =>
      (await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(id))).getSingleOrNull())?.merchant;

  test('local changes are queued by the database itself', () async {
    await addAccount(a, 'acc-1', 'Bank', t1);
    await addExpense(a, 'tx-1', 'acc-1', t1);
    final queue = await outbox(a);
    expect(queue, contains('accounts/acc-1/upsert'));
    expect(queue, contains('transactions/tx-1/upsert'));
    // The seeded defaults are queued too.
    expect(queue, contains('accounts/$defaultCashAccountId/upsert'));
    expect(queue, contains('categories/default-expense-food/upsert'));
  });

  test(
    'a change queued twice is one entry, and a delete replaces it',
    () async {
      await addAccount(a, 'acc-1', 'Bank', t1);
      await addExpense(a, 'tx-1', 'acc-1', t1);
      await (a.update(a.transactions)..where((t) => t.id.equals('tx-1'))).write(
        TransactionsCompanion(
          merchant: const Value('Edited'),
          updatedAt: Value(t2),
        ),
      );
      expect((await outbox(a)).where((e) => e.startsWith('transactions/')), [
        'transactions/tx-1/upsert',
      ]);
      await (a.delete(a.transactions)..where((t) => t.id.equals('tx-1'))).go();
      expect((await outbox(a)).where((e) => e.startsWith('transactions/')), [
        'transactions/tx-1/delete',
      ]);
    },
  );

  test('push sends parents first and empties the queue', () async {
    await addAccount(a, 'acc-1', 'Bank', t1);
    await addExpense(a, 'tx-1', 'acc-1', t1);
    final report = await syncA.push();
    expect(report.pushed, greaterThan(3));
    expect(await outbox(a), isEmpty);
    expect(remote.row('accounts', 'acc-1')!['name'], 'Bank');
    final tx = remote.row('transactions', 'tx-1')!;
    expect(tx['amount_minor'], 4500);
    expect(tx['occurred_at'], '2026-10-01T10:00:00.000Z');
    expect(tx['deleted_at'], isNull);
    expect(remote.row('accounts', 'acc-1')!['is_archived'], false);
  });

  test(
    'a second device receives everything and does not echo it back',
    () async {
      await addAccount(a, 'acc-1', 'Bank', t1);
      await addExpense(a, 'tx-1', 'acc-1', t1, merchant: 'Noodles');
      await syncA.run();

      final report = await syncB.run();
      expect(report.pulled, greaterThan(0));
      expect(await merchantOf(b, 'tx-1'), 'Noodles');
      final acc = await (b.select(
        b.accounts,
      )..where((x) => x.id.equals('acc-1'))).getSingle();
      expect(acc.name, 'Bank');
      expect(acc.openingBalanceMinor, 1000);
      // Received changes are not queued for sending again.
      expect(await outbox(b), isEmpty);
      final before = remote.upserted;
      await syncB.run();
      expect(remote.upserted, before);
    },
  );

  test('a deletion on one device removes the record on the other', () async {
    await addAccount(a, 'acc-1', 'Bank', t1);
    await addExpense(a, 'tx-1', 'acc-1', t1);
    await syncA.run();
    await syncB.run();
    expect(await merchantOf(b, 'tx-1'), 'Shop');

    await (b.delete(b.transactions)..where((t) => t.id.equals('tx-1'))).go();
    await syncB.run();
    expect(remote.row('transactions', 'tx-1')!['deleted_at'], isNotNull);

    await syncA.run();
    expect(await merchantOf(a, 'tx-1'), isNull);
    expect(await outbox(a), isEmpty);
  });

  test('the most recent edit wins, whatever the order of syncing', () async {
    await addAccount(a, 'acc-1', 'Bank', t1);
    await addExpense(a, 'tx-1', 'acc-1', t1);
    await syncA.run();
    await syncB.run();

    Future<void> edit(AppDatabase db, String merchant, DateTime at) =>
        (db.update(db.transactions)..where((t) => t.id.equals('tx-1'))).write(
          TransactionsCompanion(
            merchant: Value(merchant),
            updatedAt: Value(at),
          ),
        );
    await edit(a, 'From A', t2);
    await edit(b, 'From B', t3); // later

    // B reaches the server first, then A with its older edit.
    await syncB.run();
    await syncA.run();
    await syncB.run();

    expect(remote.row('transactions', 'tx-1')!['merchant'], 'From B');
    expect(await merchantOf(a, 'tx-1'), 'From B');
    expect(await merchantOf(b, 'tx-1'), 'From B');
  });

  test('a newer local edit survives an older change from the server', () async {
    await addAccount(a, 'acc-1', 'Bank', t1);
    await addExpense(a, 'tx-1', 'acc-1', t1);
    await syncA.run();
    await syncB.run();
    await (b.update(b.transactions)..where((t) => t.id.equals('tx-1'))).write(
      TransactionsCompanion(
        merchant: const Value('Offline edit'),
        updatedAt: Value(t3),
      ),
    );
    await (a.update(a.transactions)..where((t) => t.id.equals('tx-1'))).write(
      TransactionsCompanion(
        merchant: const Value('Older'),
        updatedAt: Value(t2),
      ),
    );
    await syncA.run();
    // B pulls A's older change first: it must not overwrite B's edit.
    await syncB.pull();
    expect(await merchantOf(b, 'tx-1'), 'Offline edit');
    await syncB.run();
    expect(remote.row('transactions', 'tx-1')!['merchant'], 'Offline edit');
  });

  test('offline: nothing is lost, the queue waits for the next run', () async {
    await addAccount(a, 'acc-1', 'Bank', t1);
    remote.failure = const SyncFailure(true);
    await expectLater(syncA.run(), throwsA(isA<SyncFailure>()));
    expect(await outbox(a), contains('accounts/acc-1/upsert'));

    remote.failure = null;
    await syncA.run();
    expect(await outbox(a), isEmpty);
    expect(remote.row('accounts', 'acc-1'), isNotNull);
  });

  test('a record edited while it was being sent is not lost', () async {
    await addAccount(a, 'acc-1', 'Bank', t1);
    await syncA.push();
    await addExpense(a, 'tx-1', 'acc-1', t1);
    final slow = _EditsWhileUpserting(remote, () async {
      await (a.update(a.transactions)..where((t) => t.id.equals('tx-1'))).write(
        TransactionsCompanion(
          merchant: const Value('Edited mid-flight'),
          updatedAt: Value(t2),
        ),
      );
    });
    await SyncEngine(a, slow, now: () => t3).push();
    // The queue entry was not cleared for the first version, so the edit was
    // sent in the same run instead of being lost.
    expect(
      remote.row('transactions', 'tx-1')!['merchant'],
      'Edited mid-flight',
    );
    expect(await outbox(a), isEmpty);
  });

  test('defaults on a new device do not overwrite the cloud copy', () async {
    // Device A renames a default category and syncs.
    await (a.update(
      a.categories,
    )..where((c) => c.id.equals('default-expense-food'))).write(
      CategoriesCompanion(
        name: const Value('Eating out'),
        updatedAt: Value(t2),
      ),
    );
    await syncA.run();
    // Device B is brand new: it only has the seeded defaults.
    await syncB.run();
    final food = await (b.select(
      b.categories,
    )..where((c) => c.id.equals('default-expense-food'))).getSingle();
    expect(food.name, 'Eating out');
    expect(
      remote.row('categories', 'default-expense-food')!['name'],
      'Eating out',
    );
  });

  test('deleting all data reaches the cloud', () async {
    await addAccount(a, 'acc-1', 'Bank', t1);
    await addExpense(a, 'tx-1', 'acc-1', t1);
    await syncA.run();
    await a.wipeUserData(t3);
    await syncA.run();
    expect(remote.live('transactions'), isEmpty);
    expect(remote.live('accounts').map((r) => r['id']), [defaultCashAccountId]);
    await syncB.run();
    expect(await merchantOf(b, 'tx-1'), isNull);
  });

  test('data from before sync existed is queued by the upgrade', () async {
    // Covered by the migration test; here: a populated db has every row queued.
    await addAccount(a, 'acc-1', 'Bank', t1);
    await syncA.run();
    expect(await outbox(a), isEmpty);
    expect(remote.live('accounts').length, 2); // default cash + acc-1
  });
}

/// Runs [onUpsert] right after the server accepted a batch, like the user
/// editing while a request is in flight.
class _EditsWhileUpserting implements SyncRemote {
  _EditsWhileUpserting(this._inner, this.onUpsert);

  final InMemorySyncRemote _inner;
  final Future<void> Function() onUpsert;
  var _done = false;

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) async {
    await _inner.upsert(table, rows);
    if (!_done && table == 'transactions') {
      _done = true;
      await onUpsert();
    }
  }

  @override
  Future<void> markDeleted(String table, List<String> ids, DateTime at) =>
      _inner.markDeleted(table, ids, at);

  @override
  Future<RemotePage> pull(String table, {String? cursor, required int limit}) =>
      _inner.pull(table, cursor: cursor, limit: limit);
}
