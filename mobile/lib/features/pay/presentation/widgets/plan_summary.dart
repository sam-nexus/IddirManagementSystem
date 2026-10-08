import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/money.dart';
import 'package:odaa_mobile/features/payments/data/models/payment_plan.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

class PlanSummary extends StatelessWidget {
  const PlanSummary({required this.plan, super.key});

  final PaymentPlan plan;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: AppRadii.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(
            context,
            label: l10n.payDues,
            value: Money.etb(plan.duesTotal),
          ),
          if (plan.penaltiesTotal > 0)
            _row(
              context,
              label: l10n.payPenalties,
              value: Money.etb(plan.penaltiesTotal),
              valueColor: tokens.stateUnpaid,
            ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: tokens.divider),
          const SizedBox(height: AppSpacing.md),
          _row(
            context,
            label: l10n.payTotal,
            value: Money.etb(plan.total),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required String value,
    bool bold = false,
    Color? valueColor,
  }) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (bold ? AppTypography.titleS : AppTypography.bodyS)
                  .copyWith(color: tokens.textSecondary),
            ),
          ),
          Text(
            value,
            style: (bold ? AppTypography.titleS : AppTypography.bodyMedium)
                .copyWith(color: valueColor ?? tokens.textPrimary),
          ),
        ],
      ),
    );
  }
}
