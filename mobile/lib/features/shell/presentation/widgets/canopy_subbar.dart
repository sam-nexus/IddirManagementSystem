import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_motion.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';

class CanopySegment {
  const CanopySegment({required this.label, required this.value});
  final String label;
  final String value;
}

class CanopySubbar extends StatelessWidget {
  const CanopySubbar({
    required this.segments,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<CanopySegment> segments;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        0,
        AppSpacing.screenEdge,
        AppSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: AppRadii.md,
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: segments.map((s) {
            final isSelected = s.value == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelected(s.value),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppMotion.scale(context, AppMotion.fast),
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? tokens.background : Colors.transparent,
                    borderRadius: AppRadii.sm,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    s.label,
                    style: AppTypography.caption.copyWith(
                      color: isSelected ? tokens.textPrimary : tokens.textMuted,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}