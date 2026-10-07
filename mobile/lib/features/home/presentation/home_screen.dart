import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/money.dart';
import 'package:odaa_mobile/features/home/data/models/home_summary.dart';
import 'package:odaa_mobile/features/home/domain/home_providers.dart';
import 'package:odaa_mobile/features/home/presentation/widgets/greeting_line.dart';
import 'package:odaa_mobile/features/home/presentation/widgets/next_meeting_line.dart';
import 'package:odaa_mobile/features/home/presentation/widgets/notice_teaser.dart';
import 'package:odaa_mobile/features/home/presentation/widgets/standing_block.dart';
import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/growth_ring.dart';
import 'package:odaa_mobile/shared/widgets/odaa_tree.dart';
import 'package:odaa_mobile/shared/widgets/primary_button.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final tokens = context.tokens;
    final async = ref.watch(homeSummaryProvider);

    return async.when(
      loading: () => const _HomeSkeleton(),
      error: (e, _) => ErrorView(
        message: context.l10n.errorGeneric,
        onRetry: () => ref.invalidate(homeSummaryProvider),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.lg,
        AppSpacing.screenEdge,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GreetingLine(firstName: summary.firstName),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Announcement detail — coming soon'),
                  ),
                );
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
    final open = DateTime(now.year, now.month, 27);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${open.day} ${months[open.month - 1]}';
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
