import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/support/data/models/support_request.dart';

class SupportStatusChip extends StatelessWidget {
  const SupportStatusChip({required this.status, super.key});

  final SupportStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (label, fg, bg) = switch (status) {
      SupportStatus.pending => ('PENDING', tokens.statePending, tokens.statePendingBg),
      SupportStatus.underReview => ('IN REVIEW', tokens.statePartial, tokens.statePartialBg),
      SupportStatus.approved => ('APPROVED', tokens.statePaid, tokens.statePaidBg),
      SupportStatus.rejected => ('REJECTED', tokens.stateUnpaid, tokens.stateUnpaidBg),
      SupportStatus.paid => ('PAID', tokens.statePaid, tokens.statePaidBg),
      SupportStatus.cancelled => ('CANCELLED', tokens.textMuted, tokens.surfaceAlt),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.sm),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontSize: 10,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}