import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../providers/app_providers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/ore_button.dart';
import '../../widgets/server_status_card.dart';

/// Dedicated server page: Java + Bedrock status, players, ping, MOTD.
class ServerScreen extends ConsumerWidget {
  const ServerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ore = OreTheme.of(context);
    final status = ref.watch(serverStatusProvider);
    final config = ref.watch(serverConfigProvider);

    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title:
            Text('MangoZ SMP', style: ore.typography.choiceTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: status.loading
                ? null
                : () =>
                    ref.read(serverStatusProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(serverStatusProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            OreCard(
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
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
                  Text(
                    status.loading
                        ? 'CHECKING…'
                        : status.anyOnline
                            ? '● ONLINE'
                            : '● OFFLINE',
                    style: ore.typography.choiceTitle.copyWith(
                      color: status.anyOnline
                          ? ore.colors.success
                          : ore.colors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            if (!status.anyOnline && !status.loading)
              const ErrorView(
                title: 'Server Offline',
                message: 'MangoZ SMP is currently unreachable.',
              ),
            const SizedBox(height: 10),
            MangoOreButton.primary(
              label: 'Refresh Status',
              onPressed: status.loading
                  ? null
                  : () => ref
                      .read(serverStatusProvider.notifier)
                      .refresh(),
              isLoading: status.loading,
              fullWidth: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: MangoOreButton(
                    onPressed: () => _copy(context,
                        '${config.javaHost}:${config.javaPort}'),
                    fullWidth: true,
                    child: const Text('Copy Java IP'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MangoOreButton(
                    onPressed: () => _copy(context,
                        '${config.bedrockHost}:${config.bedrockPort}'),
                    fullWidth: true,
                    child: const Text('Copy Bedrock IP'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last check: ${_lastChecked(status.java?.lastChecked, status.bedrock?.lastChecked)}',
              style: ore.typography.caption,
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

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $text')),
    );
  }
}
