import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/chat.dart';

final _listTimeFormat = DateFormat('HH:mm');

/// Material 3 conversation row with unread badge.
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final title = chat.title(currentUserId);
    final last = chat.lastMessage;
    final subtitle = last?.previewText ??
        (chat.isGroup
            ? (chat.description ?? 'No messages yet')
            : 'Say hello 👋');
    final avatarName = chat.isGroup
        ? (chat.name ?? 'G')
        : (chat.dmOtherUsername ?? '?');
    final avatarUrl =
        chat.isGroup ? chat.imageUrl : chat.dmOtherAvatarUrl;
    final initial =
        avatarName.isEmpty ? '?' : avatarName[0].toUpperCase();

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        backgroundImage: avatarUrl?.isNotEmpty == true
            ? CachedNetworkImageProvider(avatarUrl!)
            : null,
        onBackgroundImageError: (_, _) {},
        child: avatarUrl?.isNotEmpty == true
            ? null
            : Text(initial,
                style:
                    TextStyle(color: scheme.onPrimaryContainer)),
      ),
      title: Text(title,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (last != null)
            Text(_formatTime(last.createdAt),
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          if (chat.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Badge(
              label: Text(chat.unreadCount > 99
                  ? '99+'
                  : '${chat.unreadCount}'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return DateFormat('dd/MM').format(dt);
    if (diff.inDays >= 1) return timeago.format(dt, locale: 'en_short');
    return _listTimeFormat.format(dt);
  }
}
