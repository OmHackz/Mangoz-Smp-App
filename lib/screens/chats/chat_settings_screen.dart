import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../widgets/settings_widgets.dart';

/// Per-chat settings: link previews + media auto-download.
class ChatSettingsScreen extends ConsumerWidget {
  final String conversationId;
  const ChatSettingsScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat settings')),
      body: ListView(
        children: [
          const SettingsSection(title: 'This conversation'),
          SettingsTile(
            icon: Icons.link_outlined,
            title: 'Link previews',
            subtitle: settings.linkPreviewsEnabled
                ? 'Rich cards for URLs'
                : 'Plain URLs only',
            trailing: Switch(
              value: settings.linkPreviewsEnabled,
              onChanged: (v) => notifier.update(
                  settings.copyWith(linkPreviewsEnabled: v)),
            ),
          ),
          SettingsTile(
            icon: Icons.download_outlined,
            title: 'Media auto-download',
            subtitle: settings.mediaAutoDownload
                ? 'Images load automatically'
                : 'Manual load',
            trailing: Switch(
              value: settings.mediaAutoDownload,
              onChanged: (v) => notifier.update(
                  settings.copyWith(mediaAutoDownload: v)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Chat ID: $conversationId',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
