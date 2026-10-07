import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/history/data/models/payment_record.dart';
import 'package:odaa_mobile/features/history/domain/history_providers.dart';
import 'package:odaa_mobile/features/history/presentation/widgets/payment_row_tile.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/skeleton.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final async = ref.watch(historyProvider);

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
                l10n.historyTitle,
                style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const _HistorySkeleton(),
            error: (_, __) => ErrorView(
              message: l10n.errorGeneric,
              onRetry: () => ref.invalidate(historyProvider),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return EmptyView(
                  title: l10n.historyEmpty,
                  body: l10n.historyEmptyBody,
                  icon: Icons.receipt_long_outlined,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                itemCount: rows.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: AppSpacing.screenEdge),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  return PaymentRowTile(
                    record: r,
                    onTap: () {
                      if (r.status == PaymentStatus.success && r.receiptNo != null) {
                        context.pushNamed(
                          'receipt',
                          pathParameters: {'id': r.id},
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const Row(
        children: [
          Skeleton(
            width: 96,
            height: 24,
            radius: BorderRadius.all(Radius.circular(4)),
          ),
          SizedBox(width: 16),
          Expanded(child: Skeleton(height: 16)),
          SizedBox(width: 16),
          Skeleton(
            width: 56,
            height: 18,
            radius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}