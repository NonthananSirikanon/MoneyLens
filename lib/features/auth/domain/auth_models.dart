import 'package:flutter/foundation.dart' show immutable;

/// How the user signed in. The method is shown in Settings → Account.
enum SignInMethod { password, google }

/// The signed-in account. Never log any field: the name and email are
/// personal data (ARCHITECTURE.md §11).
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.method,
    this.username,
    this.email,
    this.displayName,
  });

  final String id;
  final SignInMethod method;

  /// The chosen name for username + password sign-in.
  final String? username;

  /// The real email of a Google account. Null for username sign-in, whose
  /// internal address is never exposed.
  final String? email;

  /// Name from the Google account, when the provider shares it.
  final String? displayName;
}

enum AuthFailureKind {
  /// Wrong username or password (deliberately not said which).
  invalidCredentials,

  /// Registration with a username that already exists.
  usernameTaken,

  /// The server rejected the password as too weak.
  weakPassword,

  /// The provider is rate-limiting requests.
  tooManyRequests,

  /// No connection or the service could not be reached.
  network,

  /// The user closed the sign-in sheet or browser.
  cancelled,

  unknown,
}

/// A sign-in problem the UI can explain. Carries only a [kind], never
/// provider text that could contain a phone number or email.
class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;

  @override
  String toString() => 'AuthFailure(${kind.name})';
}
