import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/chat_service.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('New chat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: _doSearch,
              onSubmitted: _doSearch,
              decoration: const InputDecoration(
                hintText: 'Search by username…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(28)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _future == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search_outlined,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('Find players',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge),
                          const Text(
                              'Search for a MangoZ username to start chatting.'),
                        ],
                      ),
                    ),
                  )
                : FutureBuilder<List<UserProfile>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child:
                                CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                            child: Text(
                                ChatService.friendlyError(
                                    snap.error!)));
                      }
                      final users = snap.data ?? const [];
                      if (users.isEmpty) {
                        return const Center(
                            child: Text(
                                'No players found. Try another name.'));
                      }
                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, i) {
                          final u = users[i];
                          final initial = u.username.isEmpty
                              ? '?'
                              : u.username[0].toUpperCase();
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: u.avatarUrl
                                          ?.isNotEmpty ==
                                      true
                                  ? CachedNetworkImageProvider(
                                      u.avatarUrl!)
                                  : null,
                              onBackgroundImageError:
                                  (_, _) {},
                              child: u.avatarUrl?.isNotEmpty ==
                                      true
                                  ? null
                                  : Text(initial),
                            ),
                            title: Text('@${u.username}'),
                            subtitle: Text(u.isOnline
                                ? 'Online'
                                : 'Offline'),
                            enabled: !_creating,
                            onTap: () =>
                                Navigator.of(context).pushNamed(
                                    '/user-profile',
                                    arguments: u.id),
                            trailing: IconButton(
                              icon: const Icon(
                                  Icons.chat_bubble_outline),
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
