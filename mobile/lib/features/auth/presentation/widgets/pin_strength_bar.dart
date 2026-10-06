import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_motion.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/auth/data/pin_strength.dart';

/// Three-segment strength indicator. Shows under the "new PIN" entry.
class PinStrengthBar extends StatelessWidget {
  const PinStrengthBar({
    required this.strength,
    required this.message,
    super.key,
  });

  final PinStrength strength;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final (filledCount, color) = switch (strength) {
      PinStrength.weak => (1, tokens.stateUnpaid),
      PinStrength.ok => (2, tokens.statePartial),
      PinStrength.strong => (3, tokens.statePaid),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final active = i < filledCount;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                child: AnimatedContainer(
                  duration: AppMotion.scale(context, AppMotion.fast),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? color : tokens.divider,
                    borderRadius: AppRadii.xs,
                  ),
                ),
              ),
            );
          }),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            style: AppTypography.caption.copyWith(color: tokens.textMuted),
          ),
        ],
      ],
    );
  }
}