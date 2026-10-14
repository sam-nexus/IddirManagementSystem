import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/date_display.dart';
import 'package:odaa_mobile/features/meetings/domain/meetings_providers.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';



class MeetingDetailScreen extends ConsumerWidget {
  const MeetingDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isOm = Localizations.localeOf(context).languageCode == 'om';
    final async = ref.watch(meetingProvider(id));

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.meetingsTitle),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorView(
          message: l10n.errorGeneric,
          onRetry: () => ref.invalidate(meetingProvider(id)),
        ),
        data: (m) {
          if (m == null) {
            return EmptyView(
              title: l10n.meetingsEmpty,
              icon: Icons.groups_outlined,
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
                Text(
                  m.title(isOm),
                  style: AppTypography.titleL.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateDisplay.primary(m.scheduledAt)} · ${_time(m.scheduledAt)}',
                      style: AppTypography.bodyS.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                    if (AppDate.calendar == CalendarSystem.ethiopian)
                      Text(
                        '${DateDisplay.gregorian(m.scheduledAt)} · ${_time(m.scheduledAt)}',
                        style: AppTypography.caption.copyWith(
                          color: tokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                if (m.location != null && m.location!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: tokens.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          m.location!,
                          style: AppTypography.bodyS
                              .copyWith(color: tokens.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
                if (m.agenda(isOm) != null && m.agenda(isOm)!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionHeading(label: l10n.meetingsAgenda.toUpperCase()),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    m.agenda(isOm)!,
                    style: AppTypography.body.copyWith(
                      color: tokens.textPrimary,
                      height: 1.65,
                    ),
                  ),
                ],
                if (m.hasMinutes && m.isPublished) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionHeading(label: l10n.meetingsMinutes.toUpperCase()),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    m.minutes(isOm) ?? '',
                    style: AppTypography.body.copyWith(
                      color: tokens.textPrimary,
                      height: 1.65,
                    ),
                  ),
                ] else if (m.isPast && !m.hasMinutes) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionHeading(label: l10n.meetingsMinutes.toUpperCase()),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.meetingsMinutesPending,
                    style: AppTypography.bodyS.copyWith(
                      color: tokens.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }


}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: tokens.accent,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$h:$mi';
  }
