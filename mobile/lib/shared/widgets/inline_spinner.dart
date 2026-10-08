import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';

/// A small spinner for use inside buttons and compact rows.
/// Inherits colour from the theme unless [color] is provided.
class InlineSpinner extends StatelessWidget {
  const InlineSpinner({
    this.size = 18,
    this.color,
    this.strokeWidth = 2,
    super.key,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? tokens.textOnPrimary,
        ),
      ),
    );
  }
}