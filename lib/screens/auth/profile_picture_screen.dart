import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/ore_button.dart';
import '../../widgets/player_avatar.dart';

/// Step 2 of onboarding: profile picture (camera / gallery / skip).
class ProfilePictureScreen extends ConsumerStatefulWidget {
  const ProfilePictureScreen({super.key});

  @override
  ConsumerState<ProfilePictureScreen> createState() =>
      _ProfilePictureScreenState();
}

class _ProfilePictureScreenState
    extends ConsumerState<ProfilePictureScreen> {
  Uint8List? _localBytes;
  String? _uploadedUrl;
  bool _uploading = false;
  String? _error;
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _localBytes = bytes;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _continue({bool skip = false}) async {
    if (skip) {
      await ref.read(authProvider.notifier).setOnboardingComplete();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      String? url = _uploadedUrl;
      if (_localBytes != null && url == null) {
        final uid = AuthService.currentUser?.id;
        if (uid == null) throw StateError('Not signed in.');
        url = await StorageService.uploadAvatar(uid, _localBytes!);
      }
      final profile = ref.read(authProvider).profile;
      await AuthService.upsertMyProfile(
        username: profile?.username ?? 'player',
        avatarUrl: url,
      );
      await ref.read(authProvider.notifier).setOnboardingComplete();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(
          () => _error = StorageService.decodeStorageError(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    final username =
        ref.watch(authProvider.select((s) => s.profile?.username)) ??
            'player';
    return Scaffold(
      backgroundColor: ore.colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Pick a profile picture',
                      style: ore.typography.choiceTitle,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    'Help other players recognize @$username.',
                    style: ore.typography.body
                        .copyWith(color: ore.colors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: _localBytes != null
                        ? Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: ore.colors.border,
                                  width: ore.borderWidth * 2),
                            ),
                            child: Image.memory(_localBytes!,
                                fit: BoxFit.cover),
                          )
                        : PlayerAvatar(
                            username: username,
                            imageUrl: _uploadedUrl,
                            size: 128,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MangoOreButton(
                          onPressed: () =>
                              _pick(ImageSource.camera),
                          child: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MangoOreButton(
                          onPressed: () =>
                              _pick(ImageSource.gallery),
                          child: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  if (_localBytes != null) ...[
                    const SizedBox(height: 8),
                    MangoOreButton(
                      onPressed: () => setState(() {
                        _localBytes = null;
                        _uploadedUrl = null;
                      }),
                      fullWidth: true,
                      child: const Text('Remove image'),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: ore.typography.body
                            .copyWith(color: ore.colors.danger),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 16),
                  MangoOreButton.primary(
                    label: 'Finish',
                    onPressed:
                        _uploading ? null : () => _continue(),
                    isLoading: _uploading,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 8),
                  MangoOreButton(
                    onPressed: _uploading
                        ? null
                        : () => _continue(skip: true),
                    fullWidth: true,
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
