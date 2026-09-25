import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/loading_error.dart';

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
    final ore = OreTheme.of(context);
    final conversations = ref.watch(conversationsProvider);
    final uid = ref.watch(authProvider.select((s) => s.profile?.id)) ?? '';

    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Text('Chats', style: ore.typography.choiceTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'New group',
            onPressed: () =>
                Navigator.of(context).pushNamed('/new-group'),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'New chat',
            onPressed: () =>
                Navigator.of(context).pushNamed('/new-chat'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: OreTextField(
              controller: _search,
              hintText: 'Search chats…',
              onChanged: (v) =>
                  setState(() => _filter = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: conversations.when(
              data: (chats) {
                if (!SupabaseService.isConfigured) {
                  return const ErrorView(
                    title: 'Backend not configured',
                    message:
                        'Add Supabase credentials to enable chats.',
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
                  return EmptyView(
                    title: chats.isEmpty
                        ? 'No chats yet'
                        : 'No matches',
                    subtitle: chats.isEmpty
                        ? 'Tap + to start a direct message or create a group.'
                        : 'Try a different search.',
                    icon: Icons.chat_bubble_outline,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(conversationsProvider),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 1,
                      color:
                          ore.colors.border.withValues(alpha: 0.4),
                    ),
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
                  const LoadingView(message: 'Loading chats…'),
              error: (e, _) => ErrorView(
                message:
                    'Check your internet connection and try again.\n$e',
                onRetry: () =>
                    ref.invalidate(conversationsProvider),
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
