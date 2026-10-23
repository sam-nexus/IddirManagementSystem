import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/features/months/domain/months_providers.dart';
import 'package:odaa_mobile/features/months/presentation/widgets/month_row_tile.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/refreshable_scroll.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';
// ---------------------------------------------------------------------------
// Ethiopian month ordering helper (top-level, used by both views below)
// ---------------------------------------------------------------------------

/// The Gregorian month numbers in Ethiopian calendar order.
/// Ethiopian year starts in September, so the sequence is:
/// Sep, Oct, Nov, Dec, Jan, Feb, Mar, Apr, May, Jun, Jul, Aug.
const _ethiopianMonthOrder = <int>[
  9,
  10,
  11,
  12,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
];

/// Returns 0 for September, 1 for October, … 11 for August.
/// Used to sort months in Ethiopian order regardless of Gregorian numbering.
int _ethiopianMonthIndex(DateTime period) {
  final i = _ethiopianMonthOrder.indexOf(period.month);
  return i < 0 ? 99 : i;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MonthsScreen extends ConsumerWidget {
  const MonthsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(monthsSegmentProvider);

    if (segment == 'past_years') {
      return const _PastYearsView();
    }

    return const _ThisYearView();
  }
}

// ---------------------------------------------------------------------------
// THIS YEAR
// ---------------------------------------------------------------------------
class _ThisYearView extends ConsumerWidget {
  const _ThisYearView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final async = ref.watch(yearMonthsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        Expanded(
          child: async.when(
            loading: () => const _MonthsSkeleton(),
            error: (_, __) => ErrorView(
              message: l10n.errorGeneric,
              onRetry: () => ref.invalidate(allMonthsProvider),
            ),
            data: (rows) {
              final nothingHere = rows.isEmpty ||
                  rows.every(
                    (r) =>
                        r.state == ContributionState.waived && r.amountDue == 0,
                  );

              if (nothingHere) {
                return RefreshableScroll(
                  onRefresh: () async {
                    ref.invalidate(allMonthsProvider);
                    await ref.read(allMonthsProvider.future);
                  },
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: EmptyView(
                      title: l10n.monthsNothingThisYear,
                      body: l10n.monthsNothingThisYearBody,
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),
                );
              }

              return _MonthsList(rows: rows);
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PAST YEARS
// ---------------------------------------------------------------------------
class _PastYearsView extends ConsumerWidget {
  const _PastYearsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final async = ref.watch(yearMonthsProvider);
    final yearsAsync = ref.watch(availableYearsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

        // Year strip — only shown if there is prior-year data.
        yearsAsync.when(
          loading: () => const SizedBox(height: 56),
          error: (_, __) => const SizedBox.shrink(),
          data: (years) {
            // Get the current Ethiopian year
            final ethNow = EthiopianDate.fromGregorian(DateTime.now());

            // Filter out the current Ethiopian year
            final pastYears = years.where((y) => y != ethNow.year).toList();

            if (pastYears.isEmpty) return const SizedBox.shrink();
            return _YearStrip(years: pastYears);
          },
        ),

        Expanded(
          child: async.when(
            loading: () => const _MonthsSkeleton(),
            error: (_, __) => ErrorView(
              message: l10n.errorGeneric,
              onRetry: () => ref.invalidate(allMonthsProvider),
            ),
            data: (rows) {
              // If we have no rows OR every row is a placeholder (waived with
              // zero amount), the member has no history for the selected year.
              final nothingHere = rows.isEmpty ||
                  rows.every(
                    (r) =>
                        r.state == ContributionState.waived && r.amountDue == 0,
                  );

              if (nothingHere) {
                return RefreshableScroll(
                  onRefresh: () async {
                    ref.invalidate(allMonthsProvider);
                    await ref.read(allMonthsProvider.future);
                  },
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: EmptyView(
                      title: l10n.pastYearsEmpty,
                      body: l10n.pastYearsEmptyBody,
                      icon: Icons.history_outlined,
                    ),
                  ),
                );
              }

              return _MonthsList(rows: rows);
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// YEAR STRIP
// ---------------------------------------------------------------------------
class _YearStrip extends ConsumerWidget {
  const _YearStrip({required this.years});

  final List<int> years;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final selected = ref.watch(selectedYearProvider);

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenEdge,
          vertical: AppSpacing.sm,
        ),
        itemCount: years.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final y = years[i];
          final isSelected = y == selected;
          return Material(
            color: isSelected ? tokens.primaryAction : tokens.surfaceAlt,
            borderRadius: AppRadii.sm,
            child: InkWell(
              borderRadius: AppRadii.sm,
              onTap: () => ref.read(selectedYearProvider.notifier).state = y,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Center(
                  child: Text(
                    '$y',
                    style: AppTypography.label.copyWith(
                      color: isSelected
                          ? tokens.textOnPrimary
                          : tokens.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MONTHS LIST
// ---------------------------------------------------------------------------
class _MonthsList extends ConsumerWidget {
  const _MonthsList({required this.rows});

  final List<MonthRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final windowOpen = PaymentWindow.isAnyWindowOpen(now);

    // Sort by Ethiopian month order.
    int cmp(MonthRow a, MonthRow b) => _ethiopianMonthIndex(a.period)
        .compareTo(_ethiopianMonthIndex(b.period));

    final paid = rows.where((r) => r.isFullyPaid).toList()..sort(cmp);
    final unpaid = rows.where((r) => !r.isFullyPaid).toList()..sort(cmp);

    // Rotate unpaid so it starts after the newest paid month.
    List<MonthRow> rotatedUnpaid = unpaid;
    if (paid.isNotEmpty && unpaid.isNotEmpty) {
      final lastPaidIdx = _ethiopianMonthIndex(paid.last.period);
      final startIndex = unpaid.indexWhere(
        (r) => _ethiopianMonthIndex(r.period) > lastPaidIdx,
      );
      if (startIndex > 0) {
        rotatedUnpaid = [
          ...unpaid.sublist(startIndex),
          ...unpaid.sublist(0, startIndex),
        ];
      }
    }

    final ordered = [...paid, ...rotatedUnpaid];

    final oldestUnpaid = unpaid.isNotEmpty ? unpaid.first : null;
    final oldestUnpaidKey = oldestUnpaid == null
        ? null
        : '${oldestUnpaid.period.year}-${oldestUnpaid.period.month}';

    return RefreshIndicator(
      color: context.tokens.primaryAction,
      backgroundColor: context.tokens.surface,
      onRefresh: () async {
        ref.invalidate(allMonthsProvider);
        await ref.read(allMonthsProvider.future);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        itemCount: ordered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
        itemBuilder: (context, i) {
          final row = ordered[i];
          final rowKey = '${row.period.year}-${row.period.month}';
          final rowEthIdx = _ethiopianMonthIndex(row.period);

          final hasOlderUnpaid = unpaid.any(
            (r) => _ethiopianMonthIndex(r.period) < rowEthIdx,
          );

          final isOldestUnpaid = oldestUnpaidKey == rowKey;
          final canPayNow = isOldestUnpaid && windowOpen && row.isUnpaid;

          return MonthRowTile(
            row: row,
            hasOlderUnpaid: hasOlderUnpaid,
            canPayNow: canPayNow,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SKELETON
// ---------------------------------------------------------------------------
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
          Skeleton(
            width: 28,
            height: 36,
            radius: BorderRadius.all(Radius.circular(4)),
          ),
          SizedBox(width: 16),
          Expanded(child: Skeleton(height: 16)),
          SizedBox(width: 16),
          Skeleton(
            width: 56,
            height: 20,
            radius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}
