import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/server_config.dart';
import '../../providers/app_providers.dart';
import '../../services/map_service.dart';

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
    FocusScope.of(context).unfocus();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Server')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Java Edition',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
              controller: _javaHost,
              decoration: const InputDecoration(
                  labelText: 'Java host',
                  border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
              controller: _javaPort,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Java port',
                  border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Text('Bedrock Edition',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
              controller: _bedrockHost,
              decoration: const InputDecoration(
                  labelText: 'Bedrock host',
                  border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
              controller: _bedrockPort,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Bedrock port',
                  border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Text('Live map',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
              controller: _mapUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: 'Map URL (http or https)',
                  border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
              controller: _interval,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Refresh interval (seconds, min 15)',
                  border: OutlineInputBorder())),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: scheme.error)),
          ],
          if (_saved != null) ...[
            const SizedBox(height: 8),
            Text(_saved!,
                style: TextStyle(color: Colors.green.shade700)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _saving
                ? null
                : () {
                    setState(() {
                      _javaHost.text = 'mangozsmp.seedloaf.gg';
                      _javaPort.text = '56928';
                      _bedrockHost.text =
                          'mangozsmp.seedloaf.gg';
                      _bedrockPort.text = '54992';
                      _mapUrl.text =
                          'http://mangozsmp.seedloaf.gg:51260';
                      _interval.text = '60';
                    });
                    _save();
                  },
            child: const Text('Reset to defaults'),
          ),
        ],
      ),
    );
  }
}
