import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDefaultCategories(this, DateTime.now().toUtc());
    },
    onUpgrade: (m, from, to) async {
      // No released schema predates v1. Failing loudly here is safer
      // than silently recreating tables and losing user data.
      throw UnsupportedError('No migration path from schema $from to $to');
    },
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
