import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../providers/app_providers.dart';
import '../../widgets/ore_setting_tile.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ore = OreTheme.of(context);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    Widget toggle({
      required IconData icon,
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return OreSettingTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing:
            OreSwitch(value: value, onChanged: onChanged),
      );
    }

    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Text('Notifications',
            style: ore.typography.choiceTitle),
      ),
      body: ListView(
        children: [
          toggle(
            icon: Icons.chat_bubble_outline,
            title: 'Direct message notifications',
            subtitle: s.chatNotifications ? 'On' : 'Off',
            value: s.chatNotifications,
            onChanged: (v) =>
                n.update(s.copyWith(chatNotifications: v)),
          ),
          toggle(
            icon: Icons.group_outlined,
            title: 'Group notifications',
            subtitle: s.groupNotifications ? 'On' : 'Off',
            value: s.groupNotifications,
            onChanged: (v) =>
                n.update(s.copyWith(groupNotifications: v)),
          ),
          toggle(
            icon: Icons.dns_outlined,
            title: 'Server status notifications',
            subtitle: s.serverNotifications ? 'On' : 'Off',
            value: s.serverNotifications,
            onChanged: (v) =>
                n.update(s.copyWith(serverNotifications: v)),
          ),
          const OreSectionHeader(title: 'Feedback'),
          toggle(
            icon: Icons.volume_up_outlined,
            title: 'Message sounds',
            subtitle: s.messageSounds ? 'On' : 'Off',
            value: s.messageSounds,
            onChanged: (v) =>
                n.update(s.copyWith(messageSounds: v)),
          ),
          toggle(
            icon: Icons.vibration,
            title: 'Vibration',
            subtitle: s.vibration ? 'On' : 'Off',
            value: s.vibration,
            onChanged: (v) =>
                n.update(s.copyWith(vibration: v)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Push delivery requires a backend push service. These toggles control in-app sounds, badges and server alerts.',
              style: ore.typography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
