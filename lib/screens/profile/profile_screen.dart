import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/ore_button.dart';
import '../../widgets/player_avatar.dart';

/// Own profile: view + edit username/avatar entry points.
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
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
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
      final url =
          await StorageService.uploadAvatar(uid, bytes, sourcePath: file.name);
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
    final ore = OreTheme.of(context);
    final auth = ref.watch(authProvider);
    final profile = auth.profile;
    if (profile == null) {
      return Scaffold(
        backgroundColor: ore.colors.background,
        appBar: AppBar(backgroundColor: ore.colors.background),
        body: const LoadingView(message: 'Loading profile…'),
      );
    }
    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Text('Profile', style: ore.typography.choiceTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                PlayerAvatar(
                  username: profile.username,
                  imageUrl: profile.avatarUrl,
                  size: 112,
                ),
                if (_uploading)
                  const Positioned.fill(
                    child: Center(
                        child: OreLoadingIndicator(size: 40)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('@${profile.username}',
              style: ore.typography.title,
              textAlign: TextAlign.center),
          if (profile.createdAt != null)
            Text(
              'Joined ${DateFormat('MMM yyyy').format(profile.createdAt!)}',
              style: ore.typography.caption,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          MangoOreButton(
            onPressed: _uploading ? null : _changePhoto,
            fullWidth: true,
            child: const Text('Change profile picture'),
          ),
          const SizedBox(height: 8),
          MangoOreButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/account-settings'),
            fullWidth: true,
            child: const Text('Account settings'),
          ),
        ],
      ),
    );
  }
}
