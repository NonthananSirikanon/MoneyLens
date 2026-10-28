import 'dart:async';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// Supabase Auth (Google) plus the `profiles` table.
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
      if (e.statusCode == '429' || code.contains('rate_limit')) {
        throw const AuthFailure(AuthFailureKind.tooManyRequests);
      }
      throw AuthFailure(otherwise);
    } on sb.AuthRetryableFetchException {
      throw const AuthFailure(AuthFailureKind.network);
    } on SocketException {
      throw const AuthFailure(AuthFailureKind.network);
    } on http.ClientException {
      throw const AuthFailure(AuthFailureKind.network);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(AuthFailureKind.unknown);
    }
  }

  @override
  Future<void> signInWithGoogle() => _guard(
    () =>
        _auth.signInWithOAuth(sb.OAuthProvider.google, redirectTo: redirectUrl),
  );

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  @override
  Future<void> deleteAccount() => _guard(() async {
    await _client.rpc('delete_my_account');
    try {
      // The server session died with the user; only forget it here.
      await _auth.signOut(scope: sb.SignOutScope.local);
    } on Object {
      // The account is gone either way.
    }
  });

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
