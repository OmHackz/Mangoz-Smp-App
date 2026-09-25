/// Supabase client configuration.
///
/// Secrets are NEVER hardcoded for production: pass them with
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// (or SUPABASE_PUBLISHABLE_KEY — same value, new name).
/// The placeholder defaults below only allow the app to boot into a
/// "not configured" error state with a retry option.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder-anon-key',
  );

  /// New name for the same key (supabase_flutter >= 2.17 prefers this).
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// Effective key: prefer the new flag, fall back to the legacy one.
  static String get effectiveKey =>
      publishableKey.isNotEmpty ? publishableKey : anonKey;

  static bool get isConfigured =>
      !url.contains('placeholder') &&
      !effectiveKey.contains('placeholder');
}
