import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../app/supabase_config.dart';
import '../../../infrastructure/database/app_database.dart';

import '../data/fake_auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';
import 'local_data_eraser.dart';

enum SessionStatus {
  /// Restoring the session / loading the profile.
  loading,

  /// Not signed in.
  signedOut,

  /// Signed in, but the profile has no birth date yet.
  needsBirthDate,

  /// Signed in with a complete profile.
  ready,
}

@immutable
class SessionState {
  const SessionState(this.status, {this.user, this.birthDate});

  final SessionStatus status;
  final AppUser? user;
  final DateTime? birthDate;

  bool get isSignedIn => user != null;
}

/// The auth backend: Supabase when a publishable key is configured,
/// otherwise the in-memory fake. Tests override this.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    return SupabaseAuthRepository(Supabase.instance.client);
  }
  return FakeAuthRepository();
});

/// Who is signed in and whether the profile is complete. The router reads
/// this to decide where the user may go.
class SessionController extends Notifier<SessionState> {
  final _initialized = Completer<void>();
  StreamSubscription<AppUser?>? _subscription;

  /// Completes once the restored session (and profile) has been resolved,
  /// so startup can wait for it before showing any screen.
  Future<void> get initialized => _initialized.future;

  @override
  SessionState build() {
    final repo = ref.watch(authRepositoryProvider);
    _subscription = repo.authChanges().listen(_onUser);
    ref.onDispose(() => _subscription?.cancel());
    final user = repo.currentUser;
    return user == null
        ? const SessionState(SessionStatus.signedOut)
        : SessionState(SessionStatus.loading, user: user);
  }

  Future<void> _onUser(AppUser? user) async {
    if (!ref.mounted) return;
    if (user == null) {
      state = const SessionState(SessionStatus.signedOut);
      _finishInit();
      return;
    }
    if (state.user?.id != user.id || state.status == SessionStatus.loading) {
      state = SessionState(
        SessionStatus.loading,
        user: user,
        birthDate: state.user?.id == user.id ? state.birthDate : null,
      );
    }
    await _loadProfile(user);
  }

  Future<void> _loadProfile(AppUser user) async {
    DateTime? birthDate;
    var known = true;
    try {
      birthDate = await ref.read(authRepositoryProvider).fetchBirthDate();
    } on Object {
      // Offline or the service is down. A returning user must not be locked
      // out of data that lives on the device, so treat the profile as
      // complete; it is checked again on the next start.
      known = false;
    }
    if (!ref.mounted) return;
    state = SessionState(
      known && birthDate == null
          ? SessionStatus.needsBirthDate
          : SessionStatus.ready,
      user: user,
      birthDate: birthDate,
    );
    _finishInit();
  }

  void _finishInit() {
    if (!_initialized.isCompleted) _initialized.complete();
  }

  /// Saves the birth date; the status becomes [SessionStatus.ready].
  Future<void> saveBirthDate(DateTime date) async {
    await ref.read(authRepositoryProvider).saveBirthDate(date);
    if (!ref.mounted) return;
    state = SessionState(
      SessionStatus.ready,
      user: state.user,
      birthDate: DateTime.utc(date.year, date.month, date.day),
    );
  }

  /// Deletes the account on the server (and with it everything synced), then
  /// everything of it on this device. Throws [AuthFailure] without touching
  /// anything when the server cannot be reached.
  Future<void> deleteAccount() async {
    final user = state.user;
    if (user == null) return;
    // Read before the account goes: the paths live in this user's database.
    final db = ref.read(appDatabaseProvider);
    final slips = await db.localSlipPaths();
    await ref.read(authRepositoryProvider).deleteAccount();
    if (!ref.mounted) return;
    state = const SessionState(SessionStatus.signedOut);
    try {
      await db.close(); // the provider closes it too; closing twice is safe
    } on Object {
      // Already closed.
    }
    await ref
        .read(localDataEraserProvider)
        .erase(userId: user.id, slipPaths: slips);
  }

  /// Ends the session. Data on the device is kept.
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!ref.mounted) return;
    state = const SessionState(SessionStatus.signedOut);
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
