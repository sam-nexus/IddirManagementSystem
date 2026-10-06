import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_motion.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';

/// A row of dots that shows how many digits have been entered.
/// Reused by PinPad and by screens that display a PIN count without input.
class PinDots extends StatelessWidget {
  const PinDots({
    required this.length,
    required this.filled,
    this.dotSize = 16,
    this.spacing = 20,
    super.key,
  });

  final int length;
  final int filled;
  final double dotSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i < filled;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: AnimatedContainer(
            duration: AppMotion.scale(context, AppMotion.fast),
            curve: AppMotion.standard,
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? tokens.primaryAction : Colors.transparent,
              border: Border.all(
                color: active ? tokens.primaryAction : tokens.divider,
                width: 2,
              ),
            ),
          ),
        );
      }),
    );
  }
}