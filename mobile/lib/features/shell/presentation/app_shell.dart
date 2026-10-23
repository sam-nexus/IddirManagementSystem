import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/features/months/domain/months_providers.dart';
import 'package:odaa_mobile/features/shell/presentation/widgets/canopy_bar.dart';
import 'package:odaa_mobile/features/shell/presentation/widgets/canopy_subbar.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    required this.section,
    required this.child,
    super.key,
  });

  final CanopySection section;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: tokens.background,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),

          // Only the Months section keeps a contextual sub-bar.
          if (widget.section == CanopySection.months)
            Consumer(
              builder: (context, ref, _) {
                final segment = ref.watch(monthsSegmentProvider);
                return CanopySubbar(
                  segments: [
                    CanopySegment(
                      label: l10n.monthsThisYear,
                      value: 'this_year',
                    ),
                    CanopySegment(
                      label: l10n.monthsPastYears,
                      value: 'past_years',
                    ),
                    CanopySegment(
                      label: l10n.monthsReceipts,
                      value: 'receipts',
                    ),
                  ],
                  selected: segment,
                  onSelected: (v) {
                    ref.read(monthsSegmentProvider.notifier).state = v;
                    if (v == 'receipts') {
                      context.goNamed('history');
                    } else if (v == 'this_year') {
                      ref.read(selectedYearProvider.notifier).state =
                          EthiopianDate.fromGregorian(DateTime.now()).year;
                      context.goNamed('months');
                    } else {
                      // Past years — if we have any, select the most recent.
                      final years =
                          ref.read(availableYearsProvider).valueOrNull ?? [];
                      final pastYears =
                          years.where((y) => y != DateTime.now().year).toList();
                      if (pastYears.isNotEmpty) {
                        ref.read(selectedYearProvider.notifier).state =
                            pastYears.first;
                      }
                      context.goNamed('months');
                    }
                  },
                );
              },
            ),

          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: CanopyBar(
        selected: widget.section,
        onSelect: (s) {
          switch (s) {
            case CanopySection.home:
              context.goNamed('home');
            case CanopySection.months:
              context.goNamed('months');
            case CanopySection.pay:
              context.goNamed('pay');
            case CanopySection.more:
              context.goNamed('more');
          }
        },
      ),
    );
  }
}
