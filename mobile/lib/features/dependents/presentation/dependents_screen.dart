import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/dependents/data/models/dependent.dart';
import 'package:odaa_mobile/features/dependents/domain/dependents_providers.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/refreshable_scroll.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';

class DependentsScreen extends ConsumerWidget {
  const DependentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final async = ref.watch(dependentsProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.dependentsTitle),
      ),
      body: async.when(
        loading: () => const _DependentsSkeleton(),
        error: (_, __) => ErrorView(
          message: l10n.errorGeneric,
          onRetry: () => ref.invalidate(dependentsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshableScroll(
              onRefresh: () async {
                ref.invalidate(dependentsProvider);
                await ref.read(dependentsProvider.future);
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: EmptyView(
                  title: l10n.dependentsEmpty,
                  body: l10n.dependentsEmptyBody,
                  icon: Icons.people_outline,
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: tokens.primaryAction,
            backgroundColor: tokens.surface,
            onRefresh: () async {
              ref.invalidate(dependentsProvider);
              await ref.read(dependentsProvider.future);
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
                return _DependentRow(dependent: items[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DependentRow extends StatelessWidget {
  const _DependentRow({required this.dependent});

  final Dependent dependent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    final relationshipLabel = switch (dependent.relationship) {
      'spouse' => l10n.relationshipSpouse,
      'child' => l10n.relationshipChild,
      'parent' => l10n.relationshipParent,
      'sibling' => l10n.relationshipSibling,
      _ => l10n.relationshipOther,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.screenEdge,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.surfaceAlt,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(dependent.fullName),
              style: AppTypography.titleS.copyWith(color: tokens.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dependent.fullName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  relationshipLabel,
                  style: AppTypography.caption.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (!dependent.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.dependentInactive,
                style: AppTypography.caption.copyWith(
                  color: tokens.textMuted,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _DependentsSkeleton extends StatelessWidget {
  const _DependentsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const Row(
        children: [
          Skeleton(
            width: 40,
            height: 40,
            radius: BorderRadius.all(Radius.circular(20)),
          ),
          SizedBox(width: 12),
          Expanded(child: Skeleton(height: 16)),
        ],
      ),
    );
  }
}