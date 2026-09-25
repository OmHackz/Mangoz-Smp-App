import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat.dart';
import '../../models/group.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';

/// Group info: members, admins, add/remove, leave, edit info.
class GroupInfoScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const GroupInfoScreen({super.key, required this.conversationId});

  @override
  ConsumerState<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends ConsumerState<GroupInfoScreen> {
  Chat? _chat;
  List<GroupMember> _members = const [];
  bool _loading = true;
  String? _error;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chats = await ChatService.fetchConversations();
      final found =
          chats.where((c) => c.id == widget.conversationId);
      if (found.isEmpty) throw StateError('Group not found.');
      final members =
          await ChatService.fetchGroupMembers(widget.conversationId);
      final uid = AuthService.currentUser?.id;
      final me = members.where((m) => m.userId == uid);
      if (mounted) {
        setState(() {
          _chat = found.first;
          _members = members;
          _isAdmin = me.isEmpty ? false : me.first.isAdmin;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = ChatService.friendlyError(e);
        });
      }
    }
  }

  Future<void> _leave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave group?'),
        content: const Text('You will stop receiving messages.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ChatService.leaveGroup(widget.conversationId);
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      Navigator.of(context)
          .popUntil((r) => r.settings.name != '/chat');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ChatService.friendlyError(e))));
      }
    }
  }

  Future<void> _removeMember(GroupMember m) async {
    try {
      await ChatService.removeGroupMember(
          widget.conversationId, m.userId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ChatService.friendlyError(e))));
      }
    }
  }

  Future<void> _toggleAdmin(GroupMember m) async {
    try {
      await ChatService.setMemberRole(widget.conversationId, m.userId,
          m.isAdmin ? 'member' : 'admin');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ChatService.friendlyError(e))));
      }
    }
  }

  Future<void> _editInfo() async {
    final name = TextEditingController(text: _chat?.name ?? '');
    final desc = TextEditingController(text: _chat?.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(
                    labelText: 'Group name',
                    border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
                controller: desc,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ChatService.updateGroup(
        conversationId: widget.conversationId,
        name: name.text,
        description: desc.text,
      );
      ref.invalidate(conversationsProvider);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ChatService.friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _chat == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Group not found.'),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: _load,
                  child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final chat = _chat!;
    final initial = (chat.name ?? 'G').isEmpty
        ? 'G'
        : (chat.name ?? 'G')[0].toUpperCase();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group info'),
        actions: [
          if (_isAdmin)
            IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _editInfo),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 56,
              backgroundColor: scheme.primaryContainer,
              backgroundImage: chat.imageUrl?.isNotEmpty == true
                  ? CachedNetworkImageProvider(chat.imageUrl!)
                  : null,
              onBackgroundImageError: (_, _) {},
              child: chat.imageUrl?.isNotEmpty == true
                  ? null
                  : Text(initial,
                      style: TextStyle(
                          fontSize: 44,
                          color: scheme.onPrimaryContainer)),
            ),
          ),
          const SizedBox(height: 12),
          Text(chat.name ?? 'Group',
              style: text.headlineSmall,
              textAlign: TextAlign.center),
          if (chat.description?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(chat.description!,
                  style: text.bodyMedium,
                  textAlign: TextAlign.center),
            ),
          Text('${_members.length} members',
              style: text.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Members', style: text.titleMedium),
          const SizedBox(height: 4),
          ..._members.map((m) {
            final mi = m.username.isEmpty
                ? '?'
                : m.username[0].toUpperCase();
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: m.avatarUrl?.isNotEmpty == true
                    ? CachedNetworkImageProvider(m.avatarUrl!)
                    : null,
                onBackgroundImageError: (_, _) {},
                child: m.avatarUrl?.isNotEmpty == true
                    ? null
                    : Text(mi),
              ),
              title: Text('@${m.username}'),
              subtitle: Text(m.role),
              onTap: () => Navigator.of(context).pushNamed(
                  '/user-profile',
                  arguments: m.userId),
              trailing: _isAdmin &&
                      m.userId != AuthService.currentUser?.id
                  ? PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'admin') _toggleAdmin(m);
                        if (v == 'remove') _removeMember(m);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'admin',
                          child: Text(m.isAdmin
                              ? 'Remove admin'
                              : 'Make admin'),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove',
                              style:
                                  TextStyle(color: Colors.red)),
                        ),
                      ],
                    )
                  : null,
            );
          }),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error),
            onPressed: _leave,
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Leave group'),
          ),
        ],
      ),
    );
  }
}
