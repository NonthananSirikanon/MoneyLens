import 'dart:async';

import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// In-memory sign-in used when no Supabase project is configured (local
/// development) and in tests. Nothing is persisted.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? signedIn, this.birthDate, this.failure})
    : _user = signedIn;

  /// Throw this from `signInWithGoogle` (to test being offline).
  AuthFailureKind? failure;

  AppUser? _user;

  /// The saved birth date (date only, UTC).
  DateTime? birthDate;
  final _changes = StreamController<AppUser?>.broadcast();

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authChanges() {
    // Subscribe to changes in the same step as emitting the current user, so
    // a sign-in right after the first event cannot be missed.
    late final StreamController<AppUser?> out;
    StreamSubscription<AppUser?>? sub;
    out = StreamController<AppUser?>(
      onListen: () {
        out.add(_user);
        sub = _changes.stream.listen(out.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  void _set(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  Future<void> signInWithGoogle() async {
    if (failure != null) throw AuthFailure(failure!);
    _set(
      const AppUser(
        id: 'fake-google',
        method: SignInMethod.google,
        email: 'somchai.demo@gmail.com',
        displayName: 'สมชาย ใจดี',
      ),
    );
  }

  @override
  Future<void> signOut() async {
    birthDate = null;
    _set(null);
  }

  /// True once [deleteAccount] succeeded, for assertions.
  var accountDeleted = false;

  @override
  Future<void> deleteAccount() async {
    if (failure != null) throw AuthFailure(failure!);
    accountDeleted = true;
    birthDate = null;
    _set(null);
  }

  @override
  Future<DateTime?> fetchBirthDate() async => birthDate;

  @override
  Future<void> saveBirthDate(DateTime date) async =>
      birthDate = DateTime.utc(date.year, date.month, date.day);
}
