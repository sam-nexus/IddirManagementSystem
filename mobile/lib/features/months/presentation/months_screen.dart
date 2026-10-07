import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/features/months/domain/months_providers.dart';
import 'package:odaa_mobile/features/months/presentation/widgets/month_row_tile.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';

class MonthsScreen extends ConsumerWidget {
  const MonthsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(yearMonthsProvider);
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.lg,
            AppSpacing.screenEdge,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.monthsTitle,
                style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.monthsSubtitle,
                style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: async.when(
            loading: () => const _MonthsSkeleton(),
            error: (_, __) => ErrorView(
              message: l10n.errorGeneric,
              onRetry: () => ref.invalidate(yearMonthsProvider),
            ),
            data: (rows) => _MonthsList(rows: rows),
          ),
        ),
      ],
    );
  }
}

class _MonthsList extends ConsumerWidget {
  const _MonthsList({required this.rows});

  final List<MonthRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final windowOpen = PaymentWindow.isAnyWindowOpen(now);

    // The single actionable month is the first one that is unpaid/partial.
    int? payIndex;
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].isUnpaidOrPartial) {
        payIndex = i;
        break;
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
      itemBuilder: (context, i) {
        final row = rows[i];

        // hasOlderUnpaid — any earlier row that is unpaid or partial.
        final hasOlderUnpaid = rows
            .take(i)
            .any((r) => r.isUnpaidOrPartial);

        // canPayNow — only the oldest unpaid month, and only if its window is open.
        final isOldestUnpaid = payIndex == i;
        final canPayNow =
            isOldestUnpaid && windowOpen && row.isUnpaidOrPartial;

        return MonthRowTile(
          row: row,
          hasOlderUnpaid: hasOlderUnpaid,
          canPayNow: canPayNow,
        );
      },
    );
  }
}

class _MonthsSkeleton extends StatelessWidget {
  const _MonthsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const Row(
        children: [
          Skeleton(width: 28, height: 36, radius: BorderRadius.all(Radius.circular(4))),
          SizedBox(width: 16),
          Expanded(child: Skeleton(height: 16)),
          SizedBox(width: 16),
          Skeleton(width: 56, height: 20, radius: BorderRadius.all(Radius.circular(4))),
        ],
      ),
    );
  }
}