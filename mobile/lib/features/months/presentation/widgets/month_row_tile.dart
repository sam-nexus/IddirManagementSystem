import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/money.dart';
import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/month_leaf.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

class MonthRowTile extends StatelessWidget {
  const MonthRowTile({
    required this.row,
    required this.hasOlderUnpaid,
    required this.canPayNow,
    super.key,
  });

  final MonthRow row;
  final bool hasOlderUnpaid;
  final bool canPayNow;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isOm = Localizations.localeOf(context).languageCode == 'om';
    final monthName = isOm ? row.monthNameOm : row.monthNameEn;

    final display = row.resolveDisplayState(hasOlderUnpaid: hasOlderUnpaid);

    final (String badgeLabel, ContributionState badgeState) = switch (display) {
      DisplayState.paid => (l10n.statePaid, ContributionState.paid),
      DisplayState.unpaid => (l10n.stateUnpaid, ContributionState.unpaid),
      DisplayState.suspended =>
        (l10n.stateSuspended, ContributionState.suspended),
      DisplayState.comingSoon =>
        (l10n.stateComingSoon, ContributionState.pending),
    };

    final trailingAmount = switch (display) {
      DisplayState.paid => Money.etb(row.amountDue),
      DisplayState.unpaid => Money.etb(row.outstandingWithPenalty),
      DisplayState.suspended => l10n.monthsSuspendedHint,
      DisplayState.comingSoon => '',
    };

    final leafState = switch (display) {
      DisplayState.paid => ContributionState.paid,
      DisplayState.unpaid => ContributionState.unpaid,
      DisplayState.suspended => ContributionState.suspended,
      DisplayState.comingSoon => ContributionState.pending,
    };

    return Semantics(
      button: true,
      label: '$monthName, $badgeLabel',
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.screenEdge,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 36,
                child: MonthLeaf(
                  state: leafState,
                  size: 28,
                  isCurrentMonth: row.isCurrentMonth,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthName,
                      style: AppTypography.titleS.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trailingAmount,
                      style: AppTypography.bodyS.copyWith(
                        color: display == DisplayState.unpaid
                            ? tokens.stateUnpaid
                            : tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (canPayNow)
                _PayButton(
                  label: l10n.monthsPay,
                  onTap: () => context.goNamed(
                    'pay',
                    queryParameters: {
                      'period': row.period.toIso8601String().split('T').first,
                    },
                  ),
                )
              else
                StatusChip(
                  state: badgeState,
                  label: badgeLabel,
                  dense: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: 34,
      child: Material(
        color: tokens.primaryAction,
        borderRadius: AppRadii.sm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: tokens.textOnPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}