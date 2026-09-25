import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

/// Square-ish Minecraft-style avatar with pixel border.
class PlayerAvatar extends StatelessWidget {
  final String? imageUrl;
  final String username;
  final double size;
  final bool showOnlineDot;
  final bool isOnline;

  const PlayerAvatar({
    super.key,
    this.imageUrl,
    required this.username,
    this.size = 48,
    this.showOnlineDot = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    final initial =
        username.isEmpty ? '?' : username[0].toUpperCase();
    Widget inner;
    if (imageUrl?.isNotEmpty == true) {
      inner = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: size,
          height: size,
          color: ore.colors.surfaceDark,
          alignment: Alignment.center,
          child: Text(initial,
              style: ore.typography.choiceTitle
                  .copyWith(color: ore.colors.textPrimary)),
        ),
        errorWidget: (_, _, _) => Container(
          width: size,
          height: size,
          color: ore.colors.surfaceDark,
          alignment: Alignment.center,
          child: Text(initial,
              style: ore.typography.choiceTitle
                  .copyWith(color: ore.colors.textPrimary)),
        ),
      );
    } else {
      inner = Container(
        width: size,
        height: size,
        color: ore.colors.surfaceDark,
        alignment: Alignment.center,
        child: Text(initial,
            style: ore.typography.choiceTitle
                .copyWith(color: ore.colors.textPrimary)),
      );
    }

    final framed = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ore.colors.surfaceDark,
        border: Border.all(
            color: ore.colors.border, width: ore.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: inner,
    );

    if (!showOnlineDot) return framed;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        framed,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isOnline ? ore.colors.success : ore.colors.textMuted,
              border: Border.all(
                  color: ore.colors.border, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
