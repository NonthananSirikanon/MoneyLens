import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/supabase_config.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../auth/application/session.dart';
import '../data/supabase_sync_remote.dart';
import '../domain/sync_remote.dart';
import 'sync_engine.dart';

/// The server to sync with: Supabase when a project is configured, nothing
/// otherwise (local development and tests run without sync). Tests override
/// this.
final syncRemoteProvider = Provider<SyncRemote?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return SupabaseSyncRemote(Supabase.instance.client);
});

enum SyncPhase {
  /// Sync is not running: nobody signed in, or no server configured.
  disabled,
  idle,
  syncing,

  /// The last run could not reach the server; it retries by itself.
  offline,

  /// The server refused something; retried later, shown to the user.
  failed,
}

class SyncState {
  const SyncState(this.phase, {this.pending = 0, this.lastSyncedAt});

  final SyncPhase phase;

  /// Local changes not yet sent.
  final int pending;
  final DateTime? lastSyncedAt;

  SyncState copyWith({
    SyncPhase? phase,
    int? pending,
    DateTime? lastSyncedAt,
  }) => SyncState(
    phase ?? this.phase,
    pending: pending ?? this.pending,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
}

/// Decides when [SyncEngine] runs: after sign-in, a few seconds after a local
/// change, every few minutes, after a failure, and on demand. It lives only
/// while a user is signed in; signing out or switching user rebuilds it.
class SyncController extends Notifier<SyncState> {
  static const _afterChange = Duration(seconds: 3);
  static const _every = Duration(minutes: 5);
  static const _retryAfterFailure = Duration(seconds: 60);

  SyncEngine? _engine;
  Timer? _debounce;
  Timer? _retry;
  var _running = false;

  @override
  SyncState build() {
    final remote = ref.watch(syncRemoteProvider);
    final ready = ref.watch(
      sessionProvider.select((s) => s.status == SessionStatus.ready),
    );
    if (remote == null || !ready) {
      _engine = null;
      return const SyncState(SyncPhase.disabled);
    }
    final db = ref.watch(appDatabaseProvider);
    _engine = SyncEngine(db, remote);

    final queue = db.select(db.syncOutbox).watch().listen((rows) {
      if (!ref.mounted) return;
      state = state.copyWith(pending: rows.length);
      if (rows.isNotEmpty) _scheduleSoon();
    });
    final periodic = Timer.periodic(_every, (_) => syncNow());
    ref.onDispose(() {
      queue.cancel();
      periodic.cancel();
      _debounce?.cancel();
      _retry?.cancel();
    });

    scheduleMicrotask(syncNow);
    return const SyncState(SyncPhase.idle);
  }

  void _scheduleSoon() {
    _debounce?.cancel();
    _debounce = Timer(_afterChange, syncNow);
  }

  /// Runs a sync unless one is already running. Never throws.
  Future<void> syncNow() async {
    final engine = _engine;
    if (engine == null || _running || !ref.mounted) return;
    _running = true;
    _retry?.cancel();
    state = state.copyWith(phase: SyncPhase.syncing);
    try {
      await engine.run();
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: SyncPhase.idle,
        lastSyncedAt: DateTime.now(),
      );
    } on SyncFailure catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: e.offline ? SyncPhase.offline : SyncPhase.failed,
      );
      _retry = Timer(_retryAfterFailure, syncNow);
    } on Object {
      // Nothing from the failure is kept or logged: it can contain row data.
      if (!ref.mounted) return;
      state = state.copyWith(phase: SyncPhase.failed);
      _retry = Timer(_retryAfterFailure, syncNow);
    } finally {
      _running = false;
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);
