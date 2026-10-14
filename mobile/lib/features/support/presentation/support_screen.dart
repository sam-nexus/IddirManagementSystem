import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/features/support/domain/support_providers.dart';
import 'package:odaa_mobile/features/support/presentation/widgets/support_row.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/primary_button.dart';
import 'package:odaa_mobile/shared/widgets/refreshable_scroll.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final async = ref.watch(supportRequestsProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.supportTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.supportNew,
            onPressed: () => context.pushNamed('supportSubmit'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const _SupportSkeleton(),
        error: (_, __) => ErrorView(
          message: l10n.errorGeneric,
          onRetry: () => ref.invalidate(supportRequestsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshableScroll(
              onRefresh: () async {
                ref.invalidate(supportRequestsProvider);
                await ref.read(supportRequestsProvider.future);
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: EmptyView(
                        title: l10n.supportEmpty,
                        body: l10n.supportEmptyBody,
                        icon: Icons.volunteer_activism_outlined,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxxl,
                      ),
                      child: PrimaryButton(
                        label: l10n.supportNew,
                        onPressed: () => context.pushNamed('supportSubmit'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: tokens.primaryAction,
            backgroundColor: tokens.surface,
            onRefresh: () async {
              ref.invalidate(supportRequestsProvider);
              await ref.read(supportRequestsProvider.future);
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
                final r = items[i];
                return SupportRow(
                  request: r,
                  onTap: () => context.pushNamed(
                    'supportDetail',
                    pathParameters: {'id': r.id},
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SupportSkeleton extends StatelessWidget {
  const _SupportSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 120, height: 16),
          SizedBox(height: 8),
          Skeleton(height: 14),
          SizedBox(height: 6),
          Skeleton(width: 100, height: 12),
        ],
      ),
    );
  }
}