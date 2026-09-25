import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/ore_button.dart';

/// Step 1 of onboarding: unique MangoZ username.
class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _checking = false;
  bool? _available;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(authProvider).profile?.username;
    if (existing != null && existing.isNotEmpty) {
      _controller.text = existing;
    }
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {
      _available = null;
      _error = UserProfile.validateUsername(_controller.text);
    });
    _debounce?.cancel();
    if (_error != null) return;
    _debounce = Timer(const Duration(milliseconds: 500), _check);
  }

  Future<void> _check() async {
    final value = _controller.text.trim();
    if (UserProfile.validateUsername(value) != null) return;
    setState(() => _checking = true);
    try {
      final ok = await AuthService.isUsernameAvailable(value);
      if (mounted) setState(() => _available = ok);
    } catch (e) {
      if (mounted) {
        setState(() => _error = AuthService.friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _save() async {
    final err = UserProfile.validateUsername(_controller.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final available =
          await AuthService.isUsernameAvailable(_controller.text);
      if (!available) {
        setState(() => _error = 'That username is taken. Try another.');
        return;
      }
      await AuthService.upsertMyProfile(
        username: UserProfile.normalizeUsername(_controller.text),
      );
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/profile-picture');
    } catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    final statusText = _checking
        ? 'Checking availability…'
        : _available == true
            ? '✓ Available'
            : _available == false
                ? '✗ Taken'
                : '3–24 chars, letters/numbers/_';
    final statusColor = _available == true
        ? ore.colors.success
        : _available == false
            ? ore.colors.danger
            : ore.colors.textMuted;

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
                  Text('Choose your MangoZ username',
                      style: ore.typography.choiceTitle),
                  const SizedBox(height: 6),
                  Text(
                    'This does not have to be your Minecraft username. You can change it later in Settings.',
                    style: ore.typography.body
                        .copyWith(color: ore.colors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  OreTextField(
                    controller: _controller,
                    hintText: '@OmHackz',
                  ),
                  const SizedBox(height: 6),
                  Text(statusText,
                      style: ore.typography.caption
                          .copyWith(color: statusColor)),
                  if (_error != null &&
                      _error !=
                          UserProfile.validateUsername(
                              _controller.text)) ...[
                    const SizedBox(height: 6),
                    Text(_error!,
                        style: ore.typography.body
                            .copyWith(color: ore.colors.danger)),
                  ] else if (UserProfile.validateUsername(
                          _controller.text) !=
                      null) ...[
                    const SizedBox(height: 6),
                    Text(
                        UserProfile.validateUsername(
                            _controller.text)!,
                        style: ore.typography.body
                            .copyWith(color: ore.colors.danger)),
                  ],
                  const SizedBox(height: 16),
                  MangoOreButton.primary(
                    label: 'Continue',
                    onPressed:
                        (_saving || _checking) ? null : _save,
                    isLoading: _saving,
                    fullWidth: true,
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
