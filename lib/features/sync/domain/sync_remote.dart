/// One page of changes from the server, oldest first.
class RemotePage {
  const RemotePage(this.rows);

  /// Rows as the server stores them: snake_case columns, timestamps as ISO
  /// 8601 strings, including `deleted_at`, `updated_at` and
  /// `server_updated_at`.
  final List<Map<String, Object?>> rows;
}

/// The server side of sync. Implemented over Supabase in the app and by an
/// in-memory server in tests.
abstract interface class SyncRemote {
  /// Inserts or updates [rows] of [table]. The server keeps the newer version
  /// when a row is older than the stored one.
  Future<void> upsert(String table, List<Map<String, Object?>> rows);

  /// Marks the records as deleted at [at].
  Future<void> markDeleted(String table, List<String> ids, DateTime at);

  /// Rows changed after [cursor] (a `server_updated_at` returned earlier), or
  /// from the start when null. At most [limit] rows.
  Future<RemotePage> pull(String table, {String? cursor, required int limit});
}

/// Why a sync run did not finish.
class SyncFailure implements Exception {
  const SyncFailure(this.offline);

  /// No connection or the server could not be reached, as opposed to the
  /// server refusing something.
  final bool offline;

  @override
  String toString() => 'SyncFailure(offline: $offline)';
}
