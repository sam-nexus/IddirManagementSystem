import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/announcements/data/models/announcement.dart';

class AnnouncementRow extends StatelessWidget {
  const AnnouncementRow({
    required this.announcement,
    required this.isOm,
    required this.onTap,
    super.key,
  });

  final Announcement announcement;
  final bool isOm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = announcement.isUrgent ? tokens.stateUnpaid : tokens.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.screenEdge,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left rule — the editorial mark.
              Container(
                width: 4,
                height: 64,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: AppRadii.xs,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (announcement.isUrgent) ...[
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
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _formatDate(announcement.publishedAt),
                          style: AppTypography.caption.copyWith(
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      announcement.title(isOm),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleS.copyWith(
                        color: tokens.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.body(isOm),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyS.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: tokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const monthsOm = [
      'Ama', 'Gur', 'Bit', 'Elb', 'Cam', 'Wax',
      'Ado', 'Hag', 'Ful', 'Onk', 'Sad', 'Mud',
    ];
    final months = isOm ? monthsOm : monthsEn;
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}