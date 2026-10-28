import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/sync_remote.dart';

/// The Supabase tables from `supabase/migrations`. Row Level Security keeps
/// every query to the signed-in user's rows; `user_id` is sent explicitly
/// only because an upsert needs the whole key.
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);

  final sb.SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  /// Network problems become an offline [SyncFailure]; anything else is
  /// surfaced as a server-side one. Error text is never kept: it can echo
  /// row values.
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on SocketException {
      throw const SyncFailure(true);
    } on TimeoutException {
      throw const SyncFailure(true);
    } on sb.AuthRetryableFetchException {
      throw const SyncFailure(true);
    } on sb.PostgrestException {
      throw const SyncFailure(false);
    } on sb.AuthException {
      throw const SyncFailure(false);
    }
  }

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) =>
      _guard(() async {
        final user = _userId;
        await _client.from(table).upsert([
          for (final r in rows) {...r, 'user_id': user},
        ], onConflict: 'user_id,id');
      });

  @override
  Future<void> markDeleted(String table, List<String> ids, DateTime at) =>
      _guard(() async {
        final stamp = at.toUtc().toIso8601String();
        // The server ignores this if the row was edited after [at].
        await _client
            .from(table)
            .update({'deleted_at': stamp, 'updated_at': stamp})
            .inFilter('id', ids);
      });

  @override
  Future<RemotePage> pull(String table, {String? cursor, required int limit}) =>
      _guard(() async {
        var query = _client.from(table).select();
        if (cursor != null) query = query.gt('server_updated_at', cursor);
        final rows = await query.order('server_updated_at').limit(limit);
        return RemotePage([
          for (final r in rows) Map<String, Object?>.from(r as Map),
        ]);
      });
}
