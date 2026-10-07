import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';

class ProfileRow extends StatelessWidget {
  const ProfileRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

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
              if (trailing != null)
                Text(
                  trailing!,
                  style: AppTypography.bodyS.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: tokens.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}