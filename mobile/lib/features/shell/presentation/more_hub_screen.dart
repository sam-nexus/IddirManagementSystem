import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/shell/presentation/widgets/more_hub_row.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

class MoreHubScreen extends ConsumerWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        // ---------- Title ----------
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.lg,
            AppSpacing.screenEdge,
            AppSpacing.lg,
          ),
          child: Text(
            l10n.moreTitle,
            style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
          ),
        ),

        // ---------- Section: The Afoosha ----------
        _SectionLabel(label: l10n.moreSectionAfoosha.toUpperCase()),
        MoreHubRow(
          icon: Icons.info_outline,
          label: l10n.aboutTitle,
          onTap: () => context.pushNamed('about'),
        ),
        MoreHubRow(
          icon: Icons.campaign_outlined,
          label: l10n.announcementsTitle,
          onTap: () => context.pushNamed('announcements'),
        ),
        MoreHubRow(
          icon: Icons.groups_outlined,
          label: l10n.meetingsTitle,
          onTap: () => context.pushNamed('meetings'),
        ),
        MoreHubRow(
          icon: Icons.assessment_outlined,
          label: l10n.reportsTitle,
          onTap: () => context.pushNamed('reports'),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ---------- Section: Your household ----------
        _SectionLabel(label: l10n.moreSectionHousehold.toUpperCase()),
        MoreHubRow(
          icon: Icons.volunteer_activism_outlined,
          label: l10n.supportTitle,
          onTap: () => context.pushNamed('support'),
        ),
        MoreHubRow(
          icon: Icons.people_outline,
          label: l10n.dependentsTitle,
          onTap: () => context.pushNamed('dependents'),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ---------- Section: Account ----------
        _SectionLabel(label: l10n.moreSectionAccount.toUpperCase()),
        MoreHubRow(
          icon: Icons.person_outline,
          label: l10n.profileTitle,
          onTap: () => context.pushNamed('profile'),
        ),
        MoreHubRow(
          icon: Icons.logout,
          label: l10n.profileLogout,
          isDestructive: true,
          onTap: () => _confirmSignOut(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileLogout),
        content: Text(l10n.profileLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.profileLogout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(sessionProvider.notifier).signOut();
      if (context.mounted) context.goNamed('login');
    }
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
        AppSpacing.md,
        AppSpacing.screenEdge,
        AppSpacing.xs,
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