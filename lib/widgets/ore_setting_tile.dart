import 'package:flutter/material.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

/// Ore-styled settings row. Every toggle here is wired to real state.
class OreSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const OreSettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: ore.colors.textPrimary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ore.typography.label),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: ore.typography.caption),
                ],
              ),
            ),
            ?trailing,
            if (trailing == null && onTap != null)
              Icon(Icons.chevron_right,
                  color: ore.colors.textMuted),
          ],
        ),
      ),
    );
  }
}

class OreSectionHeader extends StatelessWidget {
  final String title;
  const OreSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: ore.typography.caption.copyWith(
          color: ore.colors.success,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
