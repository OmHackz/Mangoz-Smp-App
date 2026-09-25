import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat.dart';
import '../models/group.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

/// Full WhatsApp-style messaging backend on Supabase.
///
/// Tables: profiles, conversations, conversation_members, messages.
/// Realtime: postgres_changes on messages + conversation_members.
class ChatService {
  ChatService._();

  static SupabaseClient get _client => SupabaseService.client;
  static String get _uid => _client.auth.currentUser!.id;

  // ---------- Users ----------

  static Future<List<UserProfile>> searchUsers(String query,
      {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final normalized = UserProfile.normalizeUsername(q);
    final rows = await _client
        .from('profiles')
        .select('id, username, avatar_url, created_at, updated_at, last_seen')
        .ilike('username', '%$normalized%')
        .limit(limit);
    final list = (rows as List)
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .where((p) => p.id != _client.auth.currentUser?.id)
        .toList();
    return list;
  }

  static Future<UserProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('id, username, avatar_url, created_at, updated_at, last_seen')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromJson(row);
  }

  // ---------- Conversations ----------

  static Future<List<Chat>> fetchConversations() async {
    final uid = _uid;
    // Conversations the user belongs to.
    final memberships = await _client
        .from('conversation_members')
        .select('conversation_id, last_read_at')
        .eq('user_id', uid) as List;
    if (memberships.isEmpty) return const [];
    final ids =
        memberships.map((e) => (e as Map)['conversation_id'] as String).toList();
    final lastRead = {
      for (final m in memberships)
        (m as Map)['conversation_id'] as String:
            (m['last_read_at'] as String?)
    };

    final convRows = await _client
        .from('conversations')
        .select()
        .inFilter('id', ids)
        .order('updated_at', ascending: false);
    final chats = <Chat>[];
    for (final row in (convRows as List)) {
      final map = row as Map<String, dynamic>;
      final chat = Chat.fromJson(map);
      final enriched = await _enrich(chat, lastRead[chat.id]);
      chats.add(enriched);
    }
    chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return chats;
  }

  static Future<Chat> _enrich(Chat chat, String? lastReadAt) async {
    // Members
    List<String> memberIds = const [];
    try {
      final members = await _client
          .from('conversation_members')
          .select('user_id')
          .eq('conversation_id', chat.id) as List;
      memberIds = members
          .map((e) => (e as Map)['user_id'] as String)
          .toList();
    } catch (_) {}

    // Last message
    Message? last;
    try {
      final rows = await _client
          .from('messages')
          .select()
          .eq('conversation_id', chat.id)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(1) as List;
      if (rows.isNotEmpty) {
        last = Message.fromJson(rows.first as Map<String, dynamic>);
      }
    } catch (_) {}

    // Unread count
    int unread = 0;
    try {
      if (lastReadAt != null) {
        final rows = await _client
            .from('messages')
            .select('id')
            .eq('conversation_id', chat.id)
            .gt('created_at', lastReadAt)
            .neq('sender_id', _client.auth.currentUser!.id) as List;
        unread = rows.length;
      } else if (last != null) {
        final rows = await _client
            .from('messages')
            .select('id')
            .eq('conversation_id', chat.id)
            .neq('sender_id', _client.auth.currentUser!.id) as List;
        unread = rows.length > 99 ? 99 : rows.length;
      }
    } catch (_) {}

    String? otherId;
    String? otherUsername;
    String? otherAvatar;
    if (!chat.isGroup) {
      try {
        final other = memberIds.firstWhere(
          (id) => id != _client.auth.currentUser!.id,
          orElse: () => '',
        );
        if (other.isNotEmpty) {
          otherId = other;
          final profile = await fetchProfile(other);
          otherUsername = profile?.username;
          otherAvatar = profile?.avatarUrl;
        }
      } catch (_) {}
    }

    return Chat(
      id: chat.id,
      type: chat.type,
      name: chat.name,
      imageUrl: chat.imageUrl,
      description: chat.description,
      createdBy: chat.createdBy,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt,
      lastMessage: last,
      unreadCount: unread,
      memberIds: memberIds,
      dmOtherUserId: otherId,
      dmOtherUsername: otherUsername,
      dmOtherAvatarUrl: otherAvatar,
    );
  }

  static Future<Chat> getOrCreateDm(String otherUserId) async {
    final uid = _uid;
    // Find existing DM with exactly these two members.
    final myMemberships = await _client
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', uid);
    final myIds = (myMemberships as List)
        .map((e) => (e as Map)['conversation_id'] as String)
        .toList();
    if (myIds.isNotEmpty) {
      final otherMemberships = await _client
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', otherUserId)
          .inFilter('conversation_id', myIds);
      for (final m in (otherMemberships as List)) {
        final cid = (m as Map)['conversation_id'] as String;
        final conv = await _client
            .from('conversations')
            .select()
            .eq('id', cid)
            .eq('type', 'dm')
            .maybeSingle();
        if (conv != null) {
          final chat = Chat.fromJson(conv);
          return _enrich(chat, null);
        }
      }
    }
    // Create new DM.
    final conv = await _client
        .from('conversations')
        .insert({'type': 'dm', 'created_by': uid}).select().single();
    final chat = Chat.fromJson(conv);
    await _client.from('conversation_members').insert([
      {'conversation_id': chat.id, 'user_id': uid, 'role': 'member'},
      {'conversation_id': chat.id, 'user_id': otherUserId, 'role': 'member'},
    ]);
    return _enrich(chat, null);
  }

  static Future<Chat> createGroup({
    required String name,
    String? description,
    String? imageUrl,
    required List<String> memberIds,
  }) async {
    final uid = _uid;
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Group name is required.');
    final conv = await _client.from('conversations').insert({
      'type': 'group',
      'name': trimmed,
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'image_url': imageUrl,
      'created_by': uid,
    }).select().single();
    final chat = Chat.fromJson(conv);
    final all = {uid, ...memberIds};
    await _client.from('conversation_members').insert(
          all.map((id) => {
                'conversation_id': chat.id,
                'user_id': id,
                'role': id == uid ? 'admin' : 'member',
              }).toList(),
        );
    return _enrich(chat, null);
  }

  static Future<void> updateGroup({
    required String conversationId,
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    await _client.from('conversations').update({
      if (name != null) 'name': name.trim(),
      if (description != null) 'description': description.trim(),
      'image_url': ?imageUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', conversationId);
  }

  static Future<List<GroupMember>> fetchGroupMembers(
      String conversationId) async {
    final rows = await _client
        .from('conversation_members')
        .select('user_id, role, joined_at, profiles(username, avatar_url)')
        .eq('conversation_id', conversationId)
        .order('joined_at');
    return (rows as List)
        .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addGroupMembers(
      String conversationId, List<String> userIds) async {
    if (userIds.isEmpty) return;
    await _client.from('conversation_members').upsert(
          userIds
              .map((id) => {
                    'conversation_id': conversationId,
                    'user_id': id,
                    'role': 'member',
                  })
              .toList(),
          onConflict: 'conversation_id,user_id',
        );
    await _touchConversation(conversationId);
  }

  static Future<void> removeGroupMember(
      String conversationId, String userId) async {
    await _client
        .from('conversation_members')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
    await _touchConversation(conversationId);
  }

  static Future<void> leaveGroup(String conversationId) async {
    await removeGroupMember(conversationId, _uid);
  }

  static Future<void> setMemberRole(
      String conversationId, String userId, String role) async {
    assert(role == 'admin' || role == 'member');
    await _client.from('conversation_members').update({'role': role}).eq(
        'conversation_id', conversationId).eq('user_id', userId);
  }

  static Future<void> _touchConversation(String id) async {
    try {
      await _client.from('conversations').update(
          {'updated_at': DateTime.now().toUtc().toIso8601String()}).eq(
          'id', id);
    } catch (_) {}
  }

  static Future<void> markAsRead(String conversationId) async {
    try {
      await _client
          .from('conversation_members')
          .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', _uid);
    } catch (_) {}
  }

  // ---------- Messages ----------

  static Future<List<Message>> fetchMessages(
    String conversationId, {
    int limit = 40,
    DateTime? before,
  }) async {
    final filter = _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId);
    final withCursor = before != null
        ? filter.lt('created_at', before.toUtc().toIso8601String())
        : filter;
    final rows = await withCursor
        .order('created_at', ascending: false)
        .limit(limit);
    final messages = (rows as List)
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
    // Attach sender profiles (batched).
    final senderIds = messages.map((m) => m.senderId).toSet().toList();
    if (senderIds.isNotEmpty) {
      try {
        final profiles = await _client
            .from('profiles')
            .select('id, username, avatar_url')
            .inFilter('id', senderIds);
        final byId = {
          for (final p in (profiles as List))
            (p as Map)['id'] as String: p as Map<String, dynamic>
        };
        return messages
            .map((m) => Message(
                  id: m.id,
                  conversationId: m.conversationId,
                  senderId: m.senderId,
                  messageType: m.messageType,
                  content: m.content,
                  mediaUrl: m.mediaUrl,
                  replyToMessageId: m.replyToMessageId,
                  createdAt: m.createdAt,
                  editedAt: m.editedAt,
                  deletedAt: m.deletedAt,
                  durationSeconds: m.durationSeconds,
                  senderUsername:
                      byId[m.senderId]?['username'] as String?,
                  senderAvatarUrl:
                      byId[m.senderId]?['avatar_url'] as String?,
                ))
            .toList();
      } catch (_) {
        return messages;
      }
    }
    return messages;
  }

  static Future<Message> sendMessage({
    required String conversationId,
    required MessageType type,
    String? content,
    String? mediaUrl,
    String? replyToMessageId,
    int? durationSeconds,
  }) async {
    final row = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': _uid,
          'message_type': messageTypeToString(type),
          'content': content,
          'media_url': mediaUrl,
          'reply_to_message_id': replyToMessageId,
          'duration_seconds': durationSeconds,
        })
        .select()
        .single();
    await _touchConversation(conversationId);
    return Message.fromJson(row);
  }

  static Future<Message?> fetchMessageById(String id) async {
    final row =
        await _client.from('messages').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Message.fromJson(row);
  }

  static Future<void> deleteMessage(String messageId) async {
    // Soft delete so other clients see "message deleted".
    await _client.from('messages').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
      'content': null,
      'media_url': null,
    }).eq('id', messageId).eq('sender_id', _uid);
  }

  // ---------- Realtime ----------

  /// Subscribe to new/updated/deleted messages in one conversation.
  static RealtimeChannel subscribeToConversation(
    String conversationId, {
    required void Function(Message) onInsert,
    required void Function(Message) onUpdate,
    void Function(String deletedId)? onDelete,
  }) {
    final channel =
        _client.channel('messages:$conversationId').onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'conversation_id',
                value: conversationId,
              ),
              callback: (payload) {
                try {
                  onInsert(Message.fromJson(payload.newRecord));
                } catch (_) {}
              },
            ).onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'conversation_id',
                value: conversationId,
              ),
              callback: (payload) {
                try {
                  final msg = Message.fromJson(payload.newRecord);
                  if (msg.isDeleted) {
                    onDelete?.call(msg.id);
                  }
                  onUpdate(msg);
                } catch (_) {}
              },
            ).subscribe();
    return channel;
  }

  static Future<void> unsubscribe(RealtimeChannel channel) async {
    try {
      await _client.removeChannel(channel);
    } catch (_) {}
  }

  static String friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Failed host lookup') ||
        msg.contains('SocketException') ||
        msg.contains('Network')) {
      return 'Unable to connect. Check your internet connection.';
    }
    return msg.replaceFirst(RegExp(r'^.*Exception:\s*'), '');
  }
}
