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

    // Restore the session first.
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
                    child: _OdaaMark(tokens: tokens),
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

class _OdaaMark extends StatelessWidget {
  const _OdaaMark({required this.tokens});

  final dynamic tokens;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(72, 96),
      painter: _MarkPainter(tokens: tokens),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.tokens});

  final dynamic tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final primary = tokens.primary as Color;
    final accent = tokens.primaryAction as Color;

    // Trunk
    final trunk = Path()
      ..moveTo(w * 0.42, h)
      ..lineTo(w * 0.58, h)
      ..quadraticBezierTo(w * 0.54, h * 0.55, w * 0.50, h * 0.30)
      ..quadraticBezierTo(w * 0.46, h * 0.55, w * 0.42, h)
      ..close();
    canvas.drawPath(trunk, Paint()..color = primary);

    // Three leaves at the top
    void leaf(double cx, double cy, double r) {
      final p = Path()
        ..moveTo(cx, cy + r)
        ..cubicTo(cx - r, cy + r * 0.4, cx - r, cy - r * 0.6, cx, cy - r)
        ..cubicTo(cx + r, cy - r * 0.6, cx + r, cy + r * 0.4, cx, cy + r)
        ..close();
      canvas.drawPath(p, Paint()..color = accent);
    }

    leaf(w * 0.30, h * 0.22, w * 0.14);
    leaf(w * 0.70, h * 0.22, w * 0.14);
    leaf(w * 0.50, h * 0.08, w * 0.16);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.tokens != tokens;
}
