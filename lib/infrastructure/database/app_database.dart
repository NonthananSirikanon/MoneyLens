import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.steps.dart';
import 'seed/default_categories.dart';
import 'tables/accounts.dart';
import 'tables/categories.dart';
import 'tables/scan_records.dart';
import 'tables/transactions.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Accounts, Categories, Transactions, ScanRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database in the app's private storage.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'moneylens'));

  /// Bump on every schema change, add a step in `migrations/`, and dump the
  /// new schema (see README "Database migrations").
  @override
  int get schemaVersion => 2;

  /// Deletes everything the user entered: transactions, slip records,
  /// accounts and custom categories. Default categories and the default
  /// cash account are restored afterwards. Runs in one transaction.
  Future<void> wipeUserData(DateTime nowUtc) => transaction(() async {
    await delete(transactions).go();
    await delete(scanRecords).go();
    await delete(accounts).go();
    await (delete(categories)..where((c) => c.isDefault.equals(false))).go();
    await (update(categories)..where((c) => c.isDefault.equals(true))).write(
      const CategoriesCompanion(isArchived: Value(false)),
    );
    await seedDefaults(this, nowUtc);
  });

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDefaults(this, DateTime.now().toUtc());
    },
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.addColumn(schema.accounts, schema.accounts.lastFour);
        // New default categories and the default cash account (idempotent).
        await seedDefaults(this, DateTime.now().toUtc());
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
