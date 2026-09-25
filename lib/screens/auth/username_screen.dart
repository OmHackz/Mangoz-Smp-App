import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';

/// Onboarding step 1 of 2: unique MangoZ username.
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
    final scheme = Theme.of(context).colorScheme;
    final name = UserProfile.normalizeUsername(_controller.text);
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
                  const LinearProgressIndicator(value: 0.5),
                  const SizedBox(height: 24),
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 36,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Step 1 of 2',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: scheme.primary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Pick your MangoZ name',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    'Not your Minecraft name — just how players will know you here. You can change it later.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (name.isNotEmpty)
                    Card(
                      color: scheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('@$name',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                            textAlign: TextAlign.center),
                      ),
                    ),
                  if (name.isNotEmpty) const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'OmHackz',
                      prefixText: '@ ',
                      border: const OutlineInputBorder(),
                      suffixIcon: _checking
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                        strokeWidth: 2),
                              ),
                            )
                          : _available == true
                              ? Icon(Icons.check_circle,
                                  color: Colors.green.shade600)
                              : _available == false
                                  ? Icon(Icons.cancel,
                                      color: scheme.error)
                                  : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _error ??
                        (_available == false
                            ? 'That username is taken.'
                            : '3–24 characters: letters, numbers, underscore.'),
                    style: TextStyle(
                      color: _error != null || _available == false
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: (_saving ||
                            _checking ||
                            _available != true)
                        ? null
                        : _save,
                    child: Text(_saving
                        ? 'Saving…'
                        : 'Continue →'),
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
