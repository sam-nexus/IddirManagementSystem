import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';

/// Shown at the top of the PIN step when the account is locked.
/// The caller passes the remaining minutes; the banner just renders.
class LockedBanner extends StatelessWidget {
  const LockedBanner({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tokens.stateUnpaidBg,
        borderRadius: AppRadii.md,
        border: Border.all(color: tokens.stateUnpaid, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_clock_outlined,
                  size: 20, color: tokens.stateUnpaid,),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.titleS.copyWith(
                  color: tokens.stateUnpaid,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppTypography.bodyS.copyWith(
              color: tokens.stateUnpaid,
            ),
          ),
        ],
      ),
    );
  }
}