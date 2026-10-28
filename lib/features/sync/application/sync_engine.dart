import 'package:drift/drift.dart';

import '../../../infrastructure/database/app_database.dart';
import '../domain/sync_remote.dart';
import 'sync_tables.dart';

/// What one sync run did.
class SyncReport {
  const SyncReport({this.pushed = 0, this.pulled = 0, this.skipped = 0});

  /// Records sent to the server (changes and deletions).
  final int pushed;

  /// Records received and applied.
  final int pulled;

  /// Received records that could not be applied (for example a transaction
  /// whose account is missing). They are counted, not retried.
  final int skipped;

  SyncReport operator +(SyncReport o) => SyncReport(
    pushed: pushed + o.pushed,
    pulled: pulled + o.pulled,
    skipped: skipped + o.skipped,
  );
}

/// Pushes the local outbox to the server and applies what changed there.
/// See SYNC.md. Does not decide when to run; [SyncController] does.
class SyncEngine {
  SyncEngine(
    this._db,
    this._remote, {
    DateTime Function()? now,
    this.batchSize = 100,
    this.pageSize = 500,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final SyncRemote _remote;
  final DateTime Function() _now;
  final int batchSize;
  final int pageSize;

  Future<SyncReport> run() async {
    final pushed = await push();
    final pulled = await pull();
    return pushed + pulled;
  }

  // ---------------------------------------------------------------- push

  /// Sends everything in the outbox. Changes go parents first (accounts,
  /// categories, transactions), deletions children first.
  Future<SyncReport> push() async {
    var sent = 0;
    for (final table in syncTables) {
      sent += await _pushChanges(table);
    }
    for (final table in syncTables.reversed) {
      sent += await _pushDeletes(table);
    }
    return SyncReport(pushed: sent);
  }

  Future<int> _pushChanges(SyncTable table) async {
    var sent = 0;
    while (true) {
      final queued = await _queued(table, 'upsert');
      if (queued.isEmpty) return sent;
      final ids = queued.keys.toList();
      final marks = List.filled(ids.length, '?').join(',');
      final columns = table.columns.map((c) => c.name).join(', ');
      final rows = await _db
          .customSelect(
            'SELECT $columns FROM ${table.name} WHERE id IN ($marks)',
            variables: [for (final id in ids) Variable.withString(id)],
          )
          .get();
      final payload = [
        for (final r in rows) {..._toRemote(table, r.data), 'deleted_at': null},
      ];
      if (payload.isNotEmpty) await _remote.upsert(table.name, payload);
      await _clear(table, queued);
      sent += payload.length;
    }
  }

  Future<int> _pushDeletes(SyncTable table) async {
    var sent = 0;
    while (true) {
      final queued = await _queued(table, 'delete');
      if (queued.isEmpty) return sent;
      await _remote.markDeleted(table.name, queued.keys.toList(), _now());
      await _clear(table, queued);
      sent += queued.length;
    }
  }

  /// `row id -> seq` of the next batch of queued records of [table].
  Future<Map<String, int>> _queued(SyncTable table, String op) async {
    final rows = await _db
        .customSelect(
          'SELECT row_id, seq FROM sync_outbox '
          'WHERE entity = ? AND op = ? ORDER BY seq LIMIT ?',
          variables: [
            Variable.withString(table.name),
            Variable.withString(op),
            Variable.withInt(batchSize),
          ],
        )
        .get();
    return {for (final r in rows) r.read<String>('row_id'): r.read<int>('seq')};
  }

  /// Takes records off the queue, unless they changed again since they were
  /// read (their `seq` moved); those stay for the next round.
  Future<void> _clear(SyncTable table, Map<String, int> sent) async {
    await _db.transaction(() async {
      for (final e in sent.entries) {
        await _db.customStatement(
          'DELETE FROM sync_outbox WHERE entity = ? AND row_id = ? AND seq = ?',
          [table.name, e.key, e.value],
        );
      }
    });
    // Raw statements do not tell Drift's watchers that the queue changed.
    _db.notifyUpdates({const TableUpdate('sync_outbox')});
  }

  // ---------------------------------------------------------------- pull

  /// Applies every change made on the server since the last pull.
  Future<SyncReport> pull() async {
    var applied = 0;
    var skipped = 0;
    for (final table in syncTables) {
      var cursor = await _meta('cursor:${table.name}');
      while (true) {
        final page = await _remote.pull(
          table.name,
          cursor: cursor,
          limit: pageSize,
        );
        if (page.rows.isEmpty) break;
        final next = page.rows.last['server_updated_at'] as String;
        final result = await _apply(table, page.rows, next);
        applied += result.applied;
        skipped += result.skipped;
        cursor = next;
        if (page.rows.length < pageSize) break;
      }
    }
    return SyncReport(pulled: applied, skipped: skipped);
  }

  /// Writes one page and its cursor together. The `applying` flag keeps the
  /// outbox triggers quiet, so received changes are not sent back.
  Future<({int applied, int skipped})> _apply(
    SyncTable table,
    List<Map<String, Object?>> rows,
    String nextCursor,
  ) async {
    var applied = 0;
    var skipped = 0;
    await _db.transaction(() async {
      await _setMeta('applying', '1');
      for (final row in rows) {
        try {
          await _applyRow(table, row);
          applied++;
        } on Object catch (e) {
          if (!_isConstraintFailure(e)) rethrow;
          skipped++;
        }
      }
      await _setMeta('applying', '0');
      await _setMeta('cursor:${table.name}', nextCursor);
    });
    return (applied: applied, skipped: skipped);
  }

  bool _isConstraintFailure(Object e) =>
      e.toString().contains('constraint failed');

  Future<void> _applyRow(SyncTable table, Map<String, Object?> row) async {
    final updatedAt = _fromRemote(SyncColumnKind.timestamp, row['updated_at']);
    if (row['deleted_at'] != null) {
      // Deleted elsewhere. Keep the row if it was edited here afterwards.
      await _db.customStatement(
        'DELETE FROM ${table.name} WHERE id = ? AND updated_at <= ?',
        [row['id'], updatedAt],
      );
      return;
    }
    final names = table.columns.map((c) => c.name).toList();
    final values = [
      for (final c in table.columns) _fromRemote(c.kind, row[c.name]),
    ];
    final updates = [
      for (final n in names)
        if (n != 'id') '$n = excluded.$n',
    ].join(', ');
    await _db.customStatement(
      'INSERT INTO ${table.name} (${names.join(', ')}) '
      'VALUES (${List.filled(names.length, '?').join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET $updates '
      'WHERE excluded.updated_at >= ${table.name}.updated_at',
      values,
    );
  }

  // ------------------------------------------------------------- helpers

  Future<String?> _meta(String name) async {
    final r = await _db
        .customSelect(
          'SELECT value FROM sync_meta WHERE name = ?',
          variables: [Variable.withString(name)],
        )
        .getSingleOrNull();
    return r?.read<String>('value');
  }

  Future<void> _setMeta(String name, String value) => _db.customStatement(
    'INSERT INTO sync_meta (name, value) VALUES (?, ?) '
    'ON CONFLICT(name) DO UPDATE SET value = excluded.value',
    [name, value],
  );

  Map<String, Object?> _toRemote(SyncTable table, Map<String, Object?> row) => {
    for (final c in table.columns) c.name: _toRemoteValue(c.kind, row[c.name]),
  };

  Object? _toRemoteValue(SyncColumnKind kind, Object? v) {
    if (v == null) return null;
    return switch (kind) {
      SyncColumnKind.boolean => v == 1 || v == true,
      SyncColumnKind.timestamp => DateTime.fromMillisecondsSinceEpoch(
        (v as int) * 1000,
        isUtc: true,
      ).toIso8601String(),
      _ => v,
    };
  }

  Object? _fromRemote(SyncColumnKind kind, Object? v) {
    if (v == null) return null;
    return switch (kind) {
      SyncColumnKind.boolean => v == true ? 1 : 0,
      SyncColumnKind.timestamp =>
        DateTime.parse(v as String).toUtc().millisecondsSinceEpoch ~/ 1000,
      SyncColumnKind.integer => (v as num).toInt(),
      SyncColumnKind.text => v,
    };
  }
}
