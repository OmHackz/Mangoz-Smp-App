import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/app_config.dart';
import '../../providers/app_providers.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/ore_button.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/server_status_card.dart';

/// MangoZ SMP dashboard: branding, server status, quick access, recents.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ore = OreTheme.of(context);
    final auth = ref.watch(authProvider);
    final status = ref.watch(serverStatusProvider);
    final config = ref.watch(serverConfigProvider);
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ore.colors.accent,
                border: Border.all(
                    color: ore.colors.border, width: 2),
              ),
              alignment: Alignment.center,
              child: Text('M',
                  style: ore.typography.label.copyWith(
                      color: ore.colors.textInverse)),
            ),
            const SizedBox(width: 8),
            Text(AppConfig.appName, style: ore.typography.choiceTitle),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PlayerAvatar(
              username: auth.profile?.username ?? '?',
              imageUrl: auth.profile?.avatarUrl,
              size: 36,
              showOnlineDot: true,
              isOnline: true,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(serverStatusProvider.notifier).refresh();
          ref.invalidate(conversationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Status banner
            OreCard(
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: status.loading
                          ? ore.colors.warning
                          : status.anyOnline
                              ? ore.colors.success
                              : ore.colors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: ore.colors.border, width: 2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.loading
                              ? 'Checking server…'
                              : status.anyOnline
                                  ? '● ONLINE'
                                  : '● OFFLINE',
                          style: ore.typography.label.copyWith(
                            color: status.anyOnline
                                ? ore.colors.success
                                : ore.colors.danger,
                          ),
                        ),
                        Text(
                          'Java ${config.javaAddress} · Bedrock ${config.bedrockAddress}',
                          style: ore.typography.caption,
                        ),
                      ],
                    ),
                  ),
                  MangoOreButton(
                    onPressed: status.loading
                        ? null
                        : () => ref
                            .read(serverStatusProvider.notifier)
                            .refresh(),
                    size: OreButtonSize.sm,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Java / Bedrock cards
            ServerStatusCard(
              title: 'Java Edition',
              address: config.javaAddress,
              status: status.java,
              loading: status.loading && status.java == null,
            ),
            const SizedBox(height: 8),
            ServerStatusCard(
              title: 'Bedrock Edition',
              address: config.bedrockAddress,
              status: status.bedrock,
              loading: status.loading && status.bedrock == null,
            ),
            const SizedBox(height: 12),
            // Quick access
            Row(
              children: [
                Expanded(
                  child: MangoOreButton.primary(
                    label: 'Open Chats',
                    onPressed: () {
                      // MainShell navigation is index-based; chats list
                      // handles its own routing.
                      Navigator.of(context).pushNamed('/chats');
                    },
                    fullWidth: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MangoOreButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/map'),
                    fullWidth: true,
                    child: const Text('Live Map'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OreCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Server IP', style: ore.typography.label),
                  const SizedBox(height: 4),
                  SelectableText(
                    'Java: ${config.javaAddress}\nBedrock: ${config.bedrockAddress}',
                    style: ore.typography.body.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Recent conversations',
                style: ore.typography.choiceTitle),
            const SizedBox(height: 6),
            conversations.when(
              data: (chats) {
                if (chats.isEmpty) {
                  return OreCard(
                    child: Text(
                      'No conversations yet. Start a chat from the Chats tab.',
                      style: ore.typography.body,
                    ),
                  );
                }
                final recent = chats.take(5).toList();
                final uid = auth.profile?.id ?? '';
                return Column(
                  children: recent
                      .map((c) => OreCard(
                            padding: EdgeInsets.zero,
                            child: ChatTile(
                              chat: c,
                              currentUserId: uid,
                              onTap: () => Navigator.of(context)
                                  .pushNamed('/chat',
                                      arguments: c.id),
                            ),
                          ))
                      .toList(),
                );
              },
              loading: () => const LoadingView(message: 'Loading chats…'),
              error: (e, _) => ErrorView(
                title: 'Chats unavailable',
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(conversationsProvider),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last status check: ${_lastChecked(status.java?.lastChecked, status.bedrock?.lastChecked)}',
              style: ore.typography.caption,
            ),
          ],
        ),
      ),
    );
  }

  String _lastChecked(DateTime? a, DateTime? b) {
    final latest = [a, b].whereType<DateTime>().fold<DateTime?>(
        null, (prev, e) => prev == null || e.isAfter(prev) ? e : prev);
    if (latest == null) return 'never';
    return timeago.format(latest);
  }
}
