import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

/// Authentication + profile onboarding helpers backed by Supabase Auth.
class AuthService {
  AuthService._();

  static SupabaseClient get _client => SupabaseService.client;

  static User? get currentUser => SupabaseService.isConfigured
      ? Supabase.instance.client.auth.currentUser
      : null;

  static Stream<AuthState> authStateChanges() {
    if (!SupabaseService.isConfigured) return const Stream.empty();
    return Supabase.instance.client.auth.onAuthStateChange;
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    return res;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res;
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  static Future<void> updateEmail(String newEmail) async {
    await _client.auth.updateUser(UserAttributes(email: newEmail));
  }

  static Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<void> deleteAccount() async {
    // Supabase has no client-side self-delete; remove profile rows then
    // sign out. Actual auth.user deletion must be done server-side.
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.from('profiles').delete().eq('id', user.id);
    } catch (_) {
      // Best effort — RLS may restrict; still sign out.
    }
    await _client.auth.signOut();
  }

  // ---- Profiles / onboarding ----

  static Future<UserProfile?> fetchMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromJson(row);
  }

  static Future<bool> isUsernameAvailable(String username) async {
    final normalized = UserProfile.normalizeUsername(username).toLowerCase();
    final rows = await _client
        .from('profiles')
        .select('id')
        .ilike('username', normalized)
        .limit(1) as List;
    return rows.isEmpty;
  }

  static Future<UserProfile> upsertMyProfile({
    required String username,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not signed in.');
    final normalized = UserProfile.normalizeUsername(username);
    final payload = {
      'id': user.id,
      'username': normalized,
      'avatar_url': ?avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = await _client
        .from('profiles')
        .upsert(payload, onConflict: 'id')
        .select()
        .single();
    return UserProfile.fromJson(row);
  }

  static Future<void> updateLastSeen() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.from('profiles').update({
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);
    } catch (_) {
      // Non-fatal.
    }
  }

  static String friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Please confirm your email, then try again.';
    }
    if (msg.contains('Network') || msg.contains('SocketException')) {
      return 'Unable to connect. Check your internet connection.';
    }
    if (msg.contains('not configured')) {
      return 'Backend not configured. Add Supabase credentials.';
    }
    // Strip "Exception:" prefix for display.
    return msg.replaceFirst(RegExp(r'^.*Exception:\s*'), '');
  }
}
