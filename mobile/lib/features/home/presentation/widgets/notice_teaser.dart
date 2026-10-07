import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/home/data/models/home_summary.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

/// An editorial notice, not a card. Left edge is a clay rule.
class NoticeTeaserCard extends StatelessWidget {
  const NoticeTeaserCard({
    required this.notice,
    required this.onTap,
    super.key,
  });

  final NoticeTeaser notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isOm = Localizations.localeOf(context).languageCode == 'om';
    final title = isOm ? notice.titleOm : notice.titleEn;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: AppRadii.md,
          border: Border(
            left: BorderSide(
              color: notice.isUrgent ? tokens.stateUnpaid : tokens.accent,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.homeLatestNotice.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: tokens.accent,
                    letterSpacing: 1.2,
                  ),
                ),
                if (notice.isUrgent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.stateUnpaidBg,
                      borderRadius: AppRadii.xs,
                    ),
                    child: Text(
                      'URGENT',
                      style: AppTypography.caption.copyWith(
                        color: tokens.stateUnpaid,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleM.copyWith(
                color: tokens.textPrimary,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.homeReadMore,
              style: AppTypography.label.copyWith(color: tokens.primary),
            ),
          ],
        ),
      ),
    );
  }
}