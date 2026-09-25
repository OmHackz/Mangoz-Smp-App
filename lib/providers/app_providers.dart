import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/server_config.dart';
import '../models/app_settings.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/server_status.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/server_status_service.dart';
import '../services/supabase_service.dart';

// ---------- Shared prefs ----------

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// ---------- Auth ----------

class AuthState {
  final bool initializing;
  final bool signedIn;
  final UserProfile? profile;
  final bool onboardingComplete;

  const AuthState({
    this.initializing = true,
    this.signedIn = false,
    this.profile,
    this.onboardingComplete = false,
  });

  AuthState copyWith({
    bool? initializing,
    bool? signedIn,
    UserProfile? profile,
    bool? onboardingComplete,
  }) {
    return AuthState(
      initializing: initializing ?? this.initializing,
      signedIn: signedIn ?? this.signedIn,
      profile: profile ?? this.profile,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  Future<void> _init() async {
    if (!SupabaseService.isConfigured) {
      state = state.copyWith(initializing: false, signedIn: false);
      return;
    }
    final session = AuthService.currentUser;
    if (session == null) {
      state = state.copyWith(initializing: false, signedIn: false);
      return;
    }
    try {
      final profile = await AuthService.fetchMyProfile();
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('onboarding_complete_${session.id}') ??
          (profile != null);
      state = AuthState(
        initializing: false,
        signedIn: true,
        profile: profile,
        onboardingComplete: done,
      );
      unawaited(AuthService.updateLastSeen());
    } catch (_) {
      state = state.copyWith(initializing: false, signedIn: true);
    }
  }

  Future<void> refreshProfile() async {
    try {
      final profile = await AuthService.fetchMyProfile();
      state = state.copyWith(profile: profile);
    } catch (_) {}
  }

  Future<void> setOnboardingComplete() async {
    final uid = AuthService.currentUser?.id;
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete_$uid', true);
    }
    state = state.copyWith(onboardingComplete: true);
    await refreshProfile();
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    state = const AuthState(initializing: false, signedIn: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ---------- Server config ----------

class ServerConfigNotifier extends Notifier<ServerConfig> {
  static const _key = 'server_config_json';

  @override
  ServerConfig build() {
    _load();
    return const ServerConfig();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      state = ServerConfig.fromJson(json);
    } catch (_) {}
  }

  Future<String?> update(ServerConfig config) async {
    final err = config.validate();
    if (err != null) return err;
    state = config;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(config.toJson()));
    } catch (_) {}
    return null;
  }
}

final serverConfigProvider =
    NotifierProvider<ServerConfigNotifier, ServerConfig>(
  ServerConfigNotifier.new,
);

// ---------- Server status ----------

class ServerStatusState {
  final ServerStatus? java;
  final ServerStatus? bedrock;
  final bool loading;
  final String? error;

  const ServerStatusState({
    this.java,
    this.bedrock,
    this.loading = false,
    this.error,
  });

  ServerStatusState copyWith({
    ServerStatus? java,
    ServerStatus? bedrock,
    bool? loading,
    String? error,
  }) {
    return ServerStatusState(
      java: java ?? this.java,
      bedrock: bedrock ?? this.bedrock,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  bool get anyOnline => (java?.online ?? false) || (bedrock?.online ?? false);
}

class ServerStatusNotifier extends Notifier<ServerStatusState> {
  Timer? _timer;
  final _service = McSrvStatStatusService();

  @override
  ServerStatusState build() {
    ref.listen(serverConfigProvider, (_, _) => refresh());
    _startPolling();
    ref.onDispose(() => _timer?.cancel());
    // Kick off first check.
    Future.microtask(refresh);
    return const ServerStatusState(loading: true);
  }

  void _startPolling() {
    _timer?.cancel();
    final interval =
        ref.read(serverConfigProvider).statusRefreshInterval;
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  Future<void> refresh() async {
    final config = ref.read(serverConfigProvider);
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait([
        _service.checkJavaServer(config.javaHost, config.javaPort),
        _service.checkBedrockServer(config.bedrockHost, config.bedrockPort),
      ]);
      state = state.copyWith(
        java: results[0],
        bedrock: results[1],
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final serverStatusProvider =
    NotifierProvider<ServerStatusNotifier, ServerStatusState>(
  ServerStatusNotifier.new,
);

// ---------- Chats ----------

final conversationsProvider =
    FutureProvider<List<Chat>>((ref) async {
  if (!SupabaseService.isConfigured) return const [];
  // Re-fetch when auth changes.
  ref.watch(authProvider.select((s) => s.signedIn));
  return ChatService.fetchConversations();
});

class MessagesNotifier
    extends FamilyAsyncNotifier<List<Message>, String> {
  @override
  Future<List<Message>> build(String conversationId) async {
    final messages =
        await ChatService.fetchMessages(conversationId);
    // Oldest-first for ListView(reverse: true) is handled by UI; keep
    // newest-first from service but expose oldest-first? Keep as-is and let
    // UI reverse. Store newest-first.
    unawaited(ChatService.markAsRead(conversationId));
    return messages;
  }

  Future<void> loadOlder() async {
    final current = state.valueOrNull ?? const <Message>[];
    if (current.isEmpty) return;
    final oldest = current.last.createdAt;
    final older = await ChatService.fetchMessages(
      arg,
      before: oldest,
    );
    if (older.isEmpty) return;
    state = AsyncData([...current, ...older]);
  }

  void prepend(Message m) {
    final current = state.valueOrNull ?? const <Message>[];
    if (current.any((e) => e.id == m.id)) return;
    state = AsyncData([m, ...current]);
  }

  void upsert(Message m) {
    final current = state.valueOrNull ?? const <Message>[];
    final idx = current.indexWhere((e) => e.id == m.id);
    if (idx == -1) {
      prepend(m);
      return;
    }
    final next = [...current];
    next[idx] = m;
    state = AsyncData(next);
  }

  void remove(String id) {
    final current = state.valueOrNull ?? const <Message>[];
    state = AsyncData(current.where((e) => e.id != id).toList());
  }
}

final messagesProvider = AsyncNotifierProviderFamily<MessagesNotifier,
    List<Message>, String>(MessagesNotifier.new);

// ---------- Settings ----------

class SettingsNotifier extends Notifier<AppSettings> {
  static const _key = 'app_settings_json';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      state = AppSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> update(AppSettings next) async {
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(next.toJson()));
    } catch (_) {}
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// ---------- Theme ----------

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final settings = ref.watch(settingsProvider);
    switch (settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ---------- Blocked users (local stub backed by Supabase table if present) ----------

final blockedUsersProvider =
    FutureProvider<List<String>>((ref) async {
  if (!SupabaseService.isConfigured ||
      AuthService.currentUser == null) {
    return const [];
  }
  try {
    final rows = await SupabaseService.client
        .from('blocked_users')
        .select('blocked_user_id')
        .eq('user_id', AuthService.currentUser!.id);
    return (rows as List)
        .map((e) => (e as Map)['blocked_user_id'] as String)
        .toList();
  } catch (_) {
    return const [];
  }
});
