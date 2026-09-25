import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../widgets/settings_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(authProvider.select((s) => s.profile));
    final username = profile?.username ?? '…';
    final initial =
        username.isEmpty ? '?' : username[0].toUpperCase();

    void go(String route) => Navigator.of(context).pushNamed(route);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: ListTile(
                onTap: () => go('/profile'),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage:
                      profile?.avatarUrl?.isNotEmpty == true
                          ? CachedNetworkImageProvider(
                              profile!.avatarUrl!)
                          : null,
                  onBackgroundImageError: (_, _) {},
                  child:
                      profile?.avatarUrl?.isNotEmpty == true
                          ? null
                          : Text(initial,
                              style: TextStyle(
                                  color: scheme
                                      .onPrimaryContainer)),
                ),
                title: Text('@$username',
                    style:
                        Theme.of(context).textTheme.titleLarge),
                subtitle: const Text('View profile'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
          const SettingsSection(title: 'General'),
          SettingsTile(
              icon: Icons.person_outline,
              title: 'Account',
              subtitle: 'Profile, username, email',
              onTap: () => go('/account-settings')),
          SettingsTile(
              icon: Icons.chat_bubble_outline,
              title: 'Chats',
              subtitle: 'Media, link previews, text size',
              onTap: () => go('/global-chat-settings')),
          SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Message, group, server alerts',
              onTap: () => go('/notification-settings')),
          SettingsTile(
              icon: Icons.lock_outline,
              title: 'Privacy',
              subtitle: 'Online status, blocked users',
              onTap: () => go('/privacy-settings')),
          SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'Theme',
              onTap: () => go('/appearance-settings')),
          SettingsTile(
              icon: Icons.dns_outlined,
              title: 'Server',
              subtitle: 'Hosts, ports, map URL',
              onTap: () => go('/server-settings')),
          SettingsTile(
              icon: Icons.info_outline,
              title: 'App',
              subtitle: 'Version, updates, licenses',
              onTap: () => go('/app-settings')),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
