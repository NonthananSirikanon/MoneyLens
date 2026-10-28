import 'package:flutter/foundation.dart' show immutable;

/// How the user signed in. The method is shown in Settings → Account.
enum SignInMethod { google }

/// The signed-in account. Never log any field: name and email are personal
/// data (ARCHITECTURE.md §11).
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.method,
    this.email,
    this.displayName,
  });

  final String id;
  final SignInMethod method;

  final String? email;

  /// Name from the Google account, when the provider shares it.
  final String? displayName;
}

enum AuthFailureKind {
  /// The provider is rate-limiting sign-in attempts.
  tooManyRequests,

  /// No connection or the service could not be reached.
  network,

  /// The user closed the sign-in sheet or browser.
  cancelled,

  unknown,
}

/// A sign-in problem the UI can explain. Carries only a [kind], never
/// provider text that could contain a name or email.
class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;

  @override
  String toString() => 'AuthFailure(${kind.name})';
}
