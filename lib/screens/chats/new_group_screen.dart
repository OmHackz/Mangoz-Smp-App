import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';

/// Create group: name, description, image, member picker.
class NewGroupScreen extends ConsumerStatefulWidget {
  const NewGroupScreen({super.key});

  @override
  ConsumerState<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends ConsumerState<NewGroupScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _search = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  final Set<String> _selected = {};
  Future<List<UserProfile>>? _searchFuture;
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _imageBytes = bytes);
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Group name is required.');
      return;
    }
    if (_selected.isEmpty) {
      setState(() => _error = 'Add at least one member.');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      String? imageUrl;
      if (_imageBytes != null) {
        imageUrl = await StorageService.uploadGroupImage(_imageBytes!);
      }
      final chat = await ChatService.createGroup(
        name: name,
        description:
            _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        imageUrl: imageUrl,
        memberIds: _selected.toList(),
      );
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacementNamed('/chat', arguments: chat.id);
    } catch (e) {
      setState(() => _error = ChatService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: _imageBytes != null
                    ? MemoryImage(_imageBytes!)
                    : null,
                child: _imageBytes != null
                    ? null
                    : Icon(Icons.add_a_photo_outlined,
                        size: 32,
                        color: scheme.onPrimaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
              onPressed: _pickImage,
              child: const Text('Add group photo (optional)')),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Group name',
              hintText: 'e.g. Redstone Crew',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Add members',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _search,
            onChanged: (q) => setState(
                () => _searchFuture = ChatService.searchUsers(q)),
            decoration: const InputDecoration(
              hintText: 'Search users…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('${_selected.length} selected',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_searchFuture != null)
            FutureBuilder<List<UserProfile>>(
              future: _searchFuture,
              builder: (context, snap) {
                if (snap.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                        child: CircularProgressIndicator()),
                  );
                }
                final users = snap.data ?? const [];
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No users found.'),
                  );
                }
                return Card(
                  child: Column(
                    children: users.map((u) {
                      final selected = _selected.contains(u.id);
                      final initial = u.username.isEmpty
                          ? '?'
                          : u.username[0].toUpperCase();
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(u.id);
                          } else {
                            _selected.remove(u.id);
                          }
                        }),
                        title: Text('@${u.username}'),
                        secondary: CircleAvatar(
                            child: Text(initial)),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _creating ? null : _create,
            icon: const Icon(Icons.group_add_outlined),
            label:
                Text(_creating ? 'Creating…' : 'Create group'),
          ),
        ],
      ),
    );
  }
}
