import 'message.dart';

enum ConversationType { dm, group }

ConversationType conversationTypeFromString(String? raw) {
  if (raw == 'group') return ConversationType.group;
  return ConversationType.dm;
}

/// A conversation row (DM or group). Group metadata lives on the same row
/// for simplicity; membership lives in `conversation_members`.
class Chat {
  final String id;
  final ConversationType type;
  final String? name;
  final String? imageUrl;
  final String? description;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Ephemeral / joined data.
  final Message? lastMessage;
  final int unreadCount;
  final List<String> memberIds;
  final String? dmOtherUserId;
  final String? dmOtherUsername;
  final String? dmOtherAvatarUrl;

  const Chat({
    required this.id,
    required this.type,
    this.name,
    this.imageUrl,
    this.description,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.memberIds = const [],
    this.dmOtherUserId,
    this.dmOtherUsername,
    this.dmOtherAvatarUrl,
  });

  bool get isGroup => type == ConversationType.group;

  String title(String currentUserId) {
    if (isGroup) return name?.isNotEmpty == true ? name! : 'Group';
    if (dmOtherUsername?.isNotEmpty == true) return '@${dmOtherUsername!}';
    return 'Direct message';
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v as String).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    return Chat(
      id: json['id'] as String? ?? '',
      type: conversationTypeFromString(json['type'] as String?),
      name: json['name'] as String?,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}
