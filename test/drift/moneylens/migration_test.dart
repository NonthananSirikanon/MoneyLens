// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // v1 -> v2 adds accounts.last_four and seeds the new defaults. Existing
  // user data must survive untouched.
  test(
    'migration from v1 to v2 keeps user data and adds the defaults',
    () async {
      const t = 1760000000; // seconds since epoch, as stored by drift
      final oldAccounts = [
        const v1.AccountsData(
          id: 'acc-1',
          name: 'My bank',
          kind: 'bank',
          currencyCode: 'THB',
          openingBalanceMinor: 12345,
          isArchived: 0,
          createdAt: t,
          updatedAt: t,
        ),
      ];
      final oldCategories = [
        const v1.CategoriesData(
          id: 'default-expense-food',
          name: 'Food (renamed by the user)',
          kind: 'expense',
          iconKey: 'food',
          isDefault: 1,
          isArchived: 0,
          createdAt: t,
          updatedAt: t,
        ),
      ];
      final oldTransactions = [
        const v1.TransactionsData(
          id: 'tx-1',
          type: 'expense',
          amountMinor: 4500,
          currencyCode: 'THB',
          accountId: 'acc-1',
          categoryId: 'default-expense-food',
          merchant: 'Shop',
          occurredAt: t,
          source: 'manual',
          createdAt: t,
          updatedAt: t,
        ),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        createOld: v1.DatabaseAtV1.new,
        createNew: v2.DatabaseAtV2.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.accounts, oldAccounts);
          batch.insertAll(oldDb.categories, oldCategories);
          batch.insertAll(oldDb.transactions, oldTransactions);
        },
        validateItems: (newDb) async {
          final accounts = await newDb.select(newDb.accounts).get();
          final mine = accounts.singleWhere((a) => a.id == 'acc-1');
          expect(mine.name, 'My bank');
          expect(mine.openingBalanceMinor, 12345);
          expect(mine.lastFour, isNull);
          // The default cash account is added.
          expect(accounts.map((a) => a.id), contains('default-cash'));

          final categories = await newDb.select(newDb.categories).get();
          // A renamed default is left alone; missing defaults are added.
          expect(
            categories.singleWhere((c) => c.id == 'default-expense-food').name,
            'Food (renamed by the user)',
          );
          expect(
            categories.map((c) => c.id),
            containsAll(['default-income-freelance', 'default-income-gift']),
          );

          final txs = await newDb.select(newDb.transactions).get();
          expect(txs.single.id, 'tx-1');
          expect(txs.single.amountMinor, 4500);
        },
      );
    },
  );

  // v2 -> v3 adds the sync outbox. Data written before sync existed has to be
  // uploaded once, so every existing row must end up queued.
  test('migration from v2 to v3 queues existing data for sync', () async {
    const t = 1760000000;
    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.accounts,
          const v2.AccountsData(
            id: 'acc-1',
            name: 'My bank',
            kind: 'bank',
            currencyCode: 'THB',
            isArchived: 0,
            createdAt: t,
            updatedAt: t,
          ),
        );
        batch.insert(
          oldDb.transactions,
          const v2.TransactionsData(
            id: 'tx-1',
            type: 'expense',
            amountMinor: 4500,
            currencyCode: 'THB',
            accountId: 'acc-1',
            merchant: 'Shop',
            occurredAt: t,
            source: 'manual',
            createdAt: t,
            updatedAt: t,
          ),
        );
      },
      validateItems: (newDb) async {
        final queued = [
          for (final r in await newDb.select(newDb.syncOutbox).get())
            '${r.entity}/${r.rowId}/${r.op}',
        ];
        expect(queued, contains('accounts/acc-1/upsert'));
        expect(queued, contains('transactions/tx-1/upsert'));
        // From now on changes are queued by the triggers.
        await newDb.customStatement(
          "UPDATE accounts SET name = 'Renamed' WHERE id = 'acc-1'",
        );
        final seqs = {
          for (final r in await newDb.select(newDb.syncOutbox).get())
            '${r.entity}/${r.rowId}': r.seq,
        };
        expect(seqs['accounts/acc-1'], greaterThan(seqs['transactions/tx-1']!));
      },
    );
  });
}
