import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/ore_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.signIn(email: email, password: password);
      await ref.read(authProvider.notifier).refreshProfile();
      final auth = ref.read(authProvider);
      if (!mounted) return;
      if (!auth.signedIn) {
        setState(() => _error = 'Sign-in failed. Try again.');
        return;
      }
      if (auth.profile == null || !auth.onboardingComplete) {
        Navigator.of(context).pushReplacementNamed('/username');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first, then tap Forgot password.');
      return;
    }
    try {
      await AuthService.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
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
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: ore.colors.accent,
                        border: Border.all(
                            color: ore.colors.border,
                            width: ore.borderWidth * 2),
                      ),
                      alignment: Alignment.center,
                      child: Text('M',
                          style: ore.typography.title.copyWith(
                              color: ore.colors.textInverse)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('MangoZ SMP',
                      style: ore.typography.title,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Log in to your community account',
                      style: ore.typography.body
                          .copyWith(color: ore.colors.textMuted),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (!SupabaseService.isConfigured)
                    OreCard(
                      child: Text(
                        'Backend not configured. Launch with --dart-define=SUPABASE_URL and SUPABASE_ANON_KEY.',
                        style: ore.typography.body
                            .copyWith(color: ore.colors.warning),
                      ),
                    ),
                  if (!SupabaseService.isConfigured)
                    const SizedBox(height: 12),
                  Text('Email', style: ore.typography.label),
                  const SizedBox(height: 6),
                  OreTextField(
                    controller: _email,
                    hintText: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  Text('Password', style: ore.typography.label),
                  const SizedBox(height: 6),
                  OreTextField(
                    controller: _password,
                    hintText: '••••••••',
                    obscureText: _obscure,
                    suffix: GestureDetector(
                      onTap: () =>
                          setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: ore.colors.textMuted,
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: ore.typography.body
                            .copyWith(color: ore.colors.danger)),
                  ],
                  const SizedBox(height: 16),
                  MangoOreButton.primary(
                    label: 'Login',
                    onPressed: _loading ? null : _login,
                    isLoading: _loading,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 8),
                  MangoOreButton(
                    onPressed: _loading ? null : _forgot,
                    fullWidth: true,
                    child: const Text('Forgot password'),
                  ),
                  const SizedBox(height: 8),
                  MangoOreButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed('/register'),
                    fullWidth: true,
                    child: const Text('Create account'),
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
