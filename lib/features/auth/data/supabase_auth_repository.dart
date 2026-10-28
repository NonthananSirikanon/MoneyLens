import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../application/credentials.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// Supabase Auth (username + password, and Google) plus the `profiles`
/// table. A username is stored as an internal email (see [Username]).
///
/// Error text from the provider is never surfaced or logged, only mapped to
/// an [AuthFailureKind].
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  /// Where the Google sign-in returns to. Must be listed under
  /// Authentication → URL Configuration → Redirect URLs, and match the URL
  /// scheme registered in `Info.plist` and `AndroidManifest.xml`.
  static const redirectUrl = 'com.moneylens.app://login-callback/';

  final sb.SupabaseClient _client;

  sb.GoTrueClient get _auth => _client.auth;

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> authChanges() {
    // Emit the restored user and subscribe in the same step, so an event
    // arriving right after cannot be missed.
    late final StreamController<AppUser?> out;
    StreamSubscription<sb.AuthState>? sub;
    out = StreamController<AppUser?>(
      onListen: () {
        out.add(currentUser);
        sub = _auth.onAuthStateChange.listen(
          (e) => out.add(_map(e.session?.user)),
          onError: out.addError,
        );
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  AppUser? _map(sb.User? u) {
    if (u == null) return null;
    final isGoogle = u.appMetadata['provider'] == 'google';
    if (!isGoogle) {
      final name = Username.fromAuthEmail(u.email);
      return AppUser(
        id: u.id,
        method: SignInMethod.password,
        username: name,
        displayName: name,
      );
    }
    final name = u.userMetadata?['full_name'] ?? u.userMetadata?['name'];
    return AppUser(
      id: u.id,
      method: SignInMethod.google,
      email: u.email,
      displayName: name is String && name.isNotEmpty ? name : null,
    );
  }

  Future<T> _guard<T>(
    Future<T> Function() run, {
    AuthFailureKind otherwise = AuthFailureKind.unknown,
  }) async {
    try {
      return await run();
    } on sb.AuthApiException catch (e) {
      final code = (e.code ?? '').toLowerCase();
      switch (code) {
        case 'user_already_exists' || 'email_exists':
          throw const AuthFailure(AuthFailureKind.usernameTaken);
        case 'invalid_credentials':
          throw const AuthFailure(AuthFailureKind.invalidCredentials);
        case 'weak_password':
          throw const AuthFailure(AuthFailureKind.weakPassword);
      }
      if (e.statusCode == '429' || code.contains('rate_limit')) {
        throw const AuthFailure(AuthFailureKind.tooManyRequests);
      }
      throw AuthFailure(otherwise);
    } on sb.AuthRetryableFetchException {
      throw const AuthFailure(AuthFailureKind.network);
    } on SocketException {
      throw const AuthFailure(AuthFailureKind.network);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(AuthFailureKind.unknown);
    }
  }

  @override
  Future<void> signUp(String username, String password) => _guard(() async {
    final res = await _auth.signUp(
      email: Username.authEmail(username),
      password: password,
      data: {'username': Username.normalize(username)},
    );
    // With "Confirm email" on, no session starts and the user could never
    // confirm the internal address. Say so rather than hang.
    if (res.session == null) throw const AuthFailure(AuthFailureKind.unknown);
  });

  @override
  Future<void> signInWithPassword(String username, String password) => _guard(
    () => _auth.signInWithPassword(
      email: Username.authEmail(username),
      password: password,
    ),
    otherwise: AuthFailureKind.invalidCredentials,
  );

  @override
  Future<void> signInWithGoogle() => _guard(
    () =>
        _auth.signInWithOAuth(sb.OAuthProvider.google, redirectTo: redirectUrl),
  );

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  @override
  Future<DateTime?> fetchBirthDate() => _guard(() async {
    final row = await _client
        .from('profiles')
        .select('birth_date')
        .maybeSingle();
    final text = row?['birth_date'] as String?;
    return text == null ? null : DateTime.parse(text);
  });

  @override
  Future<void> saveBirthDate(DateTime date) => _guard(() async {
    final text =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    // user_id is filled from the JWT by the table default.
    await _client.from('profiles').upsert({
      'user_id': _auth.currentUser!.id,
      'birth_date': text,
    });
  });
}
