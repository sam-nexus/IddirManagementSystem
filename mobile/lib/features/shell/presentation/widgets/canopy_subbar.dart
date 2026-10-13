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
    this.scrollable = false,
    super.key,
  });

  final List<CanopySegment> segments;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        0,
        0,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: 44,
        child: scrollable
            ? ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                itemCount: segments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => _pill(context, segments[i]),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: tokens.surfaceAlt,
                    borderRadius: AppRadii.md,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: segments
                        .map((s) => Expanded(child: _segment(context, s)))
                        .toList(),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _segment(BuildContext context, CanopySegment s) {
    final tokens = context.tokens;
    final isSelected = s.value == selected;
    return GestureDetector(
      onTap: () => onSelected(s.value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.scale(context, AppMotion.fast),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? tokens.background : Colors.transparent,
          borderRadius: AppRadii.sm,
        ),
        child: Text(
          s.label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? tokens.textPrimary : tokens.textMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, CanopySegment s) {
    final tokens = context.tokens;
    final isSelected = s.value == selected;
    return Material(
      color: isSelected ? tokens.primaryAction : tokens.surfaceAlt,
      borderRadius: AppRadii.sm,
      child: InkWell(
        borderRadius: AppRadii.sm,
        onTap: () => onSelected(s.value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Center(
            child: Text(
              s.label,
              style: AppTypography.caption.copyWith(
                color: isSelected
                    ? tokens.textOnPrimary
                    : tokens.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}