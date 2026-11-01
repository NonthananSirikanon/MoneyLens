import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../accounts/application/account_providers.dart';
import '../../categories/application/category_providers.dart';
import '../../slip_import/application/slip_import_providers.dart';
import '../../slip_import/application/slip_queue.dart';
import '../../transactions/application/transaction_providers.dart';

/// "Delete all data" from Settings -> Data & export: erases the user's rows
/// and slip images, restores the default account and categories, and has
/// reloaded the ledger by the time it returns.
Future<void> wipeAllData(Ref ref) async {
  final db = ref.read(appDatabaseProvider);
  final slips = await db.localSlipPaths();
  await db.wipeUserData(ref.read(clockProvider).nowUtc());
  // The rows are gone; the image files must go too.
  final store = ref.read(slipImageStoreProvider);
  for (final path in slips) {
    try {
      await store.delete(path);
    } on Object {
      // A file that cannot be removed must not fail the wipe.
    }
  }
  await Future.wait([
    reloadTransactions(ref),
    reloadAccounts(ref),
    reloadCategories(ref),
  ]);
  ref.read(slipQueueProvider.notifier).clear();
}

final wipeAllDataProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => wipeAllData(ref),
);
