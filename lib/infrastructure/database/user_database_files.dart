import 'dart:io';

import 'package:path/path.dart' as p;

/// Where each user's database file lives.
///
/// Every account gets its own SQLite file (`moneylens_<user id>.sqlite`), so
/// someone signing in on the same device never sees another account's data.
///
/// Before accounts existed the app used one shared `moneylens.sqlite`. The
/// first account that signs in after the update takes that file over
/// ([resolve]); other accounts start empty. This is the only moment data
/// moves between accounts, and it happens once.
abstract final class UserDatabaseFiles {
  static const legacyName = 'moneylens';

  /// A user id as a safe file-name part (ids are UUIDs, but never trust
  /// that when building a path).
  static String fileSafe(String userId) =>
      userId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  static File userFile(Directory dir, String userId) =>
      File(p.join(dir.path, 'moneylens_${fileSafe(userId)}.sqlite'));

  static File legacyFile(Directory dir) =>
      File(p.join(dir.path, '$legacyName.sqlite'));

  /// The file for [userId] in [dir], first moving the shared legacy
  /// database (and its `-wal`/`-shm` side files) into place when this user
  /// has no file yet.
  static Future<File> resolve(Directory dir, String userId) async {
    final target = userFile(dir, userId);
    final legacy = legacyFile(dir);
    if (!await target.exists() && await legacy.exists()) {
      // Side files first, the main file last: if this is interrupted, the
      // legacy main file still exists and the move is attempted again.
      for (final suffix in ['-wal', '-shm', '-journal']) {
        final side = File('${legacy.path}$suffix');
        if (await side.exists()) await side.rename('${target.path}$suffix');
      }
      await legacy.rename(target.path);
    }
    return target;
  }

  /// Deletes [userId]'s database file and its side files, if they exist.
  /// Other accounts' files are never touched.
  static Future<void> deleteFor(Directory dir, String userId) async {
    final main = userFile(dir, userId);
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final file = File('${main.path}$suffix');
      if (await file.exists()) await file.delete();
    }
  }
}
