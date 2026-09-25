import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

/// Own profile: view + change avatar + shortcuts.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;
  final _picker = ImagePicker();

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () =>
                  Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Gallery'),
              onTap: () =>
                  Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await _picker.pickImage(source: source);
      if (file == null) return;
      setState(() => _uploading = true);
      final bytes = await file.readAsBytes();
      final uid = AuthService.currentUser!.id;
      final url = await StorageService.uploadAvatar(uid, bytes,
          sourcePath: file.name);
      final profile = ref.read(authProvider).profile;
      await AuthService.upsertMyProfile(
        username: profile?.username ?? 'player',
        avatarUrl: url,
      );
      await ref.read(authProvider.notifier).refreshProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(StorageService.decodeStorageError(e))));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final profile = ref.watch(authProvider).profile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final initial = profile.username.isEmpty
        ? '?'
        : profile.username[0].toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 64,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage:
                      profile.avatarUrl?.isNotEmpty == true
                          ? CachedNetworkImageProvider(
                              profile.avatarUrl!)
                          : null,
                  onBackgroundImageError: (_, _) {},
                  child: profile.avatarUrl?.isNotEmpty == true
                      ? null
                      : Text(initial,
                          style: TextStyle(
                              fontSize: 48,
                              color: scheme.onPrimaryContainer)),
                ),
                if (_uploading)
                  const SizedBox(
                    width: 132,
                    height: 132,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('@${profile.username}',
              style: text.headlineSmall,
              textAlign: TextAlign.center),
          if (profile.createdAt != null)
            Text(
              'Joined ${DateFormat('MMM yyyy').format(profile.createdAt!)}',
              style: text.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _uploading ? null : _changePhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Change profile picture'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context)
                .pushNamed('/account-settings'),
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Account settings'),
          ),
        ],
      ),
    );
  }
}
