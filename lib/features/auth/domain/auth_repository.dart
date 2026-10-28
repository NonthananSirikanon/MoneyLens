import 'auth_models.dart';

/// Sign-in and the profile collected right after it. Implemented by
/// Supabase Auth in the app and by an in-memory fake for tests and for
/// running without a configured backend.
abstract interface class AuthRepository {
  /// The restored session, if any (available synchronously after startup).
  AppUser? get currentUser;

  /// Emits the current user (or null) first, then every change.
  Stream<AppUser?> authChanges();

  /// Opens the Google sign-in. The session arrives later through
  /// [authChanges] (the OAuth redirect returns to the app).
  Future<void> signInWithGoogle();

  Future<void> signOut();

  /// Deletes the account and all of its data on the server, then ends the
  /// session. Throws [AuthFailure] (for example `network`) without changing
  /// anything when it cannot be done.
  Future<void> deleteAccount();

  /// The saved birth date (date only), or null when the user has not given
  /// one yet.
  Future<DateTime?> fetchBirthDate();

  Future<void> saveBirthDate(DateTime date);
}
