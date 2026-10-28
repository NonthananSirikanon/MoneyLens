import 'dart:async';

import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// In-memory sign-in used when no Supabase project is configured (local
/// development) and in tests. NOT SECURE: the one-time code is always
/// [validCode] and nothing is persisted.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? signedIn, this.birthDate, this.sendFailure})
    : _user = signedIn;

  static const validCode = '123456';

  /// Throw this from `sendPhoneOtp` (to test rate limiting and offline).
  AuthFailureKind? sendFailure;

  AppUser? _user;

  /// The saved birth date (date only, UTC).
  DateTime? birthDate;
  final _changes = StreamController<AppUser?>.broadcast();

  /// Codes sent so far, for assertions.
  final sentTo = <String>[];

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
  Future<void> sendPhoneOtp(String e164) async {
    if (sendFailure != null) throw AuthFailure(sendFailure!);
    sentTo.add(e164);
  }

  @override
  Future<void> verifyPhoneOtp(String e164, String code) async {
    if (code != validCode) throw const AuthFailure(AuthFailureKind.invalidCode);
    _set(AppUser(id: 'fake-phone', method: SignInMethod.phone, phone: e164));
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
