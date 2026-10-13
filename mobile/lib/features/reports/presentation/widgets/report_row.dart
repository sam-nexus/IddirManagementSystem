import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/money.dart';
import 'package:odaa_mobile/features/reports/data/models/report.dart';

class ReportRow extends StatelessWidget {
  const ReportRow({
    required this.report,
    required this.isOm,
    required this.onTap,
    super.key,
  });

  final Report report;
  final bool isOm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final balance = report.balance;
    final balanceColor = balance >= 0 ? tokens.statePaid : tokens.stateUnpaid;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.screenEdge,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title(isOm),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleS.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _periodLabel(report, isOm),
                      style: AppTypography.bodyS.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.etbShort(balance),
                    style: AppTypography.moneyMedium.copyWith(
                      color: balanceColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOm ? 'Hafte' : 'Balance',
                    style: AppTypography.caption.copyWith(
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: tokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _periodLabel(Report report, bool isOm) {
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const monthsOm = [
      'Ama', 'Gur', 'Bit', 'Elb', 'Cam', 'Wax',
      'Ado', 'Hag', 'Ful', 'Onk', 'Sad', 'Mud',
    ];
    final months = isOm ? monthsOm : monthsEn;
    final s = report.periodStart;
    final e = report.periodEnd;
    return '${months[s.month - 1]} – ${months[e.month - 1]} ${e.year}';
  }
}