import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../chats/chats_screen.dart';
import '../map/server_map_screen.dart';
import '../server/server_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_screen.dart';

/// Persistent bottom navigation shell: Chats / Map / Server / Settings.
/// Dashboard is the Chats tab header? Spec wants Dashboard after onboarding
/// plus 4 tabs. We implement Home tab as Dashboard with quick access, and
/// bottom bar has Chats, Map, Server, Settings. Dashboard is reachable via
/// the top brand button and is the initial tab content's header.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  final _pages = const [
    DashboardScreen(),
    ChatsScreen(),
    ServerMapScreen(),
    ServerScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Update last-seen presence.
    AuthService.updateLastSeen();
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return Scaffold(
      backgroundColor: ore.colors.background,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ore.colors.surface,
          border: Border(
            top: BorderSide(
                color: ore.colors.border,
                width: ore.borderWidth),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              _navItem(context, 0, Icons.dashboard, 'Home'),
              _navItem(context, 1, Icons.chat_bubble, 'Chats'),
              _navItem(context, 2, Icons.map, 'Map'),
              _navItem(context, 3, Icons.dns, 'Server'),
              _navItem(context, 4, Icons.settings, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      BuildContext context, int index, IconData icon, String label) {
    final ore = OreTheme.of(context);
    final selected = _index == index;
    final conversations = ref.watch(conversationsProvider);
    int unread = 0;
    conversations.whenData((chats) {
      unread = chats.fold<int>(0, (a, c) => a + c.unreadCount);
    });
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? ore.colors.surfaceDark.withValues(alpha: 0.6)
                : null,
            border: selected
                ? Border(
                    top: BorderSide(
                        color: ore.colors.success, width: 3))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? ore.colors.success
                        : ore.colors.textMuted,
                    size: 24,
                  ),
                  if (index == 1 && unread > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: ore.colors.danger,
                          border: Border.all(
                              color: ore.colors.border, width: 1),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: ore.typography.caption.copyWith(
                            color: ore.colors.textInverse,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: ore.typography.caption.copyWith(
                  color: selected
                      ? ore.colors.textPrimary
                      : ore.colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
