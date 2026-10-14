import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/features/reports/domain/reports_providers.dart';
import 'package:odaa_mobile/features/reports/presentation/widgets/report_row.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/refreshable_scroll.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isOm = Localizations.localeOf(context).languageCode == 'om';
    final async = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.reportsTitle),
      ),
      body: async.when(
        loading: () => const _ReportsSkeleton(),
        error: (_, __) => ErrorView(
          message: l10n.errorGeneric,
          onRetry: () => ref.invalidate(reportsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshableScroll(
              onRefresh: () async {
                ref.invalidate(reportsProvider);
                await ref.read(reportsProvider.future);
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: EmptyView(
                  title: l10n.reportsEmpty,
                  body: l10n.reportsEmptyBody,
                  icon: Icons.assessment_outlined,
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: tokens.primaryAction,
            backgroundColor: tokens.surface,
            onRefresh: () async {
              ref.invalidate(reportsProvider);
              await ref.read(reportsProvider.future);
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
                return ReportRow(
                  report: r,
                  isOm: isOm,
                  onTap: () => context.pushNamed(
                    'reportDetail',
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

class _ReportsSkeleton extends StatelessWidget {
  const _ReportsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(height: 16),
          SizedBox(height: 6),
          Skeleton(width: 160, height: 12),
        ],
      ),
    );
  }
}