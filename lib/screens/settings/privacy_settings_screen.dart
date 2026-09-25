import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/chat_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/settings_widgets.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final blocked = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        children: [
          SettingsTile(
            icon: Icons.circle_outlined,
            title: 'Show online status',
            subtitle: s.showOnlineStatus
                ? 'Others see you online'
                : 'Hidden',
            trailing: Switch(
              value: s.showOnlineStatus,
              onChanged: (v) =>
                  n.update(s.copyWith(showOnlineStatus: v)),
            ),
          ),
          const SettingsSection(title: 'Profile visibility'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: s.profileVisibility,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Who can see my profile',
              ),
              items: const [
                DropdownMenuItem(
                    value: 'everyone',
                    child: Text('Everyone')),
                DropdownMenuItem(
                    value: 'contacts',
                    child: Text('People I chat with')),
                DropdownMenuItem(
                    value: 'nobody', child: Text('Nobody')),
              ],
              onChanged: (v) {
                if (v == null) return;
                n.update(s.copyWith(profileVisibility: v));
              },
            ),
          ),
          const SettingsSection(title: 'Who can message me'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: s.whoCanMessage,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Who can message me',
              ),
              items: const [
                DropdownMenuItem(
                    value: 'everyone',
                    child: Text('Everyone')),
                DropdownMenuItem(
                    value: 'contacts',
                    child: Text('People I chat with')),
              ],
              onChanged: (v) {
                if (v == null) return;
                n.update(s.copyWith(whoCanMessage: v));
              },
            ),
          ),
          const SettingsSection(title: 'Blocked users'),
          blocked.when(
            data: (ids) {
              if (ids.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No blocked users.'),
                );
              }
              return Column(
                children:
                    ids.map((id) => _BlockedRow(userId: id)).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Could not load blocked users: $e'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Chats travel over TLS and are protected by Supabase auth + Row Level Security. They are NOT end-to-end encrypted.',
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedRow extends ConsumerWidget {
  final String userId;
  const _BlockedRow({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<UserProfile?>(
      future: ChatService.fetchProfile(userId),
      builder: (context, snap) {
        final name = snap.data == null
            ? '${userId.substring(0, 6)}…'
            : '@${snap.data!.username}';
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                snap.data?.avatarUrl?.isNotEmpty == true
                    ? CachedNetworkImageProvider(
                        snap.data!.avatarUrl!)
                    : null,
            onBackgroundImageError: (_, _) {},
            child: snap.data?.avatarUrl?.isNotEmpty == true
                ? null
                : Text((snap.data?.username ?? '?')[0]
                    .toUpperCase()),
          ),
          title: Text(name),
          trailing: TextButton(
            onPressed: () async {
              try {
                await SupabaseService.client
                    .from('blocked_users')
                    .delete()
                    .eq('user_id',
                        SupabaseService.client.auth.currentUser!.id)
                    .eq('blocked_user_id', userId);
                ref.invalidate(blockedUsersProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Unblock'),
          ),
        );
      },
    );
  }
}
