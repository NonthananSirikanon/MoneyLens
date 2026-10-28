import 'auth_models.dart';

/// Sign-in and the profile collected right after it. Implemented by
/// Supabase Auth in the app and by an in-memory fake for tests and for
/// running without a configured backend.
abstract interface class AuthRepository {
  /// The restored session, if any (available synchronously after startup).
  AppUser? get currentUser;

  /// Emits the current user (or null) first, then every change.
  Stream<AppUser?> authChanges();

  /// Creates the account and signs in. [username] must already pass
  /// `Username.validate`. Throws [AuthFailure] with `usernameTaken`,
  /// `weakPassword`, ….
  Future<void> signUp(String username, String password);

  /// Throws [AuthFailure] with `invalidCredentials` for an unknown name or a
  /// wrong password.
  Future<void> signInWithPassword(String username, String password);

  /// Opens the Google sign-in. The session arrives later through
  /// [authChanges] (the OAuth redirect returns to the app).
  Future<void> signInWithGoogle();

  Future<void> signOut();

  /// The saved birth date (date only), or null when the user has not given
  /// one yet.
  Future<DateTime?> fetchBirthDate();

  Future<void> saveBirthDate(DateTime date);
}
