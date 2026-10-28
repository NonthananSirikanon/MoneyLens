import '../features/auth/application/session.dart';

/// Where the user is allowed to be, given the session. Pure so it can be
/// tested without a router.
///
/// * signed out: only onboarding and the sign-in screens;
/// * signed in without a birth date: only the birth-date screen;
/// * ready: everything except the sign-in screens, and the birth-date screen
///   only when editing (`?edit=1`).
String? authRedirect({
  required Uri uri,
  required SessionStatus status,
  required bool onboardingDone,
}) {
  final path = uri.path;
  const signInPaths = {'/login'};
  final isSignIn = signInPaths.contains(path);
  final isBirth = path == '/birth';
  final isEdit = uri.queryParameters['edit'] == '1';

  switch (status) {
    case SessionStatus.loading:
      return null;
    case SessionStatus.signedOut:
      if (isSignIn || path == '/onboarding') return null;
      return onboardingDone ? '/login' : '/onboarding';
    case SessionStatus.needsBirthDate:
      return isBirth ? null : '/birth';
    case SessionStatus.ready:
      if (isSignIn || (isBirth && !isEdit)) {
        return onboardingDone ? '/home' : '/permissions';
      }
      return null;
  }
}
