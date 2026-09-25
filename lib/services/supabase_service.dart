import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Owns Supabase initialization and exposes the client.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    if (!SupabaseConfig.isConfigured) {
      // Still mark initialized so the app can boot into a
      // "Supabase not configured" state instead of crashing.
      _initialized = true;
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.effectiveKey,
    );
    _initialized = true;
  }

  static SupabaseClient get client {
    if (!SupabaseConfig.isConfigured) {
      throw StateError(
        'Supabase is not configured. Pass --dart-define=SUPABASE_URL and '
        '--dart-define=SUPABASE_ANON_KEY.',
      );
    }
    return Supabase.instance.client;
  }

  static bool get isConfigured => SupabaseConfig.isConfigured;
}
