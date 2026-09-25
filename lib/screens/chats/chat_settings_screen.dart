import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../providers/app_providers.dart';
import '../../widgets/ore_setting_tile.dart';

/// Per-chat settings: link previews, media auto-download, mute.
class ChatSettingsScreen extends ConsumerWidget {
  final String conversationId;
  const ChatSettingsScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ore = OreTheme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title:
            Text('Chat settings', style: ore.typography.choiceTitle),
      ),
      body: ListView(
        children: [
          const OreSectionHeader(title: 'This conversation'),
          OreSettingTile(
            icon: Icons.link,
            title: 'Link previews',
            subtitle: settings.linkPreviewsEnabled
                ? 'Rich cards for URLs'
                : 'Plain URLs only',
            trailing: OreSwitch(
              value: settings.linkPreviewsEnabled,
              onChanged: (v) => notifier.update(
                  settings.copyWith(linkPreviewsEnabled: v)),
            ),
          ),
          OreSettingTile(
            icon: Icons.download,
            title: 'Media auto-download',
            subtitle: settings.mediaAutoDownload
                ? 'Images load automatically'
                : 'Tap to load images',
            trailing: OreSwitch(
              value: settings.mediaAutoDownload,
              onChanged: (v) => notifier.update(
                  settings.copyWith(mediaAutoDownload: v)),
            ),
          ),
          const OreSectionHeader(title: 'About'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Chat ID: $conversationId\nMute and wallpaper settings sync with global Chat settings.',
              style: ore.typography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
