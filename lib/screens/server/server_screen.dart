import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/server_status.dart';
import '../../providers/app_providers.dart';

/// Dedicated server page: Java + Bedrock status, players, ping, MOTD.
class ServerScreen extends ConsumerWidget {
  const ServerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final status = ref.watch(serverStatusProvider);
    final config = ref.watch(serverConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MangoZ SMP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: status.loading
                ? null
                : () => ref
                    .read(serverStatusProvider.notifier)
                    .refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(serverStatusProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: status.loading
                  ? scheme.surfaceContainerHighest
                  : status.anyOnline
                      ? scheme.primaryContainer
                      : scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      status.anyOnline
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 32,
                      color: status.loading
                          ? scheme.onSurfaceVariant
                          : status.anyOnline
                              ? Colors.green.shade700
                              : scheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.loading
                                ? 'Checking…'
                                : status.anyOnline
                                    ? 'Online'
                                    : 'Offline',
                            style: text.headlineSmall,
                          ),
                          Text(
                            'Java + Bedrock status below',
                            style: text.bodyMedium?.copyWith(
                                color:
                                    scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _EditionCard(
              title: 'Java Edition',
              address: config.javaAddress,
              status: status.java,
              loading: status.loading && status.java == null,
            ),
            const SizedBox(height: 8),
            _EditionCard(
              title: 'Bedrock Edition',
              address: config.bedrockAddress,
              status: status.bedrock,
              loading: status.loading && status.bedrock == null,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: status.loading
                  ? null
                  : () => ref
                      .read(serverStatusProvider.notifier)
                      .refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh status'),
            ),
            Text(
              'Last check: ${_lastChecked(status.java?.lastChecked, status.bedrock?.lastChecked)}',
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

class _EditionCard extends StatelessWidget {
  final String title;
  final String address;
  final ServerStatus? status;
  final bool loading;

  const _EditionCard({
    required this.title,
    required this.address,
    required this.status,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final online = status?.online ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(title,
                        style: text.titleLarge)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: loading
                        ? scheme.surfaceContainerHighest
                        : online
                            ? Colors.green.shade100
                            : scheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    loading
                        ? '…'
                        : online
                            ? 'ONLINE'
                            : 'OFFLINE',
                    style: text.labelMedium?.copyWith(
                      color: loading
                          ? scheme.onSurfaceVariant
                          : online
                              ? Colors.green.shade900
                              : scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(address,
                      style: const TextStyle(
                          fontFamily: 'monospace')),
                ),
                IconButton(
                  tooltip: 'Copy address',
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Copied $address')),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (online) ...[
              _statRow(Icons.group_outlined, 'Players',
                  status!.playersLabel),
              _statRow(Icons.speed_outlined, 'Ping',
                  status!.pingLabel.replaceFirst('Ping: ', '')),
              if (status!.version?.isNotEmpty == true)
                _statRow(Icons.tag_outlined, 'Version',
                    status!.version!),
              if (status!.motd?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(status!.motd!,
                      style: text.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ),
            ] else ...[
              _statRow(Icons.cloud_off_outlined, 'Status',
                  status?.error ?? 'Unable to connect'),
              Text('MangoZ SMP is currently unreachable.',
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            SizedBox(
                width: 64,
                child: Text(label,
                    style:
                        Theme.of(context).textTheme.bodySmall)),
            Expanded(
                child: Text(value,
                    style:
                        Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
    });
  }
}
