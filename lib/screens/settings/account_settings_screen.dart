import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/settings_widgets.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState
    extends ConsumerState<AccountSettingsScreen> {
  bool _busy = false;

  Future<void> _changeUsername() async {
    final controller = TextEditingController(
        text: ref.read(authProvider).profile?.username ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '@username',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final err = UserProfile.validateUsername(controller.text);
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }
    setState(() => _busy = true);
    try {
      final available =
          await AuthService.isUsernameAvailable(controller.text);
      if (!available) throw Exception('Username is taken.');
      await AuthService.upsertMyProfile(
        username: UserProfile.normalizeUsername(controller.text),
      );
      await ref.read(authProvider.notifier).refreshProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AuthService.friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeEmail() async {
    final controller = TextEditingController(
        text: AuthService.currentUser?.email ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AuthService.updateEmail(controller.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Check your inbox to confirm.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AuthService.friendlyError(e))));
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).signOut();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'Your profile will be removed and you will be signed out. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AuthService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AuthService.friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(authProvider.select((s) => s.profile));
    final email = AuthService.currentUser?.email ?? '—';
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        children: [
          const SettingsSection(title: 'Profile'),
          SettingsTile(
            icon: Icons.alternate_email,
            title: 'Username',
            subtitle: '@${profile?.username ?? '…'}',
            onTap: _busy ? null : _changeUsername,
          ),
          SettingsTile(
            icon: Icons.photo_outlined,
            title: 'Profile picture',
            subtitle: 'Change avatar',
            onTap: () =>
                Navigator.of(context).pushNamed('/profile'),
          ),
          const SettingsSection(title: 'Sign-in'),
          const SettingsTile(
            icon: Icons.mail_lock_outlined,
            title: 'Email login codes',
            subtitle: 'Passwordless — codes sent by email',
          ),
          SettingsTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: email,
            onTap: _changeEmail,
          ),
          const SettingsSection(title: 'Session'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
