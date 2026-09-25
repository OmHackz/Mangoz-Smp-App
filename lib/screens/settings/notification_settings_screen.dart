import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../widgets/settings_widgets.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    Widget toggle({
      required IconData icon,
      required String title,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return SettingsTile(
        icon: icon,
        title: title,
        subtitle: value ? 'On' : 'Off',
        trailing:
            Switch(value: value, onChanged: onChanged),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          toggle(
            icon: Icons.chat_bubble_outline,
            title: 'Direct messages',
            value: s.chatNotifications,
            onChanged: (v) =>
                n.update(s.copyWith(chatNotifications: v)),
          ),
          toggle(
            icon: Icons.group_outlined,
            title: 'Groups',
            value: s.groupNotifications,
            onChanged: (v) =>
                n.update(s.copyWith(groupNotifications: v)),
          ),
          toggle(
            icon: Icons.dns_outlined,
            title: 'Server status',
            value: s.serverNotifications,
            onChanged: (v) =>
                n.update(s.copyWith(serverNotifications: v)),
          ),
          const SettingsSection(title: 'Feedback'),
          toggle(
            icon: Icons.volume_up_outlined,
            title: 'Message sounds',
            value: s.messageSounds,
            onChanged: (v) =>
                n.update(s.copyWith(messageSounds: v)),
          ),
          toggle(
            icon: Icons.vibration,
            title: 'Vibration',
            value: s.vibration,
            onChanged: (v) =>
                n.update(s.copyWith(vibration: v)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Push delivery needs a backend push service. These toggles control in-app sounds, badges and server alerts.',
            ),
          ),
        ],
      ),
    );
  }
}
