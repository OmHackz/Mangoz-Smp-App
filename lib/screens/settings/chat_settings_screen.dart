import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../widgets/settings_widgets.dart';

class ChatSettingsPage extends ConsumerWidget {
  const ChatSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: ListView(
        children: [
          SettingsTile(
            icon: Icons.download_outlined,
            title: 'Media auto-download',
            subtitle: s.mediaAutoDownload
                ? 'Load images automatically'
                : 'Manual load',
            trailing: Switch(
              value: s.mediaAutoDownload,
              onChanged: (v) =>
                  n.update(s.copyWith(mediaAutoDownload: v)),
            ),
          ),
          SettingsTile(
            icon: Icons.link_outlined,
            title: 'Link previews',
            subtitle: s.linkPreviewsEnabled ? 'On' : 'Off',
            trailing: Switch(
              value: s.linkPreviewsEnabled,
              onChanged: (v) =>
                  n.update(s.copyWith(linkPreviewsEnabled: v)),
            ),
          ),
          const SettingsSection(title: 'Message appearance'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Text size: ${s.messageTextScale.toStringAsFixed(1)}×'),
                Slider(
                  value: s.messageTextScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  label:
                      '${s.messageTextScale.toStringAsFixed(1)}×',
                  onChanged: (v) => n.update(
                      s.copyWith(messageTextScale: v)),
                ),
                const SizedBox(height: 8),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                        'The quick brown fox jumps over the lazy dog. ⛏️'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
