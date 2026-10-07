import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';

enum ContributionState { paid, unpaid, waived, pending, suspended }

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.state,
    required this.label,
    this.dense = false,
    super.key,
  });

  final ContributionState state;
  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (fg, bg) = switch (state) {
      ContributionState.paid => (tokens.statePaid, tokens.statePaidBg),
      ContributionState.unpaid => (tokens.stateUnpaid, tokens.stateUnpaidBg),
      ContributionState.waived => (tokens.stateWaived, tokens.stateWaivedBg),
      ContributionState.pending => (tokens.statePending, tokens.statePendingBg),
      ContributionState.suspended => (tokens.textMuted, tokens.surfaceAlt),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: fg,
          fontSize: dense ? 10 : 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}