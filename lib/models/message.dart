enum MessageType { text, image, voice }

MessageType messageTypeFromString(String? raw) {
  switch (raw) {
    case 'image':
      return MessageType.image;
    case 'voice':
      return MessageType.voice;
    case 'text':
    default:
      return MessageType.text;
  }
}

String messageTypeToString(MessageType type) {
  switch (type) {
    case MessageType.image:
      return 'image';
    case MessageType.voice:
      return 'voice';
    case MessageType.text:
      return 'text';
  }
}

final _urlRegex = RegExp(
  r'(https?:\/\/[^\s<>"' r"']+)",
  caseSensitive: false,
);

/// Chat message stored in `messages`.
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType messageType;
  final String? content;
  final String? mediaUrl;
  final String? replyToMessageId;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final int? durationSeconds;

  // Joined / ephemeral fields (not in DB row).
  final String? senderUsername;
  final String? senderAvatarUrl;
  final Message? replyPreview;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    this.content,
    this.mediaUrl,
    this.replyToMessageId,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
    this.durationSeconds,
    this.senderUsername,
    this.senderAvatarUrl,
    this.replyPreview,
  });

  bool get isDeleted => deletedAt != null;
  bool get isImage => messageType == MessageType.image && !isDeleted;
  bool get isVoice => messageType == MessageType.voice && !isDeleted;

  List<String> get urls {
    final text = content ?? '';
    if (text.isEmpty) return const [];
    return _urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  bool get containsUrl => urls.isNotEmpty;

  String get previewText {
    if (isDeleted) return 'This message was deleted.';
    switch (messageType) {
      case MessageType.image:
        return content?.isNotEmpty == true ? '📷 ${content!}' : '📷 Photo';
      case MessageType.voice:
        return '🎤 Voice message${durationSeconds != null ? ' (${durationSeconds}s)' : ''}';
      case MessageType.text:
        return content ?? '';
    }
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v, {DateTime? fallback}) {
      if (v == null) return fallback ?? DateTime.now();
      try {
        return DateTime.parse(v as String).toLocal();
      } catch (_) {
        return fallback ?? DateTime.now();
      }
    }

    DateTime? parseNullable(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v as String).toLocal();
      } catch (_) {
        return null;
      }
    }

    return Message(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      messageType:
          messageTypeFromString(json['message_type'] as String? ?? 'text'),
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      replyToMessageId: json['reply_to_message_id'] as String?,
      createdAt: parseDate(json['created_at']),
      editedAt: parseNullable(json['edited_at']),
      deletedAt: parseNullable(json['deleted_at']),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      senderUsername: json['sender_username'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'message_type': messageTypeToString(messageType),
        'content': content,
        'media_url': mediaUrl,
        'reply_to_message_id': replyToMessageId,
        'duration_seconds': durationSeconds,
      };
}
