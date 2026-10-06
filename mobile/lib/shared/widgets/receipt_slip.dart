import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';

/// A receipt styled as a paper slip with a torn top edge.
/// Pass the content as [children]; the slip handles shape, stamp, and shadow.
class ReceiptSlip extends StatelessWidget {
  const ReceiptSlip({
    required this.receiptNumber,
    required this.children,
    this.footer,
    super.key,
  });

  final String receiptNumber;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: PhysicalShape(
        clipper: _TornTopClipper(),
        color: tokens.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl + 4,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'AFOOSHA ODAA',
                      style: AppTypography.caption.copyWith(
                        color: tokens.textMuted,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  _Stamp(),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DashedDivider(),
              const SizedBox(height: AppSpacing.md),
              ...children,
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.md),
                _DashedDivider(),
                const SizedBox(height: AppSpacing.md),
                footer!,
              ],
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  receiptNumber,
                  style: AppTypography.mono.copyWith(color: tokens.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.primaryAction, width: 1.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'ODAA',
        style: AppTypography.caption.copyWith(
          color: tokens.primaryAction,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 4.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return SizedBox(
              width: dash,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.tokens.divider,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _TornTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // A gentle zig-zag along the top edge, ~4px deep.
    const zigzagHeight = 4.0;
    const segmentWidth = 12.0;
    final path = Path();
    path.moveTo(0, zigzagHeight);
    var x = 0.0;
    var up = false;
    while (x < size.width) {
      x += segmentWidth / 2;
      path.lineTo(
        x > size.width ? size.width : x,
        up ? zigzagHeight : 0,
      );
      up = !up;
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}