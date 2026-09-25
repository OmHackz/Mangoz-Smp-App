import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../models/chat.dart';
import '../../models/group.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/ore_button.dart';
import '../../widgets/player_avatar.dart';

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
          TextButton(
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
            OreTextField(controller: name, hintText: 'Group name'),
            const SizedBox(height: 8),
            OreTextField(
                controller: desc,
                hintText: 'Description',
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
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
    final ore = OreTheme.of(context);
    if (_loading) {
      return Scaffold(
        backgroundColor: ore.colors.background,
        appBar: AppBar(backgroundColor: ore.colors.background),
        body: const LoadingView(message: 'Loading group…'),
      );
    }
    if (_error != null || _chat == null) {
      return Scaffold(
        backgroundColor: ore.colors.background,
        appBar: AppBar(backgroundColor: ore.colors.background),
        body: ErrorView(
            message: _error ?? 'Group not found.', onRetry: _load),
      );
    }
    final chat = _chat!;
    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Text('Group info', style: ore.typography.choiceTitle),
        actions: [
          if (_isAdmin)
            IconButton(
                icon: const Icon(Icons.edit), onPressed: _editInfo),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: PlayerAvatar(
              username: chat.name ?? 'G',
              imageUrl: chat.imageUrl,
              size: 96,
            ),
          ),
          const SizedBox(height: 12),
          Text(chat.name ?? 'Group',
              style: ore.typography.title,
              textAlign: TextAlign.center),
          if (chat.description?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(chat.description!,
                  style: ore.typography.body,
                  textAlign: TextAlign.center),
            ),
          const SizedBox(height: 4),
          Text('${_members.length} members',
              style: ore.typography.caption,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Members', style: ore.typography.choiceTitle),
          const SizedBox(height: 8),
          ..._members.map((m) => ListTile(
                leading: PlayerAvatar(
                    username: m.username,
                    imageUrl: m.avatarUrl,
                    size: 44),
                title: Text('@${m.username}',
                    style: ore.typography.label),
                subtitle: Text(m.role,
                    style: ore.typography.caption),
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
              )),
          const SizedBox(height: 16),
          if (_isAdmin)
            MangoOreButton(
              onPressed: () => Navigator.of(context)
                  .pushNamed('/new-chat'),
              fullWidth: true,
              child: const Text('Add members (via New chat search)'),
            ),
          const SizedBox(height: 8),
          MangoOreButton.danger(
            label: 'Leave group',
            onPressed: _leave,
          ),
        ],
      ),
    );
  }
}
