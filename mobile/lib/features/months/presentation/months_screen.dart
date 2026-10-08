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
import 'package:odaa_mobile/shared/widgets/skeleton.dart';

class MonthsScreen extends ConsumerWidget {
  const MonthsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(monthsSegmentProvider);

    if (segment == 'past_years') {
      return const _PastYearsView();
    }

    // Default: this year.
    return const _ThisYearView();
  }
}

// ============================================================================
// THIS YEAR — always shows the current year's months.
// ============================================================================
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
        const _MonthsHeader(),
        Expanded(
          child: async.when(
            loading: () => const _MonthsSkeleton(),
            error: (_, __) => ErrorView(
              message: l10n.errorGeneric,
              onRetry: () => ref.invalidate(allMonthsProvider),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return EmptyView(
                  title: l10n.monthsNothingThisYear,
                  body: l10n.monthsNothingThisYearBody,
                  icon: Icons.calendar_today_outlined,
                );
              }
              return _MonthsList(rows: rows, showPayButton: true);
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PAST YEARS — shows a year strip + the selected year, or an empty state.
// ============================================================================
class _PastYearsView extends ConsumerWidget {
  const _PastYearsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final yearsAsync = ref.watch(availableYearsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MonthsHeader(),
        Expanded(
          child: yearsAsync.when(
            loading: () => const _MonthsSkeleton(),
            error: (_, __) => ErrorView(
              message: l10n.errorGeneric,
              onRetry: () => ref.invalidate(allMonthsProvider),
            ),
            data: (allYears) {
              // Past years = every year that isn't the current one.
              final currentYear = DateTime.now().year;
              final pastYears =
                  allYears.where((y) => y != currentYear).toList();

              if (pastYears.isEmpty) {
                return EmptyView(
                  title: l10n.pastYearsEmpty,
                  body: l10n.pastYearsEmptyBody,
                  icon: Icons.history_outlined,
                );
              }

              // If the currently selected year is not in the list, snap
              // it to the newest past year.
              final selected = ref.watch(selectedYearProvider);
              if (!pastYears.contains(selected)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(selectedYearProvider.notifier).state =
                      pastYears.first;
                });
              }

              // Ensure the selected year is a past year when this screen
              // is entered.
              final activeYear =
                  pastYears.contains(selected) ? selected : pastYears.first;

              return _PastYearsContent(
                years: pastYears,
                activeYear: activeYear,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PastYearsContent extends ConsumerWidget {
  const _PastYearsContent({
    required this.years,
    required this.activeYear,
  });

  final List<int> years;
  final int activeYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch the rows for the active past year.
    final async = ref.watch(yearMonthsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _YearStrip(years: years, activeYear: activeYear),
        Expanded(
          child: async.when(
            loading: () => const _MonthsSkeleton(),
            error: (_, __) => ErrorView(
              message: context.l10n.errorGeneric,
              onRetry: () => ref.invalidate(allMonthsProvider),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return EmptyView(
                  title: context.l10n.pastYearsEmpty,
                  body: context.l10n.pastYearsEmptyBody,
                  icon: Icons.history_outlined,
                );
              }
              return _MonthsList(rows: rows, showPayButton: false);
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Shared header + year strip + list + skeleton
// ============================================================================
class _MonthsHeader extends StatelessWidget {
  const _MonthsHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    return Padding(
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
    );
  }
}

class _YearStrip extends ConsumerWidget {
  const _YearStrip({required this.years, required this.activeYear});

  final List<int> years;
  final int activeYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

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
          final isSelected = y == activeYear;
          return Material(
            color: isSelected ? tokens.primaryAction : tokens.surfaceAlt,
            borderRadius: AppRadii.sm,
            child: InkWell(
              borderRadius: AppRadii.sm,
              onTap: () =>
                  ref.read(selectedYearProvider.notifier).state = y,
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

class _MonthsList extends ConsumerWidget {
  const _MonthsList({
    required this.rows,
    required this.showPayButton,
  });

  final List<MonthRow> rows;

  /// Whether a Pay button can appear on this list. Only the current year
  /// allows paying; past years are read-only history.
  final bool showPayButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final windowOpen = PaymentWindow.isAnyWindowOpen(now);

    // Paid block: ascending.
    final paid = rows.where((r) => r.isFullyPaid).toList()
      ..sort((a, b) => a.period.compareTo(b.period));

    // Unpaid block: ascending.
    final unpaid = rows.where((r) => !r.isFullyPaid).toList()
      ..sort((a, b) => a.period.compareTo(b.period));

    // Rotate unpaid so it starts after the newest paid month.
    List<MonthRow> rotatedUnpaid = unpaid;
    if (paid.isNotEmpty && unpaid.isNotEmpty) {
      final lastPaid = paid.last;
      final startIndex = unpaid.indexWhere(
        (r) => r.period.isAfter(lastPaid.period),
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

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      itemCount: ordered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
      itemBuilder: (context, i) {
        final row = ordered[i];
        final rowKey = '${row.period.year}-${row.period.month}';

        final hasOlderUnpaid = unpaid.any(
          (r) => '${r.period.year}-${r.period.month}'.compareTo(rowKey) < 0,
        );

        final isOldestUnpaid = oldestUnpaidKey == rowKey;
        final canPayNow = showPayButton &&
            isOldestUnpaid &&
            windowOpen &&
            row.isUnpaid;

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