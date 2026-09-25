import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

/// Passwordless authentication via Supabase email OTP.
///
/// Flow: [sendEmailOtp] emails a 6-digit code, [verifyEmailOtp] redeems it.
/// Works for both new and returning users (no passwords anywhere).
///
/// IMPORTANT (Supabase dashboard): Auth → Email Templates → Magic Link must
/// include `{{ .Token }}` so the email actually contains the 6-digit code.
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

  /// Sends a 6-digit login code to [email]. Creates the account on first use.
  static Future<void> sendEmailOtp(String email) async {
    final clean = email.trim();
    if (clean.isEmpty || !clean.contains('@')) {
      throw FormatException('Enter a valid email address.');
    }
    await _client.auth.signInWithOtp(
      email: clean,
      shouldCreateUser: true,
    );
  }

  /// Redeems the 6-digit [token] for [email]. Tries the sign-in OTP type
  /// first, then the sign-up type (new accounts created by [sendEmailOtp]).
  static Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final cleanToken = token.trim();
    if (cleanToken.length < 6) {
      throw FormatException('Enter the 6-digit code.');
    }
    try {
      return await _client.auth.verifyOTP(
        email: email.trim(),
        token: cleanToken,
        type: OtpType.email,
      );
    } catch (_) {
      return await _client.auth.verifyOTP(
        email: email.trim(),
        token: cleanToken,
        type: OtpType.signup,
      );
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> updateEmail(String newEmail) async {
    await _client.auth.updateUser(UserAttributes(email: newEmail));
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
      ...?avatarUrl == null ? null : {'avatar_url': avatarUrl},
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
    if (e is FormatException) return e.message;
    if (msg.contains('rate limit') || msg.contains('Rate limit')) {
      return 'Too many attempts. Wait a minute, then resend the code.';
    }
    if (msg.contains('expired') || msg.contains('Expired')) {
      return 'That code expired. Request a new one.';
    }
    if (msg.contains('invalid') && msg.contains('otp')) {
      return 'Incorrect code. Check the email and try again.';
    }
    if (msg.contains('Token has expired or is invalid')) {
      return 'Incorrect or expired code. Try again or resend.';
    }
    if (msg.contains('User already registered')) {
      return 'An account with this email already exists.';
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
