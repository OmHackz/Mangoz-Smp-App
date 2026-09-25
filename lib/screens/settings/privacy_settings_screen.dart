import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/ore_setting_tile.dart';
import '../../widgets/player_avatar.dart';
import '../../models/user_profile.dart';
import '../../services/chat_service.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ore = OreTheme.of(context);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final blocked = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title:
            Text('Privacy', style: ore.typography.choiceTitle),
      ),
      body: ListView(
        children: [
          OreSettingTile(
            icon: Icons.circle,
            title: 'Show online status',
            subtitle: s.showOnlineStatus
                ? 'Others see you online'
                : 'Hidden',
            trailing: OreSwitch(
              value: s.showOnlineStatus,
              onChanged: (v) =>
                  n.update(s.copyWith(showOnlineStatus: v)),
            ),
          ),
          const OreSectionHeader(title: 'Profile visibility'),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OreDropdownButton<String>(
              value: s.profileVisibility,
              hint: const Text('Who can see my profile'),
              items: const [
                OreDropdownItem(
                    value: 'everyone',
                    child: Text('Everyone')),
                OreDropdownItem(
                    value: 'contacts',
                    child: Text('People I chat with')),
                OreDropdownItem(
                    value: 'nobody', child: Text('Nobody')),
              ],
              onChanged: (v) {
                n.update(s.copyWith(profileVisibility: v));
              },
            ),
          ),
          const OreSectionHeader(title: 'Who can message me'),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OreDropdownButton<String>(
              value: s.whoCanMessage,
              hint: const Text('Who can message me'),
              items: const [
                OreDropdownItem(
                    value: 'everyone',
                    child: Text('Everyone')),
                OreDropdownItem(
                    value: 'contacts',
                    child: Text('People I chat with')),
              ],
              onChanged: (v) {
                n.update(s.copyWith(whoCanMessage: v));
              },
            ),
          ),
          const OreSectionHeader(title: 'Blocked users'),
          blocked.when(
            data: (ids) {
              if (ids.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No blocked users.'),
                );
              }
              return Column(
                children: ids
                    .map((id) => _BlockedRow(userId: id))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: OreLoadingIndicator(size: 28),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Could not load blocked users: $e',
                  style: ore.typography.caption),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Chats are transported over TLS and protected by Supabase auth + Row Level Security. They are NOT end-to-end encrypted.',
              style: ore.typography.caption,
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
    final ore = OreTheme.of(context);
    return FutureBuilder<UserProfile?>(
      future: ChatService.fetchProfile(userId),
      builder: (context, snap) {
        final name = snap.data == null
            ? userId.substring(0, 6)
            : '@${snap.data!.username}';
        return ListTile(
          leading: PlayerAvatar(
            username: snap.data?.username ?? '?',
            imageUrl: snap.data?.avatarUrl,
            size: 40,
          ),
          title: Text(name, style: ore.typography.label),
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
