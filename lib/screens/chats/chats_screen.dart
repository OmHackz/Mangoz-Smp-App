import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/chat_tile.dart';

/// Conversation list with search + new chat/group actions.
class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final _search = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final uid = ref.watch(authProvider.select((s) => s.profile?.id)) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'New group',
            onPressed: () =>
                Navigator.of(context).pushNamed('/new-group'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'New chat',
            onPressed: () =>
                Navigator.of(context).pushNamed('/new-chat'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) =>
                  setState(() => _filter = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search chats…',
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
            child: conversations.when(
              data: (chats) {
                if (!SupabaseService.isConfigured) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Backend not configured.\nAdd Supabase credentials to enable chats.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final filtered = _filter.isEmpty
                    ? chats
                    : chats.where((c) {
                        final title =
                            c.title(uid).toLowerCase();
                        final last = c.lastMessage?.previewText
                                .toLowerCase() ??
                            '';
                        return title.contains(_filter) ||
                            last.contains(_filter);
                      }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            chats.isEmpty
                                ? 'No chats yet'
                                : 'No matches',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chats.isEmpty
                                ? 'Tap + to start chatting.'
                                : 'Try a different search.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(conversationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final chat = filtered[i];
                      return ChatTile(
                        chat: chat,
                        currentUserId: uid,
                        onTap: () => Navigator.of(context)
                            .pushNamed('/chat',
                                arguments: chat.id)
                            .then((_) => ref.invalidate(
                                conversationsProvider)),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 48),
                      const SizedBox(height: 12),
                      const Text('Unable to connect'),
                      const SizedBox(height: 4),
                      Text(
                        'Check your internet connection and try again.\n$e',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(conversationsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).pushNamed('/new-chat'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
