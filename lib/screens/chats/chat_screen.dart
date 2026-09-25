import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:oreui_flutter/oreui_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/chat.dart';
import '../../models/message.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/ore_button.dart';
import '../../widgets/player_avatar.dart';

/// Full chat screen: realtime messages, text/image/voice, reply, pagination.
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  RealtimeChannel? _channel;
  Message? _replyTo;
  bool _sending = false;

  // Voice recording
  final _recorder = AudioRecorder();
  bool _recording = false;
  DateTime? _recordStarted;
  Timer? _recordTicker;
  Duration _recordElapsed = Duration.zero;

  Chat? _chat;
  bool _loadingChat = true;
  String? _chatError;

  @override
  void initState() {
    super.initState();
    _loadChat();
    _subscribe();
    _scroll.addListener(_onScroll);
    _input.addListener(_onInputChanged);
  }

  bool _wasEmpty = true;
  void _onInputChanged() {
    final empty = _input.text.trim().isEmpty;
    if (empty != _wasEmpty && mounted) {
      setState(() => _wasEmpty = empty);
    }
  }

  Future<void> _loadChat() async {
    try {
      final chats = await ChatService.fetchConversations();
      final found = chats.where((c) => c.id == widget.conversationId);
      if (mounted) {
        setState(() {
          _chat = found.isEmpty ? null : found.first;
          _loadingChat = false;
          if (found.isEmpty) _chatError = 'Conversation not found.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingChat = false;
          _chatError = ChatService.friendlyError(e);
        });
      }
    }
  }

  void _subscribe() {
    if (!SupabaseService.isConfigured) return;
    _channel = ChatService.subscribeToConversation(
      widget.conversationId,
      onInsert: (m) {
        ref
            .read(messagesProvider(widget.conversationId).notifier)
            .prepend(m);
        ChatService.markAsRead(widget.conversationId);
        _scrollToBottom();
      },
      onUpdate: (m) {
        ref
            .read(messagesProvider(widget.conversationId).notifier)
            .upsert(m);
      },
      onDelete: (id) {
        ref
            .read(messagesProvider(widget.conversationId).notifier)
            .remove(id);
      },
    );
  }

  void _onScroll() {
    if (_scroll.position.pixels >
        _scroll.position.maxScrollExtent - 200) {
      ref
          .read(messagesProvider(widget.conversationId).notifier)
          .loadOlder();
    }
  }

  @override
  void dispose() {
    if (_channel != null) ChatService.unsubscribe(_channel!);
    _input.dispose();
    _scroll.dispose();
    _recordTicker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendText() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await ChatService.sendMessage(
        conversationId: widget.conversationId,
        type: MessageType.text,
        content: text,
        replyToMessageId: _replyTo?.id,
      );
      _input.clear();
      setState(() => _replyTo = null);
      ref
          .read(messagesProvider(widget.conversationId).notifier)
          .prepend(msg);
      ref.invalidate(conversationsProvider);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ChatService.friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (file == null) return;
      setState(() => _sending = true);
      final bytes = await file.readAsBytes();
      final url = await StorageService.uploadChatImage(
        bytes,
        sourcePath: file.name,
      );
      final msg = await ChatService.sendMessage(
        conversationId: widget.conversationId,
        type: MessageType.image,
        mediaUrl: url,
        replyToMessageId: _replyTo?.id,
      );
      setState(() => _replyTo = null);
      ref
          .read(messagesProvider(widget.conversationId).notifier)
          .prepend(msg);
      ref.invalidate(conversationsProvider);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ChatService.friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (file == null) return;
      setState(() => _sending = true);
      final bytes = await file.readAsBytes();
      final url = await StorageService.uploadChatImage(
        bytes,
        sourcePath: file.name,
      );
      final msg = await ChatService.sendMessage(
        conversationId: widget.conversationId,
        type: MessageType.image,
        mediaUrl: url,
      );
      ref
          .read(messagesProvider(widget.conversationId).notifier)
          .prepend(msg);
      ref.invalidate(conversationsProvider);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ChatService.friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Microphone permission is required.')),
        );
      }
      return;
    }
    try {
      if (!await _recorder.hasPermission()) return;
      final dir = Directory.systemTemp;
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      setState(() {
        _recording = true;
        _recordStarted = DateTime.now();
        _recordElapsed = Duration.zero;
      });
      _recordTicker?.cancel();
      _recordTicker =
          Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _recordStarted != null) {
          setState(() => _recordElapsed =
              DateTime.now().difference(_recordStarted!));
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording failed: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordTicker?.cancel();
    try {
      final path = await _recorder.stop();
      final elapsed = _recordElapsed;
      setState(() {
        _recording = false;
        _recordElapsed = Duration.zero;
      });
      if (cancel || path == null) return;
      final file = File(path);
      if (!await file.exists()) return;
      setState(() => _sending = true);
      final bytes = await file.readAsBytes();
      final url = await StorageService.uploadVoiceMessage(
        bytes,
        durationSeconds: elapsed.inSeconds,
      );
      final msg = await ChatService.sendMessage(
        conversationId: widget.conversationId,
        type: MessageType.voice,
        mediaUrl: url,
        durationSeconds: elapsed.inSeconds,
      );
      ref
          .read(messagesProvider(widget.conversationId).notifier)
          .prepend(msg);
      ref.invalidate(conversationsProvider);
      _scrollToBottom();
      try {
        await file.delete();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteMessage(Message m) async {
    try {
      await ChatService.deleteMessage(m.id);
      ref
          .read(messagesProvider(widget.conversationId).notifier)
          .upsert(Message(
            id: m.id,
            conversationId: m.conversationId,
            senderId: m.senderId,
            messageType: m.messageType,
            createdAt: m.createdAt,
            deletedAt: DateTime.now(),
          ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ChatService.friendlyError(e))),
        );
      }
    }
  }

  void _openImage(Message m) {
    if (m.mediaUrl == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: CachedNetworkImage(
              imageUrl: m.mediaUrl!,
              placeholder: (_, _) =>
                  const OreLoadingIndicator(size: 48),
              errorWidget: (_, _, _) =>
                  const Icon(Icons.broken_image, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    final uid = AuthService.currentUser?.id ?? '';
    final settings = ref.watch(settingsProvider);
    final messagesAsync =
        ref.watch(messagesProvider(widget.conversationId));

    if (_loadingChat) {
      return Scaffold(
        backgroundColor: ore.colors.background,
        appBar: AppBar(backgroundColor: ore.colors.background),
        body: const LoadingView(message: 'Opening chat…'),
      );
    }
    if (_chatError != null || _chat == null) {
      return Scaffold(
        backgroundColor: ore.colors.background,
        appBar: AppBar(backgroundColor: ore.colors.background),
        body: ErrorView(
          title: 'Chat unavailable',
          message: _chatError ?? 'Conversation not found.',
          onRetry: () {
            setState(() {
              _loadingChat = true;
              _chatError = null;
            });
            _loadChat();
          },
        ),
      );
    }
    final chat = _chat!;

    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.surface,
        title: InkWell(
          onTap: () {
            if (chat.isGroup) {
              Navigator.of(context).pushNamed('/group-info',
                  arguments: chat.id);
            } else if (chat.dmOtherUserId != null) {
              Navigator.of(context).pushNamed('/user-profile',
                  arguments: chat.dmOtherUserId);
            }
          },
          child: Row(
            children: [
              PlayerAvatar(
                username: chat.isGroup
                    ? (chat.name ?? 'G')
                    : (chat.dmOtherUsername ?? '?'),
                imageUrl: chat.isGroup
                    ? chat.imageUrl
                    : chat.dmOtherAvatarUrl,
                size: 36,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chat.title(uid),
                        style: ore.typography.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      chat.isGroup
                          ? '${chat.memberIds.length} members'
                          : 'Tap to view profile',
                      style: ore.typography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed(
                '/chat-settings',
                arguments: chat.id),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyView(
                    title: 'No messages yet',
                    subtitle: 'Say hello to start the conversation.',
                    icon: Icons.chat_bubble_outline,
                  );
                }
                // Newest-first from service; ListView reversed.
                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMine = m.senderId == uid;
                    final showSender = chat.isGroup && !isMine;
                    // Date chip when day changes.
                    final showDate = i == messages.length - 1 ||
                        !_sameDay(m.createdAt,
                            messages[i + 1].createdAt);
                    return Column(
                      children: [
                        MessageBubble(
                          message: m,
                          isMine: isMine,
                          showSender: showSender,
                          linkPreviewsEnabled:
                              settings.linkPreviewsEnabled,
                          textScale: settings.messageTextScale,
                          onReply: () =>
                              setState(() => _replyTo = m),
                          onDelete: isMine
                              ? () => _deleteMessage(m)
                              : null,
                          onTapImage: _openImage,
                        ),
                        if (showDate)
                          DateChip(
                              label: DateFormat('dd MMM yyyy')
                                  .format(m.createdAt)),
                      ],
                    );
                  },
                );
              },
              loading: () =>
                  const LoadingView(message: 'Loading messages…'),
              error: (e, _) => ErrorView(
                message: ChatService.friendlyError(e),
                onRetry: () => ref.invalidate(
                    messagesProvider(widget.conversationId)),
              ),
            ),
          ),
          if (_replyTo != null)
            Container(
              color: ore.colors.surfaceDark,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying: ${_replyTo!.previewText}',
                      style: ore.typography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyTo = null),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          _inputBar(context),
        ],
      ),
    );
  }

  Widget _inputBar(BuildContext context) {
    final ore = OreTheme.of(context);
    if (_recording) {
      return Container(
        color: ore.colors.surface,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.mic, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              '${_recordElapsed.inMinutes.toString().padLeft(2, '0')}:${(_recordElapsed.inSeconds % 60).toString().padLeft(2, '0')} recording…',
              style: ore.typography.body,
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _stopRecording(cancel: true),
              child: const Text('Cancel'),
            ),
            MangoOreButton(
              onPressed: () => _stopRecording(),
              variant: OreButtonVariant.primary,
              child: const Text('Send'),
            ),
          ],
        ),
      );
    }
    return Container(
      color: ore.colors.surface,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _sending
                  ? null
                  : () => _showAttachments(context),
            ),
            Expanded(
              child: OreTextField(
                controller: _input,
                hintText: 'Type a message…',
                maxLines: 5,
                minLines: 1,
                onSubmitted: (_) => _sendText(),
              ),
            ),
            const SizedBox(width: 6),
            if (_input.text.trim().isEmpty)
              IconButton(
                icon: const Icon(Icons.mic),
                onPressed: _sending ? null : _startRecording,
              ),
            MangoOreButton(
              onPressed: _sending ? null : _sendText,
              variant: OreButtonVariant.primary,
              isLoading: _sending,
              child: const Icon(Icons.send, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery image'),
              onTap: () {
                Navigator.pop(ctx);
                _sendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera photo'),
              onTap: () {
                Navigator.pop(ctx);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
