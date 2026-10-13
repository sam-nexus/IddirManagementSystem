import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/announcements/data/models/announcement.dart';
import 'package:odaa_mobile/features/announcements/domain/announcements_providers.dart';
import 'package:odaa_mobile/features/announcements/presentation/widgets/announcement_row.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/refreshable_scroll.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isOm = Localizations.localeOf(context).languageCode == 'om';
    final async = ref.watch(announcementsProvider);

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
                l10n.announcementsTitle,
                style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.announcementsSubtitle,
                style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const _AnnouncementsSkeleton(),
            error: (_, __) => ErrorView(
              message: l10n.errorGeneric,
              onRetry: () => ref.invalidate(announcementsProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return RefreshableScroll(
                  onRefresh: () async {
                    ref.invalidate(announcementsProvider);
                    await ref.read(announcementsProvider.future);
                  },
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: EmptyView(
                      title: l10n.announcementsEmpty,
                      body: l10n.announcementsEmptyBody,
                      icon: Icons.campaign_outlined,
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                color: tokens.primaryAction,
                backgroundColor: tokens.surface,
                onRefresh: () async {
                  ref.invalidate(announcementsProvider);
                  await ref.read(announcementsProvider.future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: AppSpacing.screenEdge,
                  ),
                  itemBuilder: (context, i) {
                    final a = items[i];
                    return AnnouncementRow(
                      announcement: a,
                      isOm: isOm,
                      onTap: () => context.pushNamed(
                        'announcementDetail',
                        pathParameters: {'id': a.id},
                      ),
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

class _AnnouncementsSkeleton extends StatelessWidget {
  const _AnnouncementsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 80, height: 12),
          SizedBox(height: 8),
          Skeleton(height: 18),
          SizedBox(height: 6),
          Skeleton(width: 240, height: 14),
        ],
      ),
    );
  }
}