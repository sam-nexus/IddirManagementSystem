import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

/// A thin horizontal band representing the year — one segment per month.
/// Months fill from left to right. Optional tap callback per month.
class GrowthRing extends StatelessWidget {
  const GrowthRing({
    required this.months,
    this.onMonthTapped,
    this.height = 8,
    super.key,
  });

  final List<ContributionState> months;
  final void Function(int index)? onMonthTapped;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Row(
          children: List.generate(months.length, (i) {
            final color = switch (months[i]) {
              ContributionState.paid => tokens.statePaid,
              ContributionState.partial => tokens.statePartial,
              ContributionState.unpaid => tokens.divider,
              ContributionState.waived => tokens.stateWaivedBg,
              ContributionState.pending => tokens.statePending,
              ContributionState.suspended => tokens.textMuted,
            };
            return Expanded(
              child: GestureDetector(
                onTap: onMonthTapped == null ? null : () => onMonthTapped!(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  color: color,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
