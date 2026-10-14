import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/money.dart';
import 'package:odaa_mobile/features/support/data/models/support_request.dart';
import 'package:odaa_mobile/features/support/domain/support_providers.dart';
import 'package:odaa_mobile/features/support/presentation/widgets/support_status_chip.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';

class SupportRequestDetailScreen extends ConsumerWidget {
  const SupportRequestDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final async = ref.watch(supportRequestProvider(id));

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.supportTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorView(
          message: l10n.errorGeneric,
          onRetry: () => ref.invalidate(supportRequestProvider(id)),
        ),
        data: (r) {
          if (r == null) {
            return EmptyView(
              title: l10n.supportEmpty,
              icon: Icons.volunteer_activism_outlined,
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
                Row(
                  children: [
                    Text(
                      _typeLabel(r.type, l10n),
                      style: AppTypography.titleL.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SupportStatusChip(status: r.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                _Field(label: l10n.supportSubmitted, value: _date(r.createdAt)),
                if (r.dependentName != null)
                  _Field(label: l10n.supportFor, value: r.dependentName!),
                if (r.amountRequested != null)
                  _Field(
                    label: l10n.supportAmountRequested,
                    value: Money.etb(r.amountRequested!),
                  ),
                if (r.amountApproved != null && r.amountApproved! > 0)
                  _Field(
                    label: l10n.supportAmountApproved,
                    value: Money.etb(r.amountApproved!),
                  ),

                const SizedBox(height: AppSpacing.lg),
                Divider(height: 1, color: tokens.divider),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  l10n.supportDescription,
                  style: AppTypography.caption.copyWith(
                    color: tokens.accent,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  r.description,
                  style: AppTypography.body.copyWith(
                    color: tokens.textPrimary,
                    height: 1.65,
                  ),
                ),

                if (r.payoutAmount != null) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: tokens.statePaidBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.supportPayoutRecorded,
                          style: AppTypography.titleS.copyWith(
                            color: tokens.statePaid,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          Money.etb(r.payoutAmount!),
                          style: AppTypography.moneyMedium.copyWith(
                            color: tokens.statePaid,
                          ),
                        ),
                        if (r.payoutMethod != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            r.payoutMethod!,
                            style: AppTypography.bodyS.copyWith(
                              color: tokens.statePaid,
                            ),
                          ),
                        ],
                      ],
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

  String _typeLabel(SupportType t, dynamic l10n) {
    switch (t) {
      case SupportType.death:
        return l10n.supportTypeDeath;
      case SupportType.illness:
        return l10n.supportTypeIllness;
      case SupportType.emergency:
        return l10n.supportTypeEmergency;
      case SupportType.other:
        return l10n.supportTypeOther;
    }
  }

  String _date(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(color: tokens.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium
                  .copyWith(color: tokens.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}