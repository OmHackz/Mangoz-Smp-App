import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../chats/chats_screen.dart';
import '../map/server_map_screen.dart';
import '../server/server_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_screen.dart';

/// Persistent Material 3 navigation: Home / Chats / Map / Server / Settings.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _pages = [
    DashboardScreen(),
    ChatsScreen(),
    ServerMapScreen(),
    ServerScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    AuthService.updateLastSeen();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final unread = conversations.maybeWhen(
      data: (chats) => chats.fold<int>(0, (a, c) => a + c.unreadCount),
      orElse: () => 0,
    );

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: unread > 0
                ? Badge(
                    label: Text(unread > 99 ? '99+' : '$unread'),
                    child: const Icon(Icons.chat_bubble_outline),
                  )
                : const Icon(Icons.chat_bubble_outline),
            selectedIcon: unread > 0
                ? Badge(
                    label: Text(unread > 99 ? '99+' : '$unread'),
                    child: const Icon(Icons.chat_bubble),
                  )
                : const Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          const NavigationDestination(
            icon: Icon(Icons.dns_outlined),
            selectedIcon: Icon(Icons.dns),
            label: 'Server',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
