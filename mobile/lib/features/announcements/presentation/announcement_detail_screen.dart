import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/announcements/domain/announcements_providers.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';

class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isOm = Localizations.localeOf(context).languageCode == 'om';
    final async = ref.watch(announcementProvider(id));

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.announcementsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorView(
          message: l10n.errorGeneric,
          onRetry: () => ref.invalidate(announcementProvider(id)),
        ),
        data: (a) {
          if (a == null) {
            return EmptyView(
              title: l10n.announcementsEmpty,
              icon: Icons.campaign_outlined,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenEdge,
              AppSpacing.xl,
              AppSpacing.screenEdge,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a.isUrgent) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.stateUnpaidBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'URGENT',
                      style: AppTypography.caption.copyWith(
                        color: tokens.stateUnpaid,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(
                  a.title(isOm),
                  style: AppTypography.titleL.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _formatDate(a.publishedAt, isOm),
                  style: AppTypography.caption.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  a.body(isOm),
                  style: AppTypography.body.copyWith(
                    color: tokens.textPrimary,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt, bool isOm) {
    const monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const monthsOm = [
      'Amajjii', 'Guraandhala', 'Bitooteessa', 'Elbaa', 'Caamsa', 'Waxabajjii',
      'Adooleessa', 'Hagayya', 'Fuulbana', 'Onkololeessa', 'Sadaasa', 'Muddee',
    ];
    final months = isOm ? monthsOm : monthsEn;
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}