import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/chat_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/ore_button.dart';
import '../../widgets/player_avatar.dart';

/// Other user's public profile: avatar, username, mutual groups, start chat.
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
    final ore = OreTheme.of(context);
    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(backgroundColor: ore.colors.background),
      body: FutureBuilder<UserProfile?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading profile…');
          }
          if (snap.hasError || snap.data == null) {
            return ErrorView(
              title: 'Profile unavailable',
              message: snap.hasError
                  ? snap.error.toString()
                  : 'User not found.',
              onRetry: () => setState(
                  () => _future = ChatService.fetchProfile(widget.userId)),
            );
          }
          final user = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: PlayerAvatar(
                  username: user.username,
                  imageUrl: user.avatarUrl,
                  size: 112,
                  showOnlineDot: true,
                  isOnline: user.isOnline,
                ),
              ),
              const SizedBox(height: 12),
              Text('@${user.username}',
                  style: ore.typography.title,
                  textAlign: TextAlign.center),
              Text(
                user.isOnline
                    ? '● Online'
                    : '○ Offline',
                style: ore.typography.body.copyWith(
                  color: user.isOnline
                      ? ore.colors.success
                      : ore.colors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              if (user.createdAt != null)
                Text(
                  'Joined ${DateFormat('MMM yyyy').format(user.createdAt!)}',
                  style: ore.typography.caption,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              MangoOreButton.primary(
                label: 'Start chat',
                onPressed: _startingChat ? null : _startChat,
                isLoading: _startingChat,
                fullWidth: true,
              ),
              const SizedBox(height: 8),
              MangoOreButton(
                onPressed: () => _toggleBlock(user),
                fullWidth: true,
                variant: _blocked
                    ? OreButtonVariant.secondary
                    : OreButtonVariant.danger,
                child: Text(_blocked ? 'Unblock' : 'Block'),
              ),
              const SizedBox(height: 8),
              Text(
                'Private info (email, settings) is never shown here.',
                style: ore.typography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
