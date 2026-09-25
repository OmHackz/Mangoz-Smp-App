import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../providers/app_providers.dart';
import '../../widgets/ore_setting_tile.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ore = OreTheme.of(context);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title:
            Text('Appearance', style: ore.typography.choiceTitle),
      ),
      body: ListView(
        children: [
          const OreSectionHeader(title: 'Theme'),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OreDropdownButton<String>(
              value: s.themeMode,
              hint: const Text('Theme'),
              items: const [
                OreDropdownItem(
                    value: 'system', child: Text('System')),
                OreDropdownItem(
                    value: 'light', child: Text('Light')),
                OreDropdownItem(
                    value: 'dark', child: Text('Dark')),
              ],
              onChanged: (v) {
                n.update(s.copyWith(themeMode: v));
              },
            ),
          ),
          OreSettingTile(
            icon: Icons.texture,
            title: 'High Ore intensity',
            subtitle: s.oreIntensityHigh
                ? 'Full bevels + shadows'
                : 'Flatter surfaces',
            trailing: OreSwitch(
              value: s.oreIntensityHigh,
              onChanged: (v) =>
                  n.update(s.copyWith(oreIntensityHigh: v)),
            ),
          ),
          const OreSectionHeader(title: 'Preview'),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OreCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MangoZ SMP',
                      style: ore.typography.choiceTitle),
                  const SizedBox(height: 4),
                  Text(
                    'Ore UI buttons, cards and switches adapt to light/dark automatically.',
                    style: ore.typography.body.copyWith(
                      fontSize: 14 * s.messageTextScale,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
