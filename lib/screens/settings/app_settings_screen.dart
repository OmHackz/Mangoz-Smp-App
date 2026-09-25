import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../services/supabase_service.dart';
import '../../services/update_service.dart';
import '../../widgets/settings_widgets.dart';

/// App info + update checker + licenses + debug.
/// Tip: tap the version 7 times. ⛏️
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
  bool _checking = false;

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
        const SnackBar(
            content: Text('⛏️ Secret unlocked: Minesweeper!')),
      );
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    try {
      final info =
          await UpdateService.checkForUpdate(force: true);
      if (!mounted) return;
      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You\'re up to date. ✅')),
        );
        return;
      }
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.system_update_outlined),
          title: Text('Update available: ${info.release.tag}'),
          content: Text(
            'You have ${info.currentVersion}.\n\n${(info.release.notes ?? '').trim().isEmpty ? 'A newer build is ready on GitHub.' : info.release.notes!.trim()}',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Later')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Download')),
          ],
        ),
      );
      if (open == true) {
        final url =
            info.release.apkUrl ?? info.release.htmlUrl;
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        try {
          await launchUrl(uri,
              mode: LaunchMode.externalApplication);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Could not open download link.')),
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final version =
        _info == null ? AppConfig.appVersion : _info!.version;
    final build =
        _info == null ? '${AppConfig.appBuildNumber}' : _info!.buildNumber;

    return Scaffold(
      appBar: AppBar(title: const Text('App')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 48,
                            height: 48,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.grass,
                                    size: 40),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('MangoZ SMP',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge),
                              GestureDetector(
                                onTap: _onVersionTap,
                                child: Text(
                                  'Version $version+$build',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Community hub for the MangoZ SMP server.',
                      style:
                          Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SettingsTile(
            icon: Icons.system_update_outlined,
            title: 'Check for updates',
            subtitle: _checking
                ? 'Checking…'
                : 'Compare with GitHub releases',
            trailing: _checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: _checking ? null : _checkForUpdates,
          ),
          SettingsTile(
            icon: Icons.article_outlined,
            title: 'About',
            subtitle: 'What MangoZ SMP does',
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => const AlertDialog(
                title: Text('About MangoZ SMP'),
                content: Text(
                    'Chats, live map, and server status for the MangoZ SMP Minecraft community.'),
              ),
            ),
          ),
          SettingsTile(
            icon: Icons.description_outlined,
            title: 'Licenses',
            subtitle: 'Open-source attributions',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'MangoZ SMP',
              applicationVersion: '$version+$build',
            ),
          ),
          const SettingsSection(title: 'Debug'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  'Supabase configured: ${SupabaseService.isConfigured}\n'
                  'kDebugMode: $kDebugMode\n'
                  'Chats use TLS + Row Level Security (not end-to-end encrypted).',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
