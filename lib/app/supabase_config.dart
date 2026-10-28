/// Supabase connection settings, supplied at build time so no key is
/// committed:
///
/// ```sh
/// flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
/// ```
///
/// Only the publishable (anon) key belongs in the app. Never use the
/// `service_role` / secret key here (ARCHITECTURE.md §11).
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://smtfabhrkmvyzpynmaas.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Without a key the app uses `FakeAuthRepository` (OTP `123456`).
  static bool get isConfigured => publishableKey.isNotEmpty;
}
