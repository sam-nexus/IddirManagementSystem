import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/meetings/data/models/meeting.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

class MeetingRow extends StatelessWidget {
  const MeetingRow({
    required this.meeting,
    required this.isOm,
    required this.onTap,
    super.key,
  });

  final Meeting meeting;
  final bool isOm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isUpcoming = meeting.isUpcoming;

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
              // Date block on the left.
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isUpcoming ? tokens.statePaidBg : tokens.surfaceAlt,
                  borderRadius: AppRadii.sm,
                ),
                child: Column(
                  children: [
                    Text(
                      _monthShort(meeting.scheduledAt, isOm).toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: isUpcoming
                            ? tokens.statePaid
                            : tokens.textMuted,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${meeting.scheduledAt.day}',
                      style: AppTypography.titleM.copyWith(
                        color: isUpcoming
                            ? tokens.statePaid
                            : tokens.textMuted,
                        fontSize: 22,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.title(isOm),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleS.copyWith(
                        color: tokens.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (meeting.location != null && meeting.location!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: tokens.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              meeting.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyS.copyWith(
                                color: tokens.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (meeting.hasMinutes) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surfaceAlt,
                          borderRadius: AppRadii.xs,
                        ),
                        child: Text(
                          l10n.meetingsMinutesAvailable.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: tokens.textSecondary,
                            fontSize: 9,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
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

  String _monthShort(DateTime dt, bool isOm) {
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const monthsOm = [
      'Ama', 'Gur', 'Bit', 'Elb', 'Cam', 'Wax',
      'Ado', 'Hag', 'Ful', 'Onk', 'Sad', 'Mud',
    ];
    final months = isOm ? monthsOm : monthsEn;
    return months[dt.month - 1];
  }
}