import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../config/server_config.dart';
import '../../providers/app_providers.dart';
import '../../services/map_service.dart';
import '../../widgets/ore_button.dart';

class ServerSettingsScreen extends ConsumerStatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  ConsumerState<ServerSettingsScreen> createState() =>
      _ServerSettingsScreenState();
}

class _ServerSettingsScreenState
    extends ConsumerState<ServerSettingsScreen> {
  late final TextEditingController _javaHost;
  late final TextEditingController _javaPort;
  late final TextEditingController _bedrockHost;
  late final TextEditingController _bedrockPort;
  late final TextEditingController _mapUrl;
  late final TextEditingController _interval;
  bool _saving = false;
  String? _error;
  String? _saved;

  @override
  void initState() {
    super.initState();
    final c = ref.read(serverConfigProvider);
    _javaHost = TextEditingController(text: c.javaHost);
    _javaPort = TextEditingController(text: '${c.javaPort}');
    _bedrockHost = TextEditingController(text: c.bedrockHost);
    _bedrockPort = TextEditingController(text: '${c.bedrockPort}');
    _mapUrl = TextEditingController(text: c.mapUrl);
    _interval = TextEditingController(
        text: '${c.statusRefreshInterval.inSeconds}');
  }

  @override
  void dispose() {
    _javaHost.dispose();
    _javaPort.dispose();
    _bedrockHost.dispose();
    _bedrockPort.dispose();
    _mapUrl.dispose();
    _interval.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _saved = null;
    });
    final config = ServerConfig(
      javaHost: _javaHost.text.trim(),
      javaPort: int.tryParse(_javaPort.text.trim()) ?? -1,
      bedrockHost: _bedrockHost.text.trim(),
      bedrockPort: int.tryParse(_bedrockPort.text.trim()) ?? -1,
      mapUrl: MapService.normalize(_mapUrl.text),
      statusRefreshInterval: Duration(
          seconds: int.tryParse(_interval.text.trim()) ?? 60),
    );
    final err = await ref
        .read(serverConfigProvider.notifier)
        .update(config);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (err != null) {
        _error = err;
      } else {
        _saved = 'Saved. Status will refresh automatically.';
      }
    });
    if (err == null) {
      ref.read(serverStatusProvider.notifier).refresh();
    }
  }

  Future<void> _reset() async {
    setState(() {
      _javaHost.text = 'mangozsmp.seedloaf.gg';
      _javaPort.text = '56928';
      _bedrockHost.text = 'mangozsmp.seedloaf.gg';
      _bedrockPort.text = '54992';
      _mapUrl.text = 'http://mangozsmp.seedloaf.gg:51260';
      _interval.text = '60';
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Text('Server', style: ore.typography.choiceTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Java Edition', style: ore.typography.label),
          const SizedBox(height: 6),
          OreTextField(controller: _javaHost, hintText: 'Java host'),
          const SizedBox(height: 8),
          OreTextField(
              controller: _javaPort,
              hintText: 'Java port',
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Text('Bedrock Edition', style: ore.typography.label),
          const SizedBox(height: 6),
          OreTextField(
              controller: _bedrockHost, hintText: 'Bedrock host'),
          const SizedBox(height: 8),
          OreTextField(
              controller: _bedrockPort,
              hintText: 'Bedrock port',
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Text('Map URL (http or https)',
              style: ore.typography.label),
          const SizedBox(height: 6),
          OreTextField(
              controller: _mapUrl, hintText: 'http://host:port'),
          const SizedBox(height: 12),
          Text('Status refresh interval (seconds, min 15)',
              style: ore.typography.label),
          const SizedBox(height: 6),
          OreTextField(
              controller: _interval,
              hintText: '60',
              keyboardType: TextInputType.number),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: ore.typography.body
                    .copyWith(color: ore.colors.danger)),
          ],
          if (_saved != null) ...[
            const SizedBox(height: 8),
            Text(_saved!,
                style: ore.typography.body
                    .copyWith(color: ore.colors.success)),
          ],
          const SizedBox(height: 16),
          MangoOreButton.primary(
            label: 'Save',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            fullWidth: true,
          ),
          const SizedBox(height: 8),
          MangoOreButton(
            onPressed: _saving ? null : _reset,
            fullWidth: true,
            child: const Text('Reset to defaults'),
          ),
        ],
      ),
    );
  }
}
