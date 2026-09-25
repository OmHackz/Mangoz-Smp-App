import 'package:flutter/material.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../models/server_status.dart';

/// Ore-styled server status card for one edition.
class ServerStatusCard extends StatelessWidget {
  final String title;
  final String address;
  final ServerStatus? status;
  final bool loading;

  const ServerStatusCard({
    super.key,
    required this.title,
    required this.address,
    required this.status,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    final online = status?.online ?? false;
    final dotColor =
        loading ? ore.colors.warning : (online ? ore.colors.success : ore.colors.danger);
    final statusText = loading
        ? 'Checking…'
        : (online ? 'ONLINE' : 'OFFLINE');

    return OreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  border: Border.all(color: ore.colors.border, width: 1.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: ore.typography.choiceTitle),
              ),
              Text(
                statusText,
                style: ore.typography.label.copyWith(
                  color: online && !loading
                      ? ore.colors.success
                      : ore.colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(address,
              style: ore.typography.caption.copyWith(
                  fontFamily: 'monospace',
                  color: ore.colors.textMuted)),
          const SizedBox(height: 8),
          if (loading)
            const OreLoadingIndicator(size: 28)
          else if (status != null && status!.online) ...[
            Text(status!.playersLabel, style: ore.typography.body),
            const SizedBox(height: 2),
            Text(status!.pingLabel, style: ore.typography.body),
            if (status!.version?.isNotEmpty == true)
              Text('Version: ${status!.version}',
                  style: ore.typography.caption),
            if (status!.motd?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(status!.motd!,
                    style: ore.typography.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
          ] else ...[
            Text(
              status?.error ?? 'Unable to connect',
              style: ore.typography.body
                  .copyWith(color: ore.colors.danger),
            ),
            Text('MangoZ SMP is currently unreachable.',
                style: ore.typography.caption),
          ],
        ],
      ),
    );
  }
}
