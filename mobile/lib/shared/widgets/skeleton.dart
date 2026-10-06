import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_motion.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';

/// A subtle shimmer block. Used everywhere instead of a spinner.
class Skeleton extends StatefulWidget {
  const Skeleton({
    this.width,
    this.height = 16,
    this.radius = AppRadii.sm,
    super.key,
  });

  final double? width;
  final double height;
  final BorderRadius radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduced = AppMotion.scale(context, AppMotion.normal) == Duration.zero;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final opacity = reduced ? 0.6 : 0.4 + (_c.value * 0.3);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: tokens.divider.withValues(alpha: opacity),
            borderRadius: widget.radius,
          ),
        );
      },
    );
  }
}

/// A pre-composed skeleton for a list of rows (Home, History, etc.).
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.rows = 4, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        rows,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const Skeleton(width: 48, height: 48, radius: AppRadii.md),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 200 + (i % 2) * 60, height: 14),
                    const SizedBox(height: 8),
                    const Skeleton(width: 120, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}