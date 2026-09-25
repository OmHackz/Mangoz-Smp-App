import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oreui_flutter/oreui_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/message.dart';
import 'link_preview.dart';
import 'voice_bubble.dart';

final _timeFormat = DateFormat('HH:mm');

/// Single chat bubble — Ore-styled but familiar and readable.
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool showSender;
  final bool linkPreviewsEnabled;
  final double textScale;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final void Function(Message)? onTapImage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showSender = false,
    this.linkPreviewsEnabled = true,
    this.textScale = 1.0,
    this.onReply,
    this.onDelete,
    this.onTapImage,
  });

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    final bubbleColor =
        isMine ? ore.colors.accent : ore.colors.surface;
    final textColor =
        isMine ? ore.colors.textInverse : ore.colors.textPrimary;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showActions(context),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin:
              const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            border: Border.all(
                color: ore.colors.border, width: ore.borderWidth),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSender && !isMine && message.senderUsername != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '@${message.senderUsername!}',
                    style: ore.typography.caption.copyWith(
                      color: isMine
                          ? ore.colors.textInverse
                          : ore.colors.success,
                    ),
                  ),
                ),
              if (message.replyToMessageId != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ore.colors.surfaceDark.withValues(alpha: 0.35),
                    border: Border(
                      left: BorderSide(
                          color: ore.colors.warning, width: 3),
                    ),
                  ),
                  child: Text(
                    '↩ Replied message',
                    style: ore.typography.caption.copyWith(
                      color: textColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              _body(context, textColor),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timeFormat.format(message.createdAt),
                    style: ore.typography.caption.copyWith(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                  if (message.editedAt != null)
                    Text(
                      ' · edited',
                      style: ore.typography.caption.copyWith(
                        color: textColor.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Color textColor) {
    final ore = OreTheme.of(context);
    if (message.isDeleted) {
      return Text(
        'This message was deleted.',
        style: ore.typography.body.copyWith(
          color: textColor.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
          fontSize: 14 * textScale,
        ),
      );
    }
    switch (message.messageType) {
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.mediaUrl != null)
              GestureDetector(
                onTap: onTapImage == null
                    ? null
                    : () => onTapImage!(message),
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const SizedBox(
                    height: 160,
                    child: Center(
                        child: OreLoadingIndicator(size: 32)),
                  ),
                  errorWidget: (_, _, _) => Container(
                    height: 120,
                    color: ore.colors.surfaceDark,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            if (message.content?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _textBody(context, textColor),
              ),
          ],
        );
      case MessageType.voice:
        if (message.mediaUrl == null) {
          return Text('Voice message unavailable.',
              style: ore.typography.body.copyWith(color: textColor));
        }
        return VoiceBubble(
          url: message.mediaUrl!,
          durationSeconds: message.durationSeconds ?? 0,
          isMine: isMine,
        );
      case MessageType.text:
        return _textBody(context, textColor);
    }
  }

  Widget _textBody(BuildContext context, Color textColor) {
    final ore = OreTheme.of(context);
    final content = message.content ?? '';
    final urls = message.urls;
    if (!linkPreviewsEnabled || urls.isEmpty) {
      return SelectableText(
        content,
        style: ore.typography.body.copyWith(
          color: textColor,
          fontSize: 14 * textScale,
        ),
      );
    }
    // Text + first link preview.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          content,
          style: ore.typography.body.copyWith(
            color: textColor,
            fontSize: 14 * textScale,
          ),
        ),
        const SizedBox(height: 6),
        LinkPreviewCard(
          url: urls.first,
          onOpen: (url) async {
            final uri = Uri.tryParse(url);
            if (uri == null) return;
            try {
              await launchUrl(uri,
                  mode: LaunchMode.externalApplication);
            } catch (_) {}
          },
        ),
      ],
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(ctx);
                  onReply!();
                },
              ),
            if (onDelete != null && isMine)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Date divider chip between message groups.
class DateChip extends StatelessWidget {
  final String label;
  const DateChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: ore.colors.surfaceDark,
          border: Border.all(
              color: ore.colors.border, width: ore.borderWidth),
        ),
        child: Text(label, style: ore.typography.caption),
      ),
    );
  }
}
