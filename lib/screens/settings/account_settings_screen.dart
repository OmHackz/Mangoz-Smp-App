import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/ore_button.dart';
import '../../widgets/ore_setting_tile.dart';

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
        content: OreTextField(
            controller: controller, hintText: '@username'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
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
        content:
            OreTextField(controller: controller, hintText: 'Email'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
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

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: OreTextField(
            controller: controller,
            hintText: 'New password',
            obscureText: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    if (controller.text.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password must be 6+ characters.')));
      }
      return;
    }
    try {
      await AuthService.updatePassword(controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated.')));
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
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
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
    final ore = OreTheme.of(context);
    final profile = ref.watch(authProvider.select((s) => s.profile));
    final email = AuthService.currentUser?.email ?? '—';
    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title:
            Text('Account', style: ore.typography.choiceTitle),
      ),
      body: ListView(
        children: [
          OreSettingTile(
            icon: Icons.alternate_email,
            title: 'Username',
            subtitle: '@${profile?.username ?? '…'}',
            onTap: _busy ? null : _changeUsername,
          ),
          OreSettingTile(
            icon: Icons.photo,
            title: 'Profile picture',
            subtitle: 'Change avatar',
            onTap: () =>
                Navigator.of(context).pushNamed('/profile'),
          ),
          OreSettingTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: email,
            onTap: _changeEmail,
          ),
          OreSettingTile(
            icon: Icons.key,
            title: 'Password',
            subtitle: 'Change password',
            onTap: _changePassword,
          ),
          const OreSectionHeader(title: 'Session'),
          Padding(
            padding: const EdgeInsets.all(12),
            child: MangoOreButton(
              onPressed: _logout,
              fullWidth: true,
              child: const Text('Logout'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MangoOreButton.danger(
              label: 'Delete account',
              onPressed: _delete,
            ),
          ),
        ],
      ),
    );
  }
}
