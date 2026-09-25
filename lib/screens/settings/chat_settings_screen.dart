import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../providers/app_providers.dart';
import '../../widgets/ore_setting_tile.dart';

class ChatSettingsPage extends ConsumerWidget {
  const ChatSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ore = OreTheme.of(context);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Text('Chats', style: ore.typography.choiceTitle),
      ),
      body: ListView(
        children: [
          OreSettingTile(
            icon: Icons.keyboard_return,
            title: 'Enter key sends message',
            subtitle: s.enterToSend ? 'On' : 'Off',
            trailing: OreSwitch(
              value: s.enterToSend,
              onChanged: (v) =>
                  n.update(s.copyWith(enterToSend: v)),
            ),
          ),
          OreSettingTile(
            icon: Icons.download,
            title: 'Media auto-download',
            subtitle: s.mediaAutoDownload
                ? 'Load images automatically'
                : 'Manual load',
            trailing: OreSwitch(
              value: s.mediaAutoDownload,
              onChanged: (v) =>
                  n.update(s.copyWith(mediaAutoDownload: v)),
            ),
          ),
          OreSettingTile(
            icon: Icons.link,
            title: 'Link previews',
            subtitle: s.linkPreviewsEnabled ? 'On' : 'Off',
            trailing: OreSwitch(
              value: s.linkPreviewsEnabled,
              onChanged: (v) =>
                  n.update(s.copyWith(linkPreviewsEnabled: v)),
            ),
          ),
          const OreSectionHeader(title: 'Voice messages'),
          OreSettingTile(
            icon: Icons.mic,
            title: 'Voice messages',
            subtitle: 'Hold mic to record (always available)',
          ),
          const OreSectionHeader(title: 'Message appearance'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Text size: ${s.messageTextScale.toStringAsFixed(1)}x',
                    style: ore.typography.label),
                OreSlider(
                  value: s.messageTextScale,
                  min: 0.8,
                  max: 1.4,
                  onChanged: (v) => n.update(
                      s.copyWith(messageTextScale: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
