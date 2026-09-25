import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../providers/app_providers.dart';
import '../../widgets/chat_tile.dart';

/// MangoZ SMP dashboard: status hero, quick actions, server IP, recents.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final auth = ref.watch(authProvider);
    final status = ref.watch(serverStatusProvider);
    final config = ref.watch(serverConfigProvider);
    final conversations = ref.watch(conversationsProvider);
    final update = ref.watch(updateCheckProvider);
    final username = auth.profile?.username ?? 'player';

    Future<void> refresh() async {
      await ref.read(serverStatusProvider.notifier).refresh();
      ref.invalidate(conversationsProvider);
    }

    final java = status.java;
    final bedrock = status.bedrock;
    final totalOnline =
        (java?.playersOnline ?? 0) + (bedrock?.playersOnline ?? 0);
    final totalMax = (java?.playersMax ?? 0) + (bedrock?.playersMax ?? 0);
    final online = status.anyOnline;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 28,
                height: 28,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.grass),
              ),
            ),
            const SizedBox(width: 8),
            Text(AppConfig.appName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My profile',
            onPressed: () =>
                Navigator.of(context).pushNamed('/profile'),
            icon: _Avatar(
              url: auth.profile?.avatarUrl,
              username: username,
              radius: 16,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Hey, @$username ⛏️', style: text.headlineSmall),
            const SizedBox(height: 2),
            Text(
              online
                  ? '$totalOnline playing right now'
                  : 'The realm is quiet… for now',
              style: text.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Update banner (GitHub releases).
            update.maybeWhen(
              data: (info) => info == null
                  ? const SizedBox.shrink()
                  : Card(
                      color: scheme.tertiaryContainer,
                      child: ListTile(
                        leading: const Icon(
                            Icons.system_update_outlined),
                        title: Text(
                            'Update available: ${info.release.tag}'),
                        subtitle: Text(
                            'You have ${info.currentVersion}'),
                        trailing: TextButton(
                          onPressed: () async {
                            final url = info.release.apkUrl ??
                                info.release.htmlUrl;
                            final uri = Uri.tryParse(url);
                            if (uri == null) return;
                            try {
                              await launchUrl(uri,
                                  mode: LaunchMode
                                      .externalApplication);
                            } catch (_) {}
                          },
                          child: const Text('Update'),
                        ),
                      ),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),

            // Status hero.
            Card(
              color: online
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: status.loading
                            ? scheme.outline
                            : online
                                ? Colors.green.shade600
                                : scheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.loading
                                ? 'Checking server…'
                                : online
                                    ? 'Server online'
                                    : 'Server offline',
                            style: text.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            online && totalMax > 0
                                ? '$totalOnline / $totalMax players'
                                : online
                                    ? 'Players online: $totalOnline'
                                    : 'MangoZ SMP is unreachable',
                            style: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh status',
                      onPressed:
                          status.loading ? null : refresh,
                      icon: status.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                      strokeWidth: 2))
                          : const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('Quick actions', style: text.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.map_outlined,
                  label: 'Live map',
                  onTap: () => Navigator.of(context)
                      .pushNamed('/map'),
                ),
                const SizedBox(width: 8),
                _QuickAction(
                  icon: Icons.dns_outlined,
                  label: 'Status',
                  onTap: () => Navigator.of(context)
                      .pushNamed('/server'),
                ),
                const SizedBox(width: 8),
                _QuickAction(
                  icon: Icons.edit_outlined,
                  label: 'New chat',
                  onTap: () => Navigator.of(context)
                      .pushNamed('/new-chat'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Server IP.
            Card(
              child: Column(
                children: [
                  _IpRow(
                    edition: 'Java',
                    address: config.javaAddress,
                    pingMs: java?.pingMs,
                  ),
                  const Divider(height: 1),
                  _IpRow(
                    edition: 'Bedrock',
                    address: config.bedrockAddress,
                    pingMs: bedrock?.pingMs,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Text('Recent chats', style: text.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed('/chats'),
                  child: const Text('See all'),
                ),
              ],
            ),
            conversations.when(
              data: (chats) {
                if (chats.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No conversations yet — tap New chat to say hello! 👋',
                        style: text.bodyMedium,
                      ),
                    ),
                  );
                }
                final uid = auth.profile?.id ?? '';
                return Card(
                  child: Column(
                    children: chats
                        .take(3)
                        .map((c) => ChatTile(
                              chat: c,
                              currentUserId: uid,
                              onTap: () =>
                                  Navigator.of(context)
                                      .pushNamed('/chat',
                                          arguments: c.id)
                                      .then((_) => ref.invalidate(
                                          conversationsProvider)),
                            ))
                        .toList(),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: const Text('Chats unavailable'),
                  subtitle: Text(e.toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () =>
                        ref.invalidate(conversationsProvider),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status checked ${_lastChecked(java?.lastChecked, bedrock?.lastChecked)} · Not end-to-end encrypted',
              style: text.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _lastChecked(DateTime? a, DateTime? b) {
    final list = [a, b].whereType<DateTime>().toList();
    if (list.isEmpty) return 'never';
    list.sort((x, y) => y.compareTo(x));
    return timeago.format(list.first);
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String username;
  final double radius;

  const _Avatar(
      {required this.url,
      required this.username,
      required this.radius});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial =
        username.isEmpty ? '?' : username[0].toUpperCase();
    if (url?.isNotEmpty == true) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primaryContainer,
        backgroundImage: CachedNetworkImageProvider(url!),
        onBackgroundImageError: (_, _) {},
        child: Text(initial),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(initial,
          style: TextStyle(color: scheme.onPrimaryContainer)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.secondaryContainer,
                  child: Icon(icon,
                      color: scheme.onSecondaryContainer),
                ),
                const SizedBox(height: 6),
                Text(label,
                    style:
                        Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IpRow extends StatelessWidget {
  final String edition;
  final String address;
  final int? pingMs;

  const _IpRow(
      {required this.edition,
      required this.address,
      this.pingMs});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        edition == 'Java' ? Icons.laptop : Icons.phone_android,
        color: scheme.primary,
      ),
      title: Text(edition,
          style: Theme.of(context).textTheme.labelLarge),
      subtitle: SelectableText(address,
          style: const TextStyle(fontFamily: 'monospace')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pingMs != null)
            Text('$pingMs ms',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          IconButton(
            tooltip: 'Copy $edition IP',
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: address));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied $address')),
              );
            },
          ),
        ],
      ),
    );
  }
}
