import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';

/// Decides: login vs onboarding vs dashboard.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (!SupabaseService.isConfigured) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    final auth = ref.read(authProvider);
    if (auth.initializing) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
    }
    _go(ref.read(authProvider));
  }

  void _go(AuthState auth) {
    if (!auth.signedIn) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else if (!auth.onboardingComplete || auth.profile == null) {
      Navigator.of(context).pushReplacementNamed('/username');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    ref.listen(authProvider, (_, next) {
      if (next.initializing || !mounted) return;
      _go(next);
    });
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 104,
                height: 104,
                errorBuilder: (_, _, _) => Container(
                  width: 104,
                  height: 104,
                  color: scheme.primaryContainer,
                  alignment: Alignment.center,
                  child: Text('M',
                      style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(AppConfig.appName,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Community Hub',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
