import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_motion.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';

class LanguageCard extends StatelessWidget {
  const LanguageCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $subtitle',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.scale(context, AppMotion.fast),
          curve: AppMotion.standard,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? tokens.statePaidBg : tokens.surface,
            borderRadius: AppRadii.md,
            border: Border.all(
              color: selected ? tokens.statePaid : tokens.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleS.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodyS.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: AppMotion.scale(context, AppMotion.fast),
                opacity: selected ? 1 : 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tokens.statePaid,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 18,
                    color: tokens.textOnPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}