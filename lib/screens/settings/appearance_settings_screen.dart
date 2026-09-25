import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../widgets/settings_widgets.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        children: [
          const SettingsSection(title: 'Theme'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: s.themeMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Theme',
              ),
              items: const [
                DropdownMenuItem(
                    value: 'system', child: Text('System')),
                DropdownMenuItem(
                    value: 'light', child: Text('Light')),
                DropdownMenuItem(
                    value: 'dark', child: Text('Dark')),
              ],
              onChanged: (v) {
                if (v == null) return;
                n.update(s.copyWith(themeMode: v));
              },
            ),
          ),
          const SizedBox(height: 8),
          const SettingsSection(title: 'Preview'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MangoZ SMP ⛏️',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                        'Buttons, cards and switches follow your system Material 3 theme automatically.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
