import 'package:flutter/foundation.dart' show immutable;

/// How the user signed in. The method is shown in Settings → Account.
enum SignInMethod { phone, google }

/// The signed-in account. Never log any field: phone and email are personal
/// data (ARCHITECTURE.md §11).
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.method,
    this.phone,
    this.email,
    this.displayName,
  });

  final String id;
  final SignInMethod method;

  /// E.164, e.g. `+66812345678`. Phone sign-in only.
  final String? phone;
  final String? email;

  /// Name from the Google account, when the provider shares it.
  final String? displayName;

  /// `81 ••• 5678` for a `+66…` number, null otherwise. Only masked
  /// numbers are ever shown.
  String? get maskedPhone {
    final p = phone;
    if (p == null || !p.startsWith('+66') || p.length != 12) return null;
    final national = p.substring(3);
    return '${national.substring(0, 2)} ••• ${national.substring(5)}';
  }
}

enum AuthFailureKind {
  /// The code does not match.
  invalidCode,

  /// The code is too old; a new one must be requested.
  expiredCode,

  /// The provider is rate-limiting SMS or verification attempts.
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
