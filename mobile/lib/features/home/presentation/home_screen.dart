import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/date_display.dart';
import 'package:odaa_mobile/core/utils/money.dart';
import 'package:odaa_mobile/core/utils/payment_window.dart';
import 'package:odaa_mobile/features/home/data/models/home_summary.dart';
import 'package:odaa_mobile/features/home/domain/home_providers.dart';
import 'package:odaa_mobile/features/home/presentation/widgets/greeting_line.dart';
import 'package:odaa_mobile/features/home/presentation/widgets/next_meeting_line.dart';
import 'package:odaa_mobile/features/home/presentation/widgets/notice_teaser.dart';
import 'package:odaa_mobile/features/home/presentation/widgets/standing_block.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/growth_ring.dart';
import 'package:odaa_mobile/shared/widgets/odaa_tree.dart';
import 'package:odaa_mobile/shared/widgets/primary_button.dart';
import 'package:odaa_mobile/shared/widgets/refreshable_scroll.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(homeSummaryProvider);
    return async.when(
      loading: () => const _HomeSkeleton(),
      error: (_, __) => RefreshableScroll(
        onRefresh: () async {
          ref.invalidate(homeSummaryProvider);
          await ref.read(homeSummaryProvider.future);
        },
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: ErrorView(
            message: context.l10n.errorGeneric,
            onRetry: () => ref.invalidate(homeSummaryProvider),
          ),
        ),
      ),
      data: (summary) => _HomeBody(summary: summary),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final windowOpen = PaymentWindow.isAnyWindowOpen(DateTime.now());

    return RefreshableScroll(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.lg,
        AppSpacing.screenEdge,
        AppSpacing.xxxl,
      ),
      onRefresh: () async {
        ref.invalidate(homeSummaryProvider);
        await ref.read(homeSummaryProvider.future);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GreetingLine(firstName: ref.watch(firstNameProvider) ?? 'Member'),
          const SizedBox(height: AppSpacing.xl),

          // The tree
          const OdaaTree(height: 220),
          const SizedBox(height: AppSpacing.md),

          // The woven year band
          GrowthRing(months: summary.months),
          const SizedBox(height: AppSpacing.xxl),

          StandingBlock(
            amountOwed: summary.totalOwed,
            currency: summary.currency,
            monthsPaid: summary.monthsPaid,
            monthsTotal: summary.monthsTotal,
          ),
          const SizedBox(height: AppSpacing.xl),

          PrimaryButton(
            label: l10n.homePayNow(Money.etb(summary.totalOwed)),
            onPressed:
                summary.totalOwed > 0 ? () => context.goNamed('pay') : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            windowOpen
                ? l10n.paymentWindowOpen
                : l10n.paymentWindowClosed(_nextWindowDate()),
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: tokens.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxl),

          if (summary.latestNotice != null) ...[
            NoticeTeaserCard(
              notice: summary.latestNotice!,
              onTap: () {
                // Navigate to the announcements list
                context.goNamed('announcements');
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          if (summary.nextMeeting != null)
            NextMeetingLine(
              meeting: summary.nextMeeting!,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meeting detail — coming soon'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _nextWindowDate() {
    final now = DateTime.now();

    // nextOpenPeriod returns the Gregorian first-of-month of the payable due.
    // Its Ethiopian month's 27th is when the window opens.
    final dueGregorian = PaymentWindow.nextOpenPeriod(now);
    final dueEthiopian = EthiopianDate.fromGregorian(dueGregorian);

    // Convert (Ethiopian year, month, day 27) back to Gregorian so we can
    // hand a DateTime to DateDisplay.primary.
    final openGregorian =
        EthiopianDate.toGregorian(dueEthiopian.year, dueEthiopian.month, 27);

    return DateDisplay.primary(openGregorian);
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 120, height: 14),
          SizedBox(height: 8),
          Skeleton(width: 180, height: 28),
          SizedBox(height: 24),
          Skeleton(height: 220, radius: BorderRadius.all(Radius.circular(16))),
          SizedBox(height: 16),
          Skeleton(height: 8, radius: BorderRadius.all(Radius.circular(4))),
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: Skeleton(height: 48)),
              SizedBox(width: 16),
              Expanded(child: Skeleton(height: 48)),
            ],
          ),
          SizedBox(height: 24),
          Skeleton(height: 56),
        ],
      ),
    );
  }
}
