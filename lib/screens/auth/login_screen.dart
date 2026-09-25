import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

/// Passwordless sign-in: email → 6-digit code → GO.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final _codeFocus = List.generate(6, (_) => FocusNode());

  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  Timer? _resendTimer;
  int _resendIn = 0;

  @override
  void dispose() {
    _email.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocus) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _code =>
      _codeControllers.map((c) => c.text).join();

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendIn <= 1) {
        t.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn--);
      }
    });
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.sendEmailOtp(email);
      if (!mounted) return;
      for (final c in _codeControllers) {
        c.clear();
      }
      setState(() => _codeSent = true);
      _startResendTimer();
      _codeFocus.first.requestFocus();
    } catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onCodeChanged(int index, String value) {
    // Spread pasted codes across the boxes.
    if (value.length > 1) {
      final chars = value.replaceAll(RegExp(r'\D'), '').split('');
      for (var i = 0; i < 6; i++) {
        _codeControllers[i].text =
            (index + i) < (index + chars.length) && i < chars.length
                ? chars[i]
                : (i == 0 ? value.characters.last : '');
      }
      _codeFocus.last.requestFocus();
      setState(() {});
      if (_code.replaceAll(RegExp(r'\D'), '').length == 6) {
        _verify();
      }
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _codeFocus[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _codeFocus[index - 1].requestFocus();
    }
    setState(() {});
    if (_code.length == 6) _verify();
  }

  Future<void> _verify() async {
    if (_busy || _code.length != 6) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.verifyEmailOtp(
        email: _email.text,
        token: _code,
      );
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 88,
                        height: 88,
                        errorBuilder: (_, _, _) => Container(
                          width: 88,
                          height: 88,
                          color: scheme.primaryContainer,
                          alignment: Alignment.center,
                          child: Text('M',
                              style: TextStyle(
                                  fontSize: 44,
                                  color: scheme.onPrimaryContainer)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Welcome to MangoZ SMP',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    _codeSent
                        ? 'Enter the 6-digit code we emailed you.'
                        : 'No passwords here — we\'ll email you a login code.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (!SupabaseService.isConfigured)
                    Card(
                      color: scheme.errorContainer,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Backend not configured. Launch with --dart-define=SUPABASE_URL and SUPABASE_ANON_KEY.',
                        ),
                      ),
                    ),
                  if (!SupabaseService.isConfigured)
                    const SizedBox(height: 12),
                  if (!_codeSent) ...[
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => _sendCode(),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_error != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: Text(_error!,
                            style: TextStyle(
                                color: scheme.error)),
                      ),
                    FilledButton.icon(
                      onPressed: _busy ? null : _sendCode,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.mail_outline),
                      label: Text(
                          _busy ? 'Sending…' : 'Send login code'),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        return SizedBox(
                          width: 48,
                          child: TextField(
                            controller: _codeControllers[i],
                            focusNode: _codeFocus[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,
                            ],
                            decoration:
                                const InputDecoration(
                              border: OutlineInputBorder(),
                              counterText: '',
                            ),
                            maxLength: i == 0 ? 6 : 1,
                            onChanged: (v) =>
                                _onCodeChanged(i, v),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    if (_error != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: Text(_error!,
                            style: TextStyle(
                                color: scheme.error),
                            textAlign: TextAlign.center),
                      ),
                    FilledButton.icon(
                      onPressed:
                          (_busy || _code.length != 6)
                              ? null
                              : _verify,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.login),
                      label:
                          Text(_busy ? 'Verifying…' : 'Verify & GO!'),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _resendIn > 0 || _busy
                              ? null
                              : _sendCode,
                          child: Text(_resendIn > 0
                              ? 'Resend in $_resendIn s'
                              : 'Resend code'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _codeSent = false;
                                    _error = null;
                                  }),
                          child:
                              const Text('Change email'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
