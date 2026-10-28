/// Why a username or password is not acceptable.
enum UsernameProblem { empty, length, characters }

enum PasswordProblem { tooShort, mismatch }

/// Rules for the username shown in the app and used to sign in.
///
/// Supabase Auth has no username, so the name is stored as the email
/// `<name>@users.moneylens.app` (see [Username.authEmail]). No mail is ever
/// sent to it, which is also why a forgotten password cannot be recovered.
abstract final class Username {
  static const minLength = 3;
  static const maxLength = 20;

  /// Host of the internal address. Never shown to the user.
  static const emailHost = 'users.moneylens.app';

  static final _allowed = RegExp(r'^[a-z0-9_]+$');

  /// Lower-case and trimmed, so `Somchai` and `somchai ` are the same user.
  static String normalize(String input) => input.trim().toLowerCase();

  /// The first problem with [input], or null when it can be used.
  static UsernameProblem? validate(String input) {
    final name = normalize(input);
    if (name.isEmpty) return UsernameProblem.empty;
    if (name.length < minLength || name.length > maxLength) {
      return UsernameProblem.length;
    }
    if (!_allowed.hasMatch(name)) return UsernameProblem.characters;
    return null;
  }

  static String authEmail(String input) => '${normalize(input)}@$emailHost';

  /// The username back from an internal address, or null for any other
  /// email (a Google account).
  static String? fromAuthEmail(String? email) {
    const suffix = '@$emailHost';
    if (email == null || !email.endsWith(suffix)) return null;
    return email.substring(0, email.length - suffix.length);
  }
}

abstract final class PasswordRules {
  static const minLength = 8;

  static PasswordProblem? validate(String password, {String? confirm}) {
    if (password.length < minLength) return PasswordProblem.tooShort;
    if (confirm != null && confirm != password) return PasswordProblem.mismatch;
    return null;
  }
}
