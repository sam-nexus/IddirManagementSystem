import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    Future<void>.delayed(const Duration(milliseconds: 1400), _route);
  }

  Future<void> _route() async {
    if (!mounted) return;

    await ref.read(sessionProvider.notifier).restore();
    if (!mounted) return;

    final lang = ref.read(languageProvider);
    final session = ref.read(sessionProvider);

    if (lang == null) {
      context.goNamed('language');
      return;
    }

    switch (session) {
      case SessionSignedIn():
        context.goNamed('home');
      case SessionSignedOut():
      case SessionUnknown():
        context.goNamed('login');
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                return Opacity(
                  opacity: _c.value,
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * _c.value,
                    child: Image.asset(
                      'assets/images/oda.png',
                      height: 140,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stack) {
                        return Icon(
                          Icons.park_outlined,
                          size: 100,
                          color: tokens.primary,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Afoosha Odaa',
              style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Gathered under the Odaa tree',
              style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
