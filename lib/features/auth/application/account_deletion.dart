import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/database/app_database.dart';
import 'local_data_eraser.dart';
import 'session.dart';

/// Deletes the signed-in account: first on the server, then on this device.
///
/// A separate object rather than a method of `SessionController`, because
/// the database provider depends on the session (one database file per
/// user); the session itself must not read it back.
class AccountDeletion {
  const AccountDeletion(this._ref);

  final Ref _ref;

  /// Throws [AuthFailure] (for example `network`) without touching anything
  /// when the server cannot be reached.
  Future<void> run() async {
    final user = _ref.read(sessionProvider).user;
    if (user == null) return;
    // Read before the account goes: the paths live in this user's database.
    final db = _ref.read(appDatabaseProvider);
    final slips = await db.localSlipPaths();

    // Also ends the session; the session controller follows the auth stream
    // and the database provider swaps to the signed-out one.
    await _ref.read(authRepositoryProvider).deleteAccount();

    try {
      await db.close(); // the provider closes it too; closing twice is safe
    } on Object {
      // Already closed.
    }
    await _ref
        .read(localDataEraserProvider)
        .erase(userId: user.id, slipPaths: slips);
  }
}

final accountDeletionProvider = Provider<AccountDeletion>(AccountDeletion.new);
