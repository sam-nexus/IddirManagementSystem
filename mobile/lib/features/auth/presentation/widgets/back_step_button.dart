import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';

/// A small back arrow for step transitions within a single screen
/// (e.g. Phone → PIN). Does NOT use Navigator.pop — the caller decides.
class BackStepButton extends StatelessWidget {
  const BackStepButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.sm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Icon(Icons.arrow_back, size: 20, color: tokens.textPrimary),
          ),
        ),
      ),
    );
  }
}