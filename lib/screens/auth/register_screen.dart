import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import '../../services/auth_service.dart';
import '../../widgets/ore_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter an email and password.');
      return;
    }
    if (password.length < 6) {
      setState(
          () => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.signUp(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/username');
    } catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        title: const Text('Create account'),
        backgroundColor: ore.colors.background,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Join MangoZ SMP',
                      style: ore.typography.choiceTitle),
                  const SizedBox(height: 4),
                  Text(
                    'Create your community account. You will pick a username next.',
                    style: ore.typography.body
                        .copyWith(color: ore.colors.textMuted),
                  ),
                  const SizedBox(height: 16),
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
                    hintText: 'At least 6 characters',
                    obscureText: _obscure,
                  ),
                  const SizedBox(height: 12),
                  Text('Confirm password',
                      style: ore.typography.label),
                  const SizedBox(height: 6),
                  OreTextField(
                    controller: _confirm,
                    hintText: 'Repeat password',
                    obscureText: _obscure,
                    onSubmitted: (_) => _register(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: ore.typography.body
                            .copyWith(color: ore.colors.danger)),
                  ],
                  const SizedBox(height: 16),
                  MangoOreButton.primary(
                    label: 'Create account',
                    onPressed: _loading ? null : _register,
                    isLoading: _loading,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 8),
                  MangoOreButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed('/login'),
                    fullWidth: true,
                    child: const Text('Back to login'),
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
