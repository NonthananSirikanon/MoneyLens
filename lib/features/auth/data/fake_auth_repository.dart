import 'dart:async';

import '../application/credentials.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// In-memory sign-in used when no Supabase project is configured (local
/// development) and in tests. NOT SECURE: passwords are kept in memory in
/// plain text and nothing is persisted.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AppUser? signedIn,
    this.birthDate,
    this.failure,
    Map<String, String> accounts = const {},
  }) : _user = signedIn,
       _accounts = {...accounts};

  /// Throw this from `signUp` and `signInWithPassword` (to test rate
  /// limiting and being offline).
  AuthFailureKind? failure;

  /// Registered users: normalized username → password.
  final Map<String, String> _accounts;

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

  AppUser _asUser(String name) => AppUser(
    id: 'fake-$name',
    method: SignInMethod.password,
    username: name,
    displayName: name,
  );

  @override
  Future<void> signUp(String username, String password) async {
    if (failure != null) throw AuthFailure(failure!);
    final name = Username.normalize(username);
    if (_accounts.containsKey(name)) {
      throw const AuthFailure(AuthFailureKind.usernameTaken);
    }
    _accounts[name] = password;
    _set(_asUser(name));
  }

  @override
  Future<void> signInWithPassword(String username, String password) async {
    if (failure != null) throw AuthFailure(failure!);
    final name = Username.normalize(username);
    if (_accounts[name] != password) {
      throw const AuthFailure(AuthFailureKind.invalidCredentials);
    }
    _set(_asUser(name));
  }

  @override
  Future<void> signInWithGoogle() async => _set(
    const AppUser(
      id: 'fake-google',
      method: SignInMethod.google,
      email: 'somchai.demo@gmail.com',
      displayName: 'สมชาย ใจดี',
    ),
  );

  @override
  Future<void> signOut() async {
    birthDate = null;
    _set(null);
  }

  @override
  Future<DateTime?> fetchBirthDate() async => birthDate;

  @override
  Future<void> saveBirthDate(DateTime date) async =>
      birthDate = DateTime.utc(date.year, date.month, date.day);
}
