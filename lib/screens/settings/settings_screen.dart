import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../providers/app_providers.dart';
import '../../widgets/ore_setting_tile.dart';
import '../../widgets/player_avatar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ore = OreTheme.of(context);
    final profile = ref.watch(authProvider.select((s) => s.profile));

    void go(String route) => Navigator.of(context).pushNamed(route);

    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Text('Settings', style: ore.typography.choiceTitle),
      ),
      body: ListView(
        children: [
          InkWell(
            onTap: () => go('/profile'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  PlayerAvatar(
                    username: profile?.username ?? '?',
                    imageUrl: profile?.avatarUrl,
                    size: 56,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@${profile?.username ?? '…'}',
                            style: ore.typography.label),
                        Text('View profile',
                            style: ore.typography.caption),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const OreSectionHeader(title: 'General'),
          OreSettingTile(
              icon: Icons.person,
              title: 'Account',
              subtitle: 'Profile, email, password',
              onTap: () => go('/account-settings')),
          OreSettingTile(
              icon: Icons.chat_bubble_outline,
              title: 'Chats',
              subtitle: 'Media, link previews, send key',
              onTap: () => go('/global-chat-settings')),
          OreSettingTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Message, group, server alerts',
              onTap: () => go('/notification-settings')),
          OreSettingTile(
              icon: Icons.lock_outline,
              title: 'Privacy',
              subtitle: 'Online status, blocked users',
              onTap: () => go('/privacy-settings')),
          OreSettingTile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'Theme, text size',
              onTap: () => go('/appearance-settings')),
          OreSettingTile(
              icon: Icons.dns_outlined,
              title: 'Server',
              subtitle: 'Hosts, ports, map URL',
              onTap: () => go('/server-settings')),
          OreSettingTile(
              icon: Icons.info_outline,
              title: 'App',
              subtitle: 'Version, licenses, debug',
              onTap: () => go('/app-settings')),
        ],
      ),
    );
  }
}
