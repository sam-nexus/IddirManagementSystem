import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/home/data/models/home_summary.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

/// A quiet one-liner: calendar glyph + "Next meeting · 15 Dec · Hall".
class NextMeetingLine extends StatelessWidget {
  const NextMeetingLine({
    required this.meeting,
    required this.onTap,
    super.key,
  });

  final MeetingTeaser meeting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isOm = Localizations.localeOf(context).languageCode == 'om';

    final dateLabel = _formatDate(meeting.scheduledAt, isOm);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: tokens.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.homeNextMeeting,
              style: AppTypography.label.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(width: 6),
            Text('·', style: AppTypography.bodyS.copyWith(color: tokens.textMuted)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$dateLabel · ${meeting.location}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyS.copyWith(color: tokens.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt, bool isOm) {
    const monthsEn = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    const monthsOm = [
      'Ama','Gur','Bit','Elb','Cam','Wax',
      'Ado','Hag','Ful','Onk','Sad','Mud',
    ];
    final m = (isOm ? monthsOm : monthsEn)[dt.month - 1];
    return '${dt.day} $m';
  }
}