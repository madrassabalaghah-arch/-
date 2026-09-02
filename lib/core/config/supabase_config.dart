/// Supabase connection settings.
///
/// Values arrive through `--dart-define` at build time. Dart has no
/// `VITE_` convention; that prefix belongs to Vite bundlers. The Dart
/// equivalent is a compile-time environment constant, read here.
///
/// Run the app with:
///
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
/// ```
///
/// Only the publishable (anon) key is ever compiled in. It is designed to
/// be public: every request it makes is still subject to row level
/// security. The service role key must never appear in this application.
class SupabaseConfig {
  const SupabaseConfig._();

  /// Supabase project REST URL.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );

  /// Publishable (anon) key. Safe to ship; RLS is what protects the data.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _defaultKey,
  );

  /// Project reference, useful for diagnostics and storage URLs.
  static const String projectId = String.fromEnvironment(
    'SUPABASE_PROJECT_ID',
    defaultValue: 'dvfaavutgxzuffninxpd',
  );

  /// Defaults for the current development project, so the app runs without
  /// extra flags. Override them with --dart-define for another environment.
  static const String _defaultUrl = 'https://dvfaavutgxzuffninxpd.supabase.co';
  static const String _defaultKey = 'sb_publishable_hVDY9XtiHJjI0Fg5lAyNyQ_HbSqv0Zi';

  /// Storage bucket for profile pictures. Public read.
  static const String avatarsBucket = 'avatars';

  /// Storage bucket for report evidence. Private; read via signed URLs.
  static const String evidenceBucket = 'evidence';

  /// How long a signed evidence URL stays valid.
  static const int signedUrlSeconds = 3600;

  /// True when the configuration looks usable.
  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
