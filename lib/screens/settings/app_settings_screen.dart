import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/app_config.dart';
import '../../services/supabase_service.dart';
import '../../widgets/ore_setting_tile.dart';

/// App info + licenses + debug. Tap version 7x to unlock Minesweeper.
class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() =>
      _AppSettingsScreenState();
}

class _AppSettingsScreenState
    extends ConsumerState<AppSettingsScreen> {
  int _taps = 0;
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((v) => mounted ? setState(() => _info = v) : null)
        .catchError((_) => null);
  }

  void _onVersionTap() {
    setState(() => _taps++);
    if (_taps >= AppConfig.minesweeperTapThreshold) {
      setState(() => _taps = 0);
      Navigator.of(context).pushNamed('/minesweeper');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⛏ Secret unlocked: Minesweeper!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    final version =
        _info == null ? AppConfig.appVersion : _info!.version;
    final build =
        _info == null ? '${AppConfig.appBuildNumber}' : _info!.buildNumber;

    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Text('App', style: ore.typography.choiceTitle),
      ),
      body: ListView(
        children: [
          OreCard(
            margin: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MangoZ SMP', style: ore.typography.choiceTitle),
                Text('Community hub for the MangoZ SMP server.',
                    style: ore.typography.body),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _onVersionTap,
                  child: Text('Version $version+$build',
                      style: ore.typography.caption),
                ),
              ],
            ),
          ),
          OreSettingTile(
            icon: Icons.article_outlined,
            title: 'About',
            subtitle: 'What MangoZ SMP does',
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('About MangoZ SMP'),
                content: const Text(
                    'Chats, live map, and server status for the MangoZ SMP Minecraft community.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close')),
                ],
              ),
            ),
          ),
          OreSettingTile(
            icon: Icons.description_outlined,
            title: 'Licenses',
            subtitle: 'Open-source attributions',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'MangoZ SMP',
              applicationVersion: '$version+$build',
            ),
          ),
          const OreSectionHeader(title: 'Debug'),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OreCard(
              child: SelectableText(
                'Supabase configured: ${SupabaseService.isConfigured}\n'
                'kDebugMode: $kDebugMode\n'
                'Ore UI: oreui_flutter (Minecraft aesthetic, unofficial)',
                style: ore.typography.caption.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
