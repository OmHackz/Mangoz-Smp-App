import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/chat_service.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/player_avatar.dart';

/// Search users → view profile → start DM.
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _search = TextEditingController();
  Future<List<UserProfile>>? _future;
  bool _creating = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _doSearch(String q) {
    setState(() => _future = ChatService.searchUsers(q));
  }

  Future<void> _startDm(UserProfile user) async {
    setState(() => _creating = true);
    try {
      final chat = await ChatService.getOrCreateDm(user.id);
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/chat',
          arguments: chat.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ChatService.friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Text('New chat', style: ore.typography.choiceTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: OreTextField(
              controller: _search,
              hintText: 'Search by username…',
              onChanged: _doSearch,
              onSubmitted: _doSearch,
            ),
          ),
          Expanded(
            child: _future == null
                ? const EmptyView(
                    title: 'Find players',
                    subtitle:
                        'Search for a MangoZ username to start chatting.',
                    icon: Icons.person_search,
                  )
                : FutureBuilder<List<UserProfile>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState ==
                          ConnectionState.waiting) {
                        return const LoadingView(
                            message: 'Searching…');
                      }
                      if (snap.hasError) {
                        return ErrorView(
                          message: ChatService.friendlyError(
                              snap.error!),
                          onRetry: () =>
                              _doSearch(_search.text),
                        );
                      }
                      final users = snap.data ?? const [];
                      if (users.isEmpty) {
                        return const EmptyView(
                          title: 'No players found',
                          subtitle: 'Try a different username.',
                        );
                      }
                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, i) {
                          final u = users[i];
                          return ListTile(
                            leading: PlayerAvatar(
                              username: u.username,
                              imageUrl: u.avatarUrl,
                              size: 44,
                              showOnlineDot: true,
                              isOnline: u.isOnline,
                            ),
                            title: Text('@${u.username}',
                                style: ore.typography.label),
                            subtitle: Text(
                              u.isOnline
                                  ? 'Online'
                                  : 'Last seen recently',
                              style: ore.typography.caption,
                            ),
                            enabled: !_creating,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                  '/user-profile',
                                  arguments: u.id);
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.chat),
                              onPressed: _creating
                                  ? null
                                  : () => _startDm(u),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
