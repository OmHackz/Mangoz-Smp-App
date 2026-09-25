import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oreui_flutter/oreui_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/chat.dart';
import 'player_avatar.dart';

final _listTimeFormat = DateFormat('HH:mm');

/// WhatsApp-style conversation row with unread badge + online dot.
class ChatTile extends StatelessWidget {
  final Chat chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    final title = chat.title(currentUserId);
    final last = chat.lastMessage;
    final subtitle = last?.previewText ?? (chat.isGroup
        ? (chat.description ?? 'No messages yet')
        : 'Say hello 👋');
    final timeLabel = last == null
        ? ''
        : _formatTime(last.createdAt);

    final avatar = chat.isGroup
        ? PlayerAvatar(
            imageUrl: chat.imageUrl,
            username: chat.name ?? 'G',
            size: 52,
          )
        : PlayerAvatar(
            imageUrl: chat.dmOtherAvatarUrl,
            username: chat.dmOtherUsername ?? '?',
            size: 52,
          );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: ore.typography.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeLabel.isNotEmpty)
                        Text(timeLabel,
                            style: ore.typography.caption),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: ore.typography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ore.colors.accent,
                            border: Border.all(
                                color: ore.colors.border, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chat.unreadCount > 99
                                ? '99+'
                                : '${chat.unreadCount}',
                            style: ore.typography.caption.copyWith(
                              color: ore.colors.textInverse,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 7) {
      return DateFormat('dd/MM').format(dt);
    }
    if (diff.inDays >= 1) {
      return timeago.format(dt, locale: 'en_short');
    }
    return _listTimeFormat.format(dt);
  }
}
