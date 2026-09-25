import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

/// Onboarding step 2 of 2: profile picture (camera / gallery / skip).
class ProfilePictureScreen extends ConsumerStatefulWidget {
  const ProfilePictureScreen({super.key});

  @override
  ConsumerState<ProfilePictureScreen> createState() =>
      _ProfilePictureScreenState();
}

class _ProfilePictureScreenState
    extends ConsumerState<ProfilePictureScreen> {
  Uint8List? _localBytes;
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
      String? url;
      if (_localBytes != null) {
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
    final scheme = Theme.of(context).colorScheme;
    final username =
        ref.watch(authProvider.select((s) => s.profile?.username)) ??
            'player';
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LinearProgressIndicator(value: 1.0),
                  const SizedBox(height: 24),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 72,
                          backgroundColor:
                              scheme.primaryContainer,
                          backgroundImage:
                              _localBytes != null
                                  ? MemoryImage(_localBytes!)
                                  : null,
                          child: _localBytes != null
                              ? null
                              : Text(initial,
                                  style: TextStyle(
                                    fontSize: 56,
                                    color: scheme
                                        .onPrimaryContainer,
                                  )),
                        ),
                        if (_uploading)
                          const SizedBox(
                            width: 148,
                            height: 148,
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Step 2 of 2',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: scheme.primary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Add a face to the name',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    'So other players recognize @$username at a glance.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                            color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _uploading
                              ? null
                              : () =>
                                  _pick(ImageSource.camera),
                          icon: const Icon(
                              Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _uploading
                              ? null
                              : () =>
                                  _pick(ImageSource.gallery),
                          icon: const Icon(
                              Icons.photo_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  if (_localBytes != null)
                    TextButton(
                      onPressed: _uploading
                          ? null
                          : () => setState(
                              () => _localBytes = null),
                      child: const Text('Remove photo'),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_error!,
                          style:
                              TextStyle(color: scheme.error),
                          textAlign: TextAlign.center),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _uploading
                        ? null
                        : () => _continue(),
                    child: Text(
                        _uploading ? 'Uploading…' : 'Finish! 🎉'),
                  ),
                  TextButton(
                    onPressed: _uploading
                        ? null
                        : () => _continue(skip: true),
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
