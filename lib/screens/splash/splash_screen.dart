import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

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
    final current = ref.read(authProvider);
    if (!current.signedIn) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else if (!current.onboardingComplete || current.profile == null) {
      Navigator.of(context).pushReplacementNamed('/username');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    ref.listen(authProvider, (prev, next) {
      if (next.initializing) return;
      if (!mounted) return;
      if (!next.signedIn) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else if (!next.onboardingComplete || next.profile == null) {
        Navigator.of(context).pushReplacementNamed('/username');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
    return Scaffold(
      backgroundColor: ore.colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: ore.colors.accent,
                border: Border.all(
                    color: ore.colors.border,
                    width: ore.borderWidth * 2),
              ),
              alignment: Alignment.center,
              child: Text(
                'M',
                style: ore.typography.title.copyWith(
                  fontSize: 56,
                  color: ore.colors.textInverse,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('MangoZ SMP', style: ore.typography.title),
            const SizedBox(height: 6),
            Text('Community Hub',
                style: ore.typography.body
                    .copyWith(color: ore.colors.textMuted)),
            const SizedBox(height: 24),
            const OreLoadingIndicator(size: 40),
          ],
        ),
      ),
    );
  }
}
