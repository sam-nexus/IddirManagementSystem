import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/money.dart';
import 'package:odaa_mobile/features/reports/domain/reports_providers.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isOm = Localizations.localeOf(context).languageCode == 'om';
    final async = ref.watch(reportProvider(id));

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorView(
          message: l10n.errorGeneric,
          onRetry: () => ref.invalidate(reportProvider(id)),
        ),
        data: (report) {
          if (report == null) {
            return EmptyView(
              title: l10n.reportsEmpty,
              icon: Icons.assessment_outlined,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenEdge,
              AppSpacing.xl,
              AppSpacing.screenEdge,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  report.title(isOm),
                  style: AppTypography.titleL.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _periodLabel(report, isOm),
                  style: AppTypography.bodyS.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                _Row(
                  label: l10n.reportIncome,
                  value: Money.etb(report.income),
                  positive: true,
                ),
                _Row(
                  label: l10n.reportExpenses,
                  value: Money.etb(report.expenses),
                  negative: true,
                ),
                _Row(
                  label: l10n.reportPayouts,
                  value: Money.etb(report.payouts),
                  negative: true,
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: tokens.divider),
                const SizedBox(height: AppSpacing.md),
                _Row(
                  label: l10n.reportBalance,
                  value: Money.etb(report.balance),
                  bold: true,
                  positive: report.balance >= 0,
                  negative: report.balance < 0,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _periodLabel(dynamic report, bool isOm) {
    const monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const monthsOm = [
      'Amajjii', 'Guraandhala', 'Bitooteessa', 'Elbaa', 'Caamsa', 'Waxabajjii',
      'Adooleessa', 'Hagayya', 'Fuulbana', 'Onkololeessa', 'Sadaasa', 'Muddee',
    ];
    final months = isOm ? monthsOm : monthsEn;
    final s = report.periodStart as DateTime;
    final e = report.periodEnd as DateTime;
    return '${s.day} ${months[s.month - 1]} ${s.year} – ${e.day} ${months[e.month - 1]} ${e.year}';
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
    this.positive = false,
    this.negative = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool positive;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = positive
        ? tokens.statePaid
        : negative
            ? tokens.stateUnpaid
            : tokens.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  (bold ? AppTypography.titleS : AppTypography.bodyS).copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: (bold ? AppTypography.moneyMedium : AppTypography.bodyMedium)
                .copyWith(color: color),
          ),
        ],
      ),
    );
  }
}