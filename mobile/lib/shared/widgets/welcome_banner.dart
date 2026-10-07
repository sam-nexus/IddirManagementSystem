import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_elevation.dart';
import 'package:odaa_mobile/core/theme/app_motion.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';

/// Shows a small welcome banner over the current screen.
/// Call [WelcomeBanner.show] from a post-frame callback.
class WelcomeBanner {
  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData icon = Icons.wb_sunny_outlined,
  }) {
    // Dismiss any existing banner first.
    _current?.remove();
    _current = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (ctx) => _WelcomeBannerOverlay(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onDismissed: () {
          _current?.remove();
          _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _WelcomeBannerOverlay extends StatefulWidget {
  const _WelcomeBannerOverlay({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onDismissed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onDismissed;

  @override
  State<_WelcomeBannerOverlay> createState() => _WelcomeBannerOverlayState();
}

class _WelcomeBannerOverlayState extends State<_WelcomeBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);

    _c.forward();

    // Auto-dismiss after 4 seconds.
    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _c.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topInset + AppSpacing.sm,
      left: AppSpacing.screenEdge,
      right: AppSpacing.screenEdge,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: AppRadii.md,
                  border: Border.all(color: tokens.divider, width: 1),
                  boxShadow: AppElevation.raised,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tokens.statePaidBg,
                        borderRadius: AppRadii.sm,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: tokens.statePaid,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: AppTypography.titleS.copyWith(
                              color: tokens.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: AppTypography.bodyS.copyWith(
                              color: tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}