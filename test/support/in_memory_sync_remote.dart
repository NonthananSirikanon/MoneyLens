import 'package:moneylens/features/sync/domain/sync_remote.dart';

/// A stand-in for the Supabase tables with the same rules as the real ones:
/// every write gets a new `server_updated_at`, and a write whose
/// `updated_at` is older than the stored row's is ignored.
class InMemorySyncRemote implements SyncRemote {
  final tables = <String, Map<String, Map<String, Object?>>>{};
  var _clock = 0;

  /// When set, every call throws it (to test being offline).
  SyncFailure? failure;

  /// Number of rows received by [upsert], for assertions.
  var upserted = 0;

  String _stamp() =>
      DateTime.utc(2030)
          .add(Duration(microseconds: ++_clock))
          .toIso8601String();

  Map<String, Map<String, Object?>> _table(String name) =>
      tables.putIfAbsent(name, () => {});

  /// Live (not deleted) rows of [table].
  List<Map<String, Object?>> live(String table) => [
    for (final r in _table(table).values)
      if (r['deleted_at'] == null) r,
  ];

  Map<String, Object?>? row(String table, String id) => _table(table)[id];

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) async {
    if (failure != null) throw failure!;
    for (final r in rows) {
      upserted++;
      final id = r['id']! as String;
      final old = _table(table)[id];
      if (old != null &&
          DateTime.parse(r['updated_at']! as String)
              .isBefore(DateTime.parse(old['updated_at']! as String))) {
        continue;
      }
      _table(table)[id] = {...r, 'server_updated_at': _stamp()};
    }
  }

  @override
  Future<void> markDeleted(String table, List<String> ids, DateTime at) async {
    if (failure != null) throw failure!;
    for (final id in ids) {
      final old = _table(table)[id];
      if (old == null) continue;
      if (at.isBefore(DateTime.parse(old['updated_at']! as String))) continue;
      _table(table)[id] = {
        ...old,
        'deleted_at': at.toUtc().toIso8601String(),
        'updated_at': at.toUtc().toIso8601String(),
        'server_updated_at': _stamp(),
      };
    }
  }

  @override
  Future<RemotePage> pull(
    String table, {
    String? cursor,
    required int limit,
  }) async {
    if (failure != null) throw failure!;
    final after = cursor == null ? null : DateTime.parse(cursor);
    final rows =
        _table(table).values.where((r) {
          final s = DateTime.parse(r['server_updated_at']! as String);
          return after == null || s.isAfter(after);
        }).toList()..sort(
          (a, b) =>
              DateTime.parse(a['server_updated_at']! as String)
                  .compareTo(DateTime.parse(b['server_updated_at']! as String)),
        );
    return RemotePage(rows.take(limit).toList());
  }
}
