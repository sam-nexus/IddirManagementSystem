import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_motion.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';

/// Outlined, quieter sibling of [PrimaryButton]. Used for Cancel, Back,
/// and any secondary action. Greys out the same way as PrimaryButton
/// when [onPressed] is null.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final disabled = onPressed == null || isLoading;

    // Foreground and border shift to muted tokens when disabled.
    final fg = disabled ? tokens.textMuted : tokens.primary;
    final borderColor = disabled ? tokens.divider : tokens.primary;

    final button = SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: AppRadii.md,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(fg),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ] else if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedOpacity(
      duration: AppMotion.scale(context, AppMotion.fast),
      opacity: disabled && !isLoading ? 0.6 : 1,
      child: button,
    );
  }
}