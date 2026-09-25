import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/ore_button.dart';
import '../../widgets/player_avatar.dart';

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
    setState(() => _imageBytes = null);
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
    final ore = OreTheme.of(context);
    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title:
            Text('New group', style: ore.typography.choiceTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: _imageBytes != null
                  ? Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: ore.colors.border, width: 3),
                      ),
                      child: Image.memory(_imageBytes!,
                          fit: BoxFit.cover),
                    )
                  : Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: ore.colors.surfaceDark,
                        border: Border.all(
                            color: ore.colors.border, width: 3),
                      ),
                      child: const Icon(Icons.add_a_photo, size: 32),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Group name', style: ore.typography.label),
          const SizedBox(height: 6),
          OreTextField(controller: _name, hintText: 'e.g. Redstone Crew'),
          const SizedBox(height: 10),
          Text('Description (optional)',
              style: ore.typography.label),
          const SizedBox(height: 6),
          OreTextField(
              controller: _desc,
              hintText: 'What is this group about?',
              maxLines: 3),
          const SizedBox(height: 12),
          Text('Add members', style: ore.typography.label),
          const SizedBox(height: 6),
          OreTextField(
            controller: _search,
            hintText: 'Search users…',
            onChanged: (q) => setState(
                () => _searchFuture = ChatService.searchUsers(q)),
          ),
          const SizedBox(height: 8),
          if (_selected.isNotEmpty)
            Text('${_selected.length} selected',
                style: ore.typography.caption),
          if (_searchFuture != null)
            FutureBuilder<List<UserProfile>>(
              future: _searchFuture,
              builder: (context, snap) {
                if (snap.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: OreLoadingIndicator(size: 28),
                  );
                }
                final users = snap.data ?? const [];
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No users found.'),
                  );
                }
                return Column(
                  children: users.map((u) {
                    final selected = _selected.contains(u.id);
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
                      secondary: PlayerAvatar(
                        username: u.username,
                        imageUrl: u.avatarUrl,
                        size: 40,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: ore.typography.body
                    .copyWith(color: ore.colors.danger)),
          ],
          const SizedBox(height: 16),
          MangoOreButton.primary(
            label: 'Create group',
            onPressed: _creating ? null : _create,
            isLoading: _creating,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
