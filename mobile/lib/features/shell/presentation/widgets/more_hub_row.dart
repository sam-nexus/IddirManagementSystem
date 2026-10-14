import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';

/// A single entry in the More hub: icon, label, chevron.
/// Optionally destructive (used for Sign out).
class MoreHubRow extends StatelessWidget {
  const MoreHubRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = isDestructive ? tokens.stateUnpaid : tokens.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.screenEdge,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(color: color),
                ),
              ),
              if (trailing != null) ...[
                Text(
                  trailing!,
                  style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Icon(
                Icons.chevron_right,
                size: 18,
                color: tokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}