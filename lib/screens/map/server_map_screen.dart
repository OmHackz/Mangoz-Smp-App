import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../providers/app_providers.dart';
import '../../services/map_service.dart';
import '../../widgets/loading_error.dart';

/// Fullscreen live server map in a WebView. Supports HTTP + HTTPS.
/// Requires Android cleartext permission (see AndroidManifest).
class ServerMapScreen extends ConsumerStatefulWidget {
  const ServerMapScreen({super.key});

  @override
  ConsumerState<ServerMapScreen> createState() => _ServerMapScreenState();
}

class _ServerMapScreenState extends ConsumerState<ServerMapScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;
  bool _canBack = false;
  bool _canForward = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final config = ref.read(serverConfigProvider);
    final url = MapService.normalize(config.mapUrl);
    final err = MapService.validate(url);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setBackgroundColor(Colors.transparent);
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) {
            setState(() {
              _loading = true;
              _error = null;
            });
          }
        },
        onPageFinished: (_) async {
          if (!mounted) return;
          setState(() => _loading = false);
          try {
            final back = await controller.canGoBack();
            final fwd = await controller.canGoForward();
            if (mounted) {
              setState(() {
                _canBack = back;
                _canForward = fwd;
              });
            }
          } catch (_) {}
        },
        onWebResourceError: (e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error =
                'Map unavailable (${e.errorCode}): ${e.description}\nCheck Settings → Server → Map URL.';
          });
        },
      ),
    );
    controller.loadRequest(MapService.toUri(url));
    setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    final config = ref.watch(serverConfigProvider);
    ref.listen(serverConfigProvider, (prev, next) {
      if (prev?.mapUrl != next.mapUrl) _init();
    });

    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Text('Server Map', style: ore.typography.choiceTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: (_controller != null && _canBack)
                ? () => _controller!.goBack()
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: (_controller != null && _canForward)
                ? () => _controller!.goForward()
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _controller == null ? null : () => _controller!.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final uri = Uri.tryParse(
                  MapService.normalize(config.mapUrl));
              if (uri == null) return;
              try {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_error != null && _controller == null) {
            return ErrorView(
              title: 'Map Unavailable',
              message:
                  'The server map could not be loaded.\n$_error',
              onRetry: () {
                setState(() => _error = null);
                _init();
              },
            );
          }
          if (_controller == null) {
            return const LoadingView(message: 'Preparing map…');
          }
          return Stack(
            children: [
              WebViewWidget(controller: _controller!),
              if (_loading)
                Container(
                  color: ore.colors.background.withValues(alpha: 0.7),
                  child: const LoadingView(
                      message: 'Loading live map…'),
                ),
              if (_error != null && !_loading)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: OreCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_error!,
                              style: ore.typography.caption),
                        ),
                        TextButton(
                          onPressed: () => _controller!.reload(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
