import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/about/domain/about_providers.dart';
import 'package:odaa_mobile/features/about/presentation/widgets/committee_member_card.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/section_header.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isOm = Localizations.localeOf(context).languageCode == 'om';
    final async = ref.watch(organizationInfoProvider);

    return async.when(
      loading: () => const _AboutSkeleton(),
      error: (_, __) => ErrorView(
        message: l10n.errorGeneric,
        onRetry: () => ref.invalidate(organizationInfoProvider),
      ),
      data: (info) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.lg,
          AppSpacing.screenEdge,
          AppSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.aboutTitle,
              style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xxl),

            _Section(
              title: l10n.aboutMission,
              body: isOm ? info.missionOm : info.missionEn,
            ),
            const SizedBox(height: AppSpacing.xl),

            _Section(
              title: l10n.aboutVision,
              body: isOm ? info.visionOm : info.visionEn,
            ),
            const SizedBox(height: AppSpacing.xl),

            _Section(
              title: l10n.aboutBylaws,
              body: isOm ? info.bylawsOm : info.bylawsEn,
            ),
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(title: l10n.aboutCommittee),
            const SizedBox(height: AppSpacing.sm),
            ...info.committee.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: CommitteeMemberCard(member: m),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: tokens.accent,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          body,
          style: AppTypography.body.copyWith(
            color: tokens.textPrimary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _AboutSkeleton extends StatelessWidget {
  const _AboutSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 140, height: 20),
          SizedBox(height: 24),
          Skeleton(height: 14),
          SizedBox(height: 8),
          Skeleton(width: 220, height: 14),
          SizedBox(height: 32),
          Skeleton(height: 14),
          SizedBox(height: 8),
          Skeleton(width: 260, height: 14),
        ],
      ),
    );
  }
}