import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/about/data/models/organization_info.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

class CommitteeMemberCard extends StatelessWidget {
  const CommitteeMemberCard({required this.member, super.key});

  final CommitteeMember member;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    final roleLabel = switch (member.role) {
      'chairperson' => l10n.roleChairperson,
      'secretary' => l10n.roleSecretary,
      'treasurer' => l10n.roleTreasurer,
      'auditor' => l10n.roleAuditor,
      _ => member.role,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: AppRadii.md,
      ),
      child: Row(
        children: [
          // A simple monogram — no photo needed.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tokens.surfaceAlt,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(member.name),
              style: AppTypography.titleS.copyWith(
                color: tokens.primaryAction,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel,
                  style: AppTypography.caption.copyWith(
                    color: tokens.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.phone,
                  style: AppTypography.mono.copyWith(
                    color: tokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
