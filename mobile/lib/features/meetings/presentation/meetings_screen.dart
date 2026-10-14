import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/meetings/domain/meetings_providers.dart';
import 'package:odaa_mobile/features/meetings/presentation/widgets/meeting_row.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/refreshable_scroll.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';

class MeetingsScreen extends ConsumerWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isOm = Localizations.localeOf(context).languageCode == 'om';
    final async = ref.watch(meetingsProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.meetingsTitle),
      ),
      body: async.when(
        loading: () => const _MeetingsSkeleton(),
        error: (_, __) => ErrorView(
          message: l10n.errorGeneric,
          onRetry: () => ref.invalidate(meetingsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshableScroll(
              onRefresh: () async {
                ref.invalidate(meetingsProvider);
                await ref.read(meetingsProvider.future);
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: EmptyView(
                  title: l10n.meetingsEmpty,
                  body: l10n.meetingsEmptyBody,
                  icon: Icons.groups_outlined,
                ),
              ),
            );
          }

          final upcoming = items.where((m) => m.isUpcoming).toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
          final past = items.where((m) => m.isPast).toList()
            ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

          return RefreshIndicator(
            color: tokens.primaryAction,
            backgroundColor: tokens.surface,
            onRefresh: () async {
              ref.invalidate(meetingsProvider);
              await ref.read(meetingsProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _SectionLabel(label: l10n.meetingsUpcoming.toUpperCase()),
                  ...upcoming.map((m) => MeetingRow(
                        meeting: m,
                        isOm: isOm,
                        onTap: () => context.pushNamed(
                          'meetingDetail',
                          pathParameters: {'id': m.id},
                        ),
                      ),),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(label: l10n.meetingsPast.toUpperCase()),
                  ...past.map((m) => MeetingRow(
                        meeting: m,
                        isOm: isOm,
                        onTap: () => context.pushNamed(
                          'meetingDetail',
                          pathParameters: {'id': m.id},
                        ),
                      ),),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.lg,
        AppSpacing.screenEdge,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: tokens.accent,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MeetingsSkeleton extends StatelessWidget {
  const _MeetingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const Row(
        children: [
          Skeleton(
            width: 56,
            height: 56,
            radius: BorderRadius.all(Radius.circular(8)),
          ),
          SizedBox(width: 12),
          Expanded(child: Skeleton(height: 16)),
        ],
      ),
    );
  }
}