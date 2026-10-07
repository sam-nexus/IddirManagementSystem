import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/money.dart';
import 'package:odaa_mobile/features/history/data/models/payment_record.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

class PaymentRowTile extends StatelessWidget {
  const PaymentRowTile({
    required this.record,
    required this.onTap,
    super.key,
  });

  final PaymentRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    final methodLabel = switch (record.method) {
      PaymentMethod.chapa => l10n.historyMethodChapa,
      PaymentMethod.cash => l10n.historyMethodCash,
      PaymentMethod.manual => l10n.historyMethodManual,
    };

    final dateLabel = _formatDate(record.paidAt);
    final statusColor = switch (record.status) {
      PaymentStatus.success => tokens.statePaid,
      PaymentStatus.pending => tokens.statePending,
      PaymentStatus.failed => tokens.stateUnpaid,
    };

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
              // Amount on the left — the biggest number on the row
              SizedBox(
                width: 96,
                child: Text(
                  Money.etbShort(record.amount),
                  style: AppTypography.moneyMedium.copyWith(
                    color: tokens.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      methodLabel,
                      style: AppTypography.bodyMedium.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: AppTypography.bodyS.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (record.status == PaymentStatus.pending)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Text(
                    l10n.statePending.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: statusColor,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}