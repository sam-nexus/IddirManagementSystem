import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/payment_window.dart';
import 'package:odaa_mobile/features/history/domain/history_providers.dart';
import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/features/months/domain/months_providers.dart';
import 'package:odaa_mobile/features/months/presentation/widgets/month_row_tile.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/refreshable_scroll.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

class MonthsScreen extends ConsumerWidget {
  const MonthsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(monthsSegmentProvider);
    if (segment == 'past_years') return const _PastYearsView();
    return const _ThisYearView();
  }
}

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
        _buildHeader(l10n, tokens, showSubtitle: true),
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
              if (nothingHere) return _buildEmptyState(ref, l10n, false);
              return _MonthsList(rows: rows);
            },
          ),
        ),
      ],
    );
  }
}

class _PastYearsView extends ConsumerStatefulWidget {
  const _PastYearsView();

  @override
  ConsumerState<_PastYearsView> createState() => _PastYearsViewState();
}

class _PastYearsViewState extends ConsumerState<_PastYearsView> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final yearsAsync = ref.watch(availableYearsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedYear == null)
          _buildHeader(l10n, tokens, showSubtitle: true)
        else
          // FIX 2: Specific year title shows ONLY the year (no subtitle)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenEdge,
              AppSpacing.lg,
              AppSpacing.screenEdge,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() => _selectedYear = null);
                    ref.read(selectedYearProvider.notifier).state =
                        EthiopianDate.fromGregorian(DateTime.now()).year;
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  '$_selectedYear',
                  style:
                      AppTypography.titleL.copyWith(color: tokens.textPrimary),
                ),
              ],
            ),
          ),
        Expanded(
          child: yearsAsync.when(
            loading: () => const _MonthsSkeleton(),
            error: (_, __) => ErrorView(
              message: l10n.errorGeneric,
              onRetry: () => ref.invalidate(allMonthsProvider),
            ),
            data: (years) {
              final ethNow = EthiopianDate.fromGregorian(DateTime.now());
              final pastYears = years.where((y) => y != ethNow.year).toList()
                ..sort((a, b) => b.compareTo(a));

              if (_selectedYear != null) {
                final yearAsync = ref.watch(yearMonthsProvider);
                return yearAsync.when(
                  loading: () => const _MonthsSkeleton(),
                  error: (_, __) =>
                      ErrorView(message: l10n.errorGeneric, onRetry: () {}),
                  data: (rows) {
                    final nothingHere = rows.isEmpty ||
                        rows.every(
                          (r) =>
                              r.state == ContributionState.waived &&
                              r.amountDue == 0,
                        );
                    if (nothingHere) return _buildEmptyState(ref, l10n, true);
                    return _MonthsList(rows: rows);
                  },
                );
              }

              if (pastYears.isEmpty) return _buildEmptyState(ref, l10n, true);

              return RefreshIndicator(
                color: tokens.primaryAction,
                backgroundColor: tokens.surface,
                onRefresh: () async {
                  ref.invalidate(allMonthsProvider);
                  await ref.read(allMonthsProvider.future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  itemCount: pastYears.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: AppSpacing.screenEdge),
                  itemBuilder: (context, i) {
                    final y = pastYears[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenEdge,
                        vertical: 8,
                      ),
                      title: Text(
                        '$y',
                        style: AppTypography.titleM
                            .copyWith(color: tokens.textPrimary),
                      ),
                      trailing:
                          Icon(Icons.chevron_right, color: tokens.textMuted),
                      onTap: () {
                        setState(() => _selectedYear = y);
                        ref.read(selectedYearProvider.notifier).state = y;
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget _buildHeader(
  dynamic l10n,
  dynamic tokens, {
  required bool showSubtitle,
}) {
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
        if (showSubtitle) ...[
          const SizedBox(height: 2),
          Text(
            l10n.monthsSubtitle,
            style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
          ),
        ],
      ],
    ),
  );
}

Widget _buildEmptyState(WidgetRef ref, dynamic l10n, bool isPast) {
  return RefreshableScroll(
    onRefresh: () async {
      ref.invalidate(allMonthsProvider);
      await ref.read(allMonthsProvider.future);
    },
    child: SizedBox(
      height: 500,
      child: EmptyView(
        title: isPast ? l10n.pastYearsEmpty : l10n.monthsNothingThisYear,
        body: isPast ? l10n.pastYearsEmptyBody : l10n.monthsNothingThisYearBody,
        icon: isPast ? Icons.history_outlined : Icons.calendar_today_outlined,
      ),
    ),
  );
}

class _MonthsList extends ConsumerWidget {
  const _MonthsList({required this.rows});
  final List<MonthRow> rows;

  int _ethIndex(DateTime p) {
    const order = [9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8];
    return order.indexOf(p.month);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    int cmp(MonthRow a, MonthRow b) =>
        _ethIndex(a.period).compareTo(_ethIndex(b.period));

    final paid = rows.where((r) => r.isFullyPaid).toList()..sort(cmp);
    final unpaid = rows.where((r) => !r.isFullyPaid).toList()..sort(cmp);

    List<MonthRow> rotatedUnpaid = unpaid;
    if (paid.isNotEmpty && unpaid.isNotEmpty) {
      final lastPaidIdx = _ethIndex(paid.last.period);
      final startIndex =
          unpaid.indexWhere((r) => _ethIndex(r.period) > lastPaidIdx);
      if (startIndex > 0) {
        rotatedUnpaid = [
          ...unpaid.sublist(startIndex),
          ...unpaid.sublist(0, startIndex),
        ];
      }
    }

    final ordered = [...paid, ...rotatedUnpaid];
    final oldestUnpaid = unpaid.isNotEmpty ? unpaid.first : null;

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
          final hasOlder = oldestUnpaid != null &&
              _ethIndex(row.period) < _ethIndex(oldestUnpaid.period);

          final ethYear =
              row.period.month >= 9 ? row.period.year - 7 : row.period.year - 8;
          final windowOpen = PaymentWindow.isOpenFor(
            ethMonth: row.ethiopianMonthIndex,
            ethYear: ethYear,
            now: now,
          );

          VoidCallback? onReceipt;
          if (row.isFullyPaid) {
            onReceipt = () async {
              final periodIso = row.period.toIso8601String().split('T').first;
              final repo = ref.read(historyRepositoryProvider);

              // Show a tiny loading indicator (optional, but good UX)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Loading receipt...'),
                  duration: Duration(seconds: 1),
                ),
              );

              final paymentId = await repo.fetchPaymentIdForPeriod(periodIso);

              if (!context.mounted) return;
              if (paymentId != null) {
                context.goNamed('receipt', pathParameters: {'id': paymentId});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receipt not found for this month'),
                  ),
                );
              }
            };
          }

          return MonthRowTile(
            row: row,
            hasOlderUnpaid: hasOlder,
            windowOpen: windowOpen,
            onReceiptTap: onReceipt,
          );
        },
      ),
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
