import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/auth/application/session.dart';

import 'app_database.steps.dart';
import 'seed/default_categories.dart';
import 'tables/accounts.dart';
import 'tables/categories.dart';
import 'tables/scan_records.dart';
import 'tables/transactions.dart';
import 'user_database_files.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Accounts, Categories, Transactions, ScanRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The signed-in user's database in the app's private storage. Each user
  /// has their own file (see [UserDatabaseFiles]).
  factory AppDatabase.openFor(String userId) => AppDatabase(
    driftDatabase(
      name: 'moneylens',
      native: DriftNativeOptions(
        databasePath: () async => (await UserDatabaseFiles.resolve(
          await getApplicationDocumentsDirectory(),
          userId,
        )).path,
      ),
    ),
  );

  /// A throwaway database for while nobody is signed in. It holds nothing
  /// and is never written to disk.
  factory AppDatabase.signedOut() => AppDatabase(NativeDatabase.memory());

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

/// The database of whoever is signed in. It is replaced (and the old one
/// closed) when the user changes, which rebuilds everything that reads it,
/// so one account's data is never shown to another.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final userId = ref.watch(sessionProvider.select((s) => s.user?.id));
  final db = userId == null
      ? AppDatabase.signedOut()
      : AppDatabase.openFor(userId);
  ref.onDispose(db.close);
  return db;
});
