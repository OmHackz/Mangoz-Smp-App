import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/chat_service.dart';
import '../../services/supabase_service.dart';

/// Other user's public profile: avatar, username, start chat, block.
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() =>
      _UserProfileScreenState();
}

class _UserProfileScreenState
    extends ConsumerState<UserProfileScreen> {
  Future<UserProfile?>? _future;
  bool _startingChat = false;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _future = ChatService.fetchProfile(widget.userId);
    _checkBlocked();
  }

  Future<void> _checkBlocked() async {
    try {
      final rows = await SupabaseService.client
          .from('blocked_users')
          .select('blocked_user_id')
          .eq('user_id',
              SupabaseService.client.auth.currentUser!.id)
          .eq('blocked_user_id', widget.userId);
      if (mounted) {
        setState(() => _blocked = (rows as List).isNotEmpty);
      }
    } catch (_) {}
  }

  Future<void> _startChat() async {
    setState(() => _startingChat = true);
    try {
      final chat = await ChatService.getOrCreateDm(widget.userId);
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/chat',
          arguments: chat.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ChatService.friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  Future<void> _toggleBlock(UserProfile user) async {
    try {
      final client = SupabaseService.client;
      final me = client.auth.currentUser!.id;
      if (_blocked) {
        await client
            .from('blocked_users')
            .delete()
            .eq('user_id', me)
            .eq('blocked_user_id', user.id);
      } else {
        await client.from('blocked_users').insert(
            {'user_id': me, 'blocked_user_id': user.id});
      }
      setState(() => _blocked = !_blocked);
      ref.invalidate(blockedUsersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<UserProfile?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Profile unavailable'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => setState(() =>
                          _future = ChatService.fetchProfile(
                              widget.userId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final user = snap.data!;
          final initial = user.username.isEmpty
              ? '?'
              : user.username[0].toUpperCase();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Center(
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage:
                      user.avatarUrl?.isNotEmpty == true
                          ? CachedNetworkImageProvider(
                              user.avatarUrl!)
                          : null,
                  onBackgroundImageError: (_, _) {},
                  child: user.avatarUrl?.isNotEmpty == true
                      ? null
                      : Text(initial,
                          style: TextStyle(
                              fontSize: 48,
                              color: scheme.onPrimaryContainer)),
                ),
              ),
              const SizedBox(height: 12),
              Text('@${user.username}',
                  style: text.headlineSmall,
                  textAlign: TextAlign.center),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: user.isOnline
                          ? Colors.green.shade600
                          : scheme.outline,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(user.isOnline ? 'Online' : 'Offline',
                      style: text.bodyMedium),
                ],
              ),
              if (user.createdAt != null)
                Text(
                  'Joined ${DateFormat('MMM yyyy').format(user.createdAt!)}',
                  style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed:
                    _startingChat ? null : _startChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                    _startingChat ? 'Opening…' : 'Start chat'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: _blocked
                    ? null
                    : OutlinedButton.styleFrom(
                        foregroundColor: scheme.error),
                onPressed: () => _toggleBlock(user),
                icon: Icon(_blocked
                    ? Icons.lock_open_outlined
                    : Icons.block_outlined),
                label: Text(_blocked ? 'Unblock' : 'Block'),
              ),
              const SizedBox(height: 8),
              Text(
                'Private info (email, settings) is never shown here.',
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
