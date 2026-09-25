import 'package:flutter/material.dart';
import 'package:oreui_flutter/oreui_flutter.dart';
import 'ore_button.dart';

/// Consistent loading / empty / error states. Never a blank screen.
class LoadingView extends StatelessWidget {
  final String message;
  const LoadingView({super.key, this.message = 'Loading…'});

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OreLoadingIndicator(size: 48),
          const SizedBox(height: 12),
          Text(message, style: ore.typography.body),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyView({
    super.key,
    required this.title,
    this.subtitle = '',
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: ore.colors.textMuted),
            const SizedBox(height: 12),
            Text(title,
                style: ore.typography.choiceTitle,
                textAlign: TextAlign.center),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  style: ore.typography.body,
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.title = 'Unable to connect',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off,
                size: 48, color: ore.colors.danger),
            const SizedBox(height: 12),
            Text(title,
                style: ore.typography.choiceTitle,
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              message,
              style: ore.typography.body,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              MangoOreButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
